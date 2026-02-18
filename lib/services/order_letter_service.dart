import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../config/dependency_injection.dart';
import '../core/error/exceptions.dart';
import '../core/utils/error_logger.dart';
import '../core/utils/exception_helper.dart';
import '../core/utils/api_response_parser.dart';
import '../features/order_letter/domain/usecases/extract_order_letter_id_usecase.dart';
import '../features/order_letter/domain/usecases/create_order_letter_details_usecase.dart';
import '../features/approval/data/models/approval_model.dart';
import 'auth_service.dart';
import 'leader_service.dart';
import 'notification_service.dart';
import 'location_service.dart';
import 'contact_work_experience_service.dart';

class OrderLetterService {
  final Dio dio;

  OrderLetterService(this.dio);

  /// Create Order Letter with Details and Discounts
  Future<Map<String, dynamic>> createOrderLetterWithDetails({
    required Map<String, dynamic> orderLetterData,
    required List<Map<String, dynamic>> detailsData,
    required dynamic
        discountsData, // Can be List<double> or List<Map<String, dynamic>>
    List<int?>? leaderIds, // Add leader IDs parameter
    int? selectedSpvId,
    String? selectedSpvName,
    int? selectedRsmId,
    String? selectedRsmName,
  }) async {
    try {
      // Step 1: POST Order Letter
      final orderLetterResult = await createOrderLetter(orderLetterData);
      if (orderLetterResult['success'] != true) {
        return orderLetterResult;
      }

      // Extract order letter ID and no_sp from response using use case
      final responseData = orderLetterResult['data'];
      final extractIdUseCase = ExtractOrderLetterIdUseCase(this);
      final idResult = await extractIdUseCase(
        responseData: responseData,
        creator: orderLetterData['creator'],
      );
      final orderLetterId = idResult['orderLetterId'] as int?;
      final noSp = idResult['noSp'] as String?;

      if (orderLetterId == null) {
        return {
          'success': false,
          'message': 'Failed to get order letter ID from response',
          'responseData': responseData,
        };
      }

      // Step 2: POST Order Letter Details using use case
      final createDetailsUseCase = CreateOrderLetterDetailsUseCase(this);
      final detailResults = await createDetailsUseCase(
        orderLetterId: orderLetterId,
        noSp: noSp,
        detailsData: detailsData,
      );

      // Step 3: POST Order Letter Discounts with Leader Data
      final List<Map<String, dynamic>> discountResults = [];

      // Handle different discount data formats
      if (discountsData is List<Map<String, dynamic>>) {
        // New structured format with per-item discount information
        if (discountsData.isEmpty) {
          // If no discounts, create default entries for all items up to Supervisor
          await _createDefaultDiscountEntries(
            detailResults,
            discountResults,
            leaderIds,
            orderLetterId,
            selectedSpvId: selectedSpvId,
            selectedSpvName: selectedSpvName,
            selectedRsmId: selectedRsmId,
            selectedRsmName: selectedRsmName,
          );
        } else {
          // Process items with discounts
          try {
            await _processStructuredDiscounts(
              discountsData,
              detailResults,
              discountResults,
              leaderIds,
              orderLetterId,
              selectedSpvId: selectedSpvId,
              selectedSpvName: selectedSpvName,
              selectedRsmId: selectedRsmId,
              selectedRsmName: selectedRsmName,
            );

            await _createDefaultEntriesForMissingItems(
              discountsData,
              detailResults,
              discountResults,
              leaderIds,
              orderLetterId,
              selectedSpvId: selectedSpvId,
              selectedSpvName: selectedSpvName,
              selectedRsmId: selectedRsmId,
              selectedRsmName: selectedRsmName,
            );
          } catch (e, stackTrace) {
            // If structured processing fails, create default entries as fallback
            await ErrorLogger.logError(
              e,
              stackTrace: stackTrace,
              context:
                  'Structured discount processing failed, creating default entries',
              extra: {'orderLetterId': orderLetterId},
              fatal: false,
            );
            await _createDefaultDiscountEntries(
              detailResults,
              discountResults,
              leaderIds,
              orderLetterId,
              selectedSpvId: selectedSpvId,
              selectedSpvName: selectedSpvName,
              selectedRsmId: selectedRsmId,
              selectedRsmName: selectedRsmName,
            );
          }
        }
      } else if (discountsData is List<double>) {
        // Legacy format - process all discounts for first kasur
        await _processLegacyDiscounts(
          discountsData,
          detailResults,
          discountResults,
          leaderIds,
          orderLetterId,
          selectedSpvId: selectedSpvId,
          selectedSpvName: selectedSpvName,
          selectedRsmId: selectedRsmId,
          selectedRsmName: selectedRsmName,
        );
      } else {
        // No discounts data provided, create default entries
        await _createDefaultDiscountEntries(
          detailResults,
          discountResults,
          leaderIds,
          orderLetterId,
          selectedSpvId: selectedSpvId,
          selectedSpvName: selectedSpvName,
          selectedRsmId: selectedRsmId,
          selectedRsmName: selectedRsmName,
        );
      }

      // Skip original loop completely - it's been replaced by structured/legacy processing above
      for (int i = 0; i < 0; i++) {
        final discount = discountsData[i];
        if (discount <= 0) continue; // Skip zero discounts

        // Find the kasur detail ID (first detail with mattress type)
        int? kasurOrderLetterDetailId;
        for (final detailResult in detailResults) {
          if (detailResult['success'] && detailResult['data'] != null) {
            final rawData = detailResult['data'];
            final detailData = rawData['location'] ?? rawData;
            // Check for both 'Mattress' and 'kasur' item types
            if (detailData['item_type'] == 'Mattress' ||
                detailData['item_type'] == 'kasur') {
              // detailData sudah berisi location data, langsung akses ID
              kasurOrderLetterDetailId = detailData['id'] ??
                  detailData['order_letter_detail_id'] ??
                  detailData['detail_id'];
              break; // Found the first kasur detail, no need to continue
            }
          }
        }

        // If no kasur detail found, use the first available detail
        if (kasurOrderLetterDetailId == null) {
          for (final detailResult in detailResults) {
            if (detailResult['success'] && detailResult['data'] != null) {
              final rawData = detailResult['data'];
              final detailData = rawData['location'] ?? rawData;
              // detailData sudah berisi location data, langsung akses ID
              kasurOrderLetterDetailId = detailData['id'] ??
                  detailData['order_letter_detail_id'] ??
                  detailData['detail_id'];
              break;
            }
          }
        }

        // Get current user info for approver data
        final currentUserId = await AuthService.getCurrentUserId();
        final currentUserName = orderLetterData['creator'] ?? 'Unknown';

        // Get leader data for this discount level
        int? approverId = leaderIds != null && i < leaderIds.length
            ? leaderIds[i]
            : currentUserId;
        String approverName = currentUserName;
        String approverLevel = 'User';
        String approverWorkTitle = 'Staff';

        // Get actual leader data from LeaderService
        try {
          final leaderService = locator<LeaderService>();
          final leaderData = await leaderService.getLeaderByUser();

          if (leaderData != null) {
            // Get leader info based on discount level
            switch (i) {
              case 0: // User level
                approverId = leaderData.user.id;
                approverName = leaderData.user.fullName;
                approverLevel = 'User';
                approverWorkTitle = leaderData.user.workTitle;
                break;
              case 1: // Supervisor (SPV)
                if (leaderData.directLeader != null) {
                  approverId = leaderData.directLeader!.id;
                  approverName = leaderData.directLeader!.fullName;
                  approverLevel = 'Supervisor';
                  approverWorkTitle = leaderData.directLeader!.workTitle;
                }
                break;
              case 2: // RSM
                if (leaderData.indirectLeader != null) {
                  approverId = leaderData.indirectLeader!.id;
                  approverName = leaderData.indirectLeader!.fullName;
                  approverLevel = 'RSM';
                  approverWorkTitle = leaderData.indirectLeader!.workTitle;
                }
                break;
              case 3: // Analyst (Diskon 4)
                if (leaderData.analyst != null) {
                  approverId = leaderData.analyst!.id;
                  approverName = leaderData.analyst!.fullName;
                  approverLevel = 'Analyst';
                  approverWorkTitle = leaderData.analyst!.workTitle;
                }
                break;
              case 4: // Controller (Diskon 5)
                if (leaderData.controller != null) {
                  approverId = leaderData.controller!.id;
                  approverName = leaderData.controller!.fullName;
                  approverLevel = 'Controller';
                  approverWorkTitle = leaderData.controller!.workTitle;
                }
                break;
            }
          }
        } catch (e, stackTrace) {
          // Fallback to current user data
          await ErrorLogger.logError(
            e,
            stackTrace: stackTrace,
            context: 'Failed to get leader data for approval',
            extra: {'discountIndex': i},
            fatal: false,
          );
        }

        // Smart approval logic - Modified to ensure all orders require Supervisor approval
        String? approvedAt;
        String? approvedValue;

        if (i == 0) {
          // User level - always auto-approved (user created the order)
          approvedAt = DateTime.now().toIso8601String();
          approvedValue = 'true';
        } else {
          // For all other levels (Supervisor, RSM, Controller, Analyst)
          // Set approved and approved_at to null - they need manual approval
          approvedValue = null;
          approvedAt = null;
        }

        final discountData = {
          'order_letter_id': orderLetterId,
          'order_letter_detail_id': kasurOrderLetterDetailId,
          'discount': discount.toString(),
          'approver': approverId,
          'approver_name': approverName,
          'approver_level_id': i + 1,
          'approver_level': approverLevel,
          'approver_work_title': approverWorkTitle,
          'approved': approvedValue,
          'approved_at': approvedAt,
        };

        final discountResult = await createOrderLetterDiscount(discountData);
        discountResults.add(discountResult);

        if (discountResult['success']) {
        } else {}
      }

      // Check if all operations were successful
      final allDetailsSuccess =
          detailResults.every((result) => result['success']);
      final allDiscountsSuccess =
          discountResults.every((result) => result['success']);

      // Determine final status after discount creation
      String finalStatus = orderLetterData['status'] ?? 'Pending';

      if (allDetailsSuccess && allDiscountsSuccess) {
        finalStatus =
            await _determineFinalOrderStatus(orderLetterId, discountsData);
      }

      // Update order letter status if it should be auto-approved
      if (finalStatus == 'Approved') {
        await _updateOrderLetterStatus(orderLetterId, 'Approved');
      }

      return {
        'success': allDetailsSuccess && allDiscountsSuccess,
        'message': allDetailsSuccess && allDiscountsSuccess
            ? 'Order letter created successfully with all details and discounts'
            : 'Order letter created but some details or discounts failed',
        'orderLetterId': orderLetterId,
        'noSp': noSp,
        'finalStatus': finalStatus,
        'detailResults': detailResults,
        'discountResults': discountResults,
      };
    } catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to create order letter with details',
        extra: {
          'orderLetterData': orderLetterData,
          'detailsCount': detailsData.length,
          'discountsCount': discountsData is List ? discountsData.length : 1,
        },
        fatal: true,
      );
      return {
        'success': false,
        'message': 'Error creating order letter: $e',
      };
    }
  }

  /// Create Order Letter
  Future<Map<String, dynamic>> createOrderLetter(
      Map<String, dynamic> orderLetterData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw CacheException('Token not found. Silakan login kembali.');
      }

      final url = ApiConfig.getCreateOrderLetterUrl(token: token);

      // Ensure postage is always included in the data
      // Create a new map to ensure postage is not removed by Dio
      final Map<String, dynamic> dataToSend =
          Map<String, dynamic>.from(orderLetterData);

      // Explicitly ensure postage is in the map with proper value
      final postageValue = orderLetterData['postage'];
      if (postageValue == null) {
        dataToSend['postage'] = 0.0;
      } else {
        // Ensure it's a number, not null
        dataToSend['postage'] = postageValue is double
            ? postageValue
            : (postageValue as num).toDouble();
      }

      final response = await dio.post(
        url,
        data: dataToSend,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Order letter created successfully',
        };
      } else {
        throw ExceptionHelper.convertDioException(
          DioException(
            requestOptions: RequestOptions(path: url),
            response: response,
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on ServerException catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to create order letter',
        fatal: false,
      );
      return {
        'success': false,
        'message': e.message,
      };
    } on NetworkException catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Network error creating order letter',
        fatal: false,
      );
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e, stackTrace) {
      final exception = ExceptionHelper.convertGenericException(e);
      await ErrorLogger.logError(
        exception,
        stackTrace: stackTrace,
        context: 'Unexpected error creating order letter',
        fatal: true,
      );
      return {
        'success': false,
        'message': exception is ServerException
            ? exception.message
            : 'Error creating order letter: $e',
      };
    }
  }

  /// Create Order Letter Detail
  Future<Map<String, dynamic>> createOrderLetterDetail(
      Map<String, dynamic> detailData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw CacheException('Token not found. Silakan login kembali.');
      }

      final url = ApiConfig.getCreateOrderLetterDetailUrl(token: token);

      final response = await dio.post(url, data: detailData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Order letter detail created successfully',
        };
      } else {
        throw ExceptionHelper.convertDioException(
          DioException(
            requestOptions: RequestOptions(path: url),
            response: response,
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on ServerException catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to create order letter detail',
        fatal: false,
      );
      return {
        'success': false,
        'message': e.message,
      };
    } on NetworkException catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Network error creating order letter detail',
        fatal: false,
      );
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e, stackTrace) {
      final exception = ExceptionHelper.convertGenericException(e);
      await ErrorLogger.logError(
        exception,
        stackTrace: stackTrace,
        context: 'Unexpected error creating order letter detail',
        fatal: true,
      );
      return {
        'success': false,
        'message': exception is ServerException
            ? exception.message
            : 'Error creating order letter detail: $e',
      };
    }
  }

  /// Create Order Letter Discount
  Future<Map<String, dynamic>> createOrderLetterDiscount(
      Map<String, dynamic> discountData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw CacheException('Token not found. Silakan login kembali.');
      }

      final url = ApiConfig.getCreateOrderLetterDiscountUrl(token: token);

      final response = await dio.post(url, data: discountData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Order letter discount created successfully',
        };
      } else {
        throw ExceptionHelper.convertDioException(
          DioException(
            requestOptions: RequestOptions(path: url),
            response: response,
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on ServerException catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to create order letter discount',
        fatal: false,
      );
      return {
        'success': false,
        'message': e.message,
      };
    } on NetworkException catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Network error creating order letter discount',
        fatal: false,
      );
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e, stackTrace) {
      final exception = ExceptionHelper.convertGenericException(e);
      await ErrorLogger.logError(
        exception,
        stackTrace: stackTrace,
        context: 'Unexpected error creating order letter discount',
        fatal: true,
      );
      return {
        'success': false,
        'message': exception is ServerException
            ? exception.message
            : 'Error creating order letter discount: $e',
      };
    }
  }

  /// Batch approve/reject all discounts for a specific user level in an order letter
  Future<Map<String, dynamic>> batchApproveOrderLetterDiscounts({
    required int orderLetterId,
    required int leaderId,
    required int jobLevelId,
    String action = 'approve', // 'approve' or 'reject'
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not available');
      }

      // Get all discounts for this order letter
      final allDiscounts =
          await getOrderLetterDiscounts(orderLetterId: orderLetterId);

      // Find all pending discounts for the current user level
      final List<int> discountIdsToApprove = [];
      for (final discount in allDiscounts) {
        final approverId = discount['approver'];
        final approverLevelId = discount['approver_level_id'];
        final approved = discount['approved'];

        // Check if this discount is for the current user and level, and is pending
        if (approverId == leaderId &&
            approverLevelId == jobLevelId &&
            (approved == null || approved == false)) {
          discountIdsToApprove.add(discount['id']);
        }
      }

      if (discountIdsToApprove.isEmpty) {
        return {
          'success': false,
          'message': 'No pending discounts found for approval',
          'approved_count': 0,
        };
      }

      final currentTime = DateTime.now().toIso8601String();
      final List<Map<String, dynamic>> approveResults = [];
      final List<Map<String, dynamic>> updateResults = [];

      // Get approver name for this level
      String approverName = await AuthService.getCurrentUserName() ?? 'Unknown';
      try {
        final leaderService = locator<LeaderService>();
        final leaderData = await leaderService.getLeaderByUser();
        if (leaderData != null) {
          final nameFromLeader = leaderService.getLeaderNameByDiscountLevel(
              leaderData, jobLevelId);
          if (nameFromLeader != null && nameFromLeader.isNotEmpty) {
            approverName = nameFromLeader;
          }
        }
      } catch (e, stackTrace) {
        // Fallback to current user name
        await ErrorLogger.logError(
          e,
          stackTrace: stackTrace,
          context: 'Failed to get approver name, using current user',
          fatal: false,
        );
      }

      // Get current location for approval
      String? approvalLocation;
      try {
        final locationInfo = await LocationService.getLocationInfo();
        if (locationInfo != null) {
          // Format location as address string, or include coordinates if needed
          final address = locationInfo['address'] as String?;
          if (address != null && address.isNotEmpty) {
            approvalLocation = address;
          } else {
            // Fallback to coordinates if address is not available
            final lat = locationInfo['latitude'] as double?;
            final lon = locationInfo['longitude'] as double?;
            if (lat != null && lon != null) {
              approvalLocation = '$lat,$lon';
            }
          }
        }
      } catch (e, stackTrace) {
        // If location cannot be obtained, continue without it
        // Location will be null
        await ErrorLogger.logError(
          e,
          stackTrace: stackTrace,
          context: 'Failed to get location for approval',
          fatal: false,
        );
      }

      // Approve all discounts in batch
      for (final discountId in discountIdsToApprove) {
        try {
          // Find the discount to get its approver_level_id
          final discountToApprove = allDiscounts.firstWhere(
            (d) => (d['id'] ?? d['order_letter_discount_id']) == discountId,
            orElse: () => {},
          );

          // Get the actual approver_level_id from the discount being approved
          final actualApproverLevelId =
              discountToApprove['approver_level_id'] ?? jobLevelId;

          // Get approver name based on the actual discount level, not the jobLevelId parameter
          String actualApproverName = approverName;
          try {
            final leaderService = locator<LeaderService>();
            final leaderData = await leaderService.getLeaderByUser();
            if (leaderData != null) {
              final nameFromLeader = leaderService.getLeaderNameByDiscountLevel(
                  leaderData, actualApproverLevelId);
              if (nameFromLeader != null && nameFromLeader.isNotEmpty) {
                actualApproverName = nameFromLeader;
              }
            }
          } catch (e) {
            // Fallback to default approverName
          }

          // POST to order_letter_approves endpoint
          final approveUrl =
              ApiConfig.getCreateOrderLetterApproveUrl(token: token);
          final approveData = {
            'order_letter_discount_id': discountId,
            'leader': leaderId,
            'job_level_id':
                actualApproverLevelId, // Use actual level from discount
            if (approvalLocation != null) 'location': approvalLocation,
          };

          final approveResponse = await dio.post(
            approveUrl,
            data: approveData,
            options: Options(
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            ),
          );
          approveResults.add(approveResponse.data);

          // PUT to order_letter_discounts endpoint
          final updateUrl = ApiConfig.getUpdateOrderLetterDiscountUrl(
            token: token,
            discountId: discountId,
          );

          // Determine approved value based on action
          final bool isApproved = action.toLowerCase() == 'approve';

          final updateData = {
            'approved': isApproved, // true for approve, false for reject
            'approved_at': currentTime,
            'approver_level': _getApproverLevelName(actualApproverLevelId),
            'approver_name':
                actualApproverName, // Use name based on actual discount level
          };

          final updateResponse = await dio.put(
            updateUrl,
            data: updateData,
            options: Options(
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            ),
          );
          updateResults.add(updateResponse.data);

          // Auto-approve disc5 (level 5) if disc4 (level 4) is being APPROVED (not rejected)
          if (actualApproverLevelId == 4 && isApproved) {
            await _autoApproveDisc5FromDisc4(
              orderLetterId: orderLetterId,
              disc4DiscountId: discountId,
              disc4Data: updateData,
              currentTime: currentTime,
              token: token,
              approvalLocation: approvalLocation,
            );
          }
        } catch (e, stackTrace) {
          // Continue with other discounts even if one fails
          await ErrorLogger.logError(
            e,
            stackTrace: stackTrace,
            context: 'Failed to update single discount in batch',
            extra: {'orderLetterId': orderLetterId},
            fatal: false,
          );
        }
      }

      // Check if this is the final approval (highest level)
      // Use the highest level from approved discounts
      int highestApprovedLevel = jobLevelId;
      for (final discountId in discountIdsToApprove) {
        final discount = allDiscounts.firstWhere(
          (d) => (d['id'] ?? d['order_letter_discount_id']) == discountId,
          orElse: () => {},
        );
        final level = discount['approver_level_id'] ?? 0;
        if (level > highestApprovedLevel) {
          highestApprovedLevel = level;
        }
      }
      // Determine if action is approve or reject
      final bool isApproveAction = action.toLowerCase() == 'approve';
      bool isFinalApproval = false;

      Map<String, dynamic>? orderLetterUpdateResult;

      if (isApproveAction) {
        // Only check for final approval if approving
        isFinalApproval =
            await _isFinalApproval(orderLetterId, highestApprovedLevel);

        if (isFinalApproval) {
          orderLetterUpdateResult =
              await _updateOrderLetterStatus(orderLetterId, 'Approved');
        }
      } else {
        // If rejecting, update order letter status to Rejected immediately
        orderLetterUpdateResult =
            await _updateOrderLetterStatus(orderLetterId, 'Rejected');
      }

      // Send notification after approval/rejection
      try {
        // Get approver name and level
        String approverName = 'Unknown';
        String approvalLevel = 'Level $jobLevelId';

        // Try to get from discount data or current user
        if (discountIdsToApprove.isNotEmpty) {
          final discounts = await getOrderLetterDiscounts(
            orderLetterId: orderLetterId,
          );
          final firstDiscount = discounts.firstWhere(
            (d) => discountIdsToApprove
                .contains(d['id'] ?? d['order_letter_discount_id']),
            orElse: () => {},
          );

          if (firstDiscount.isNotEmpty) {
            approverName = firstDiscount['approver_name'] as String? ??
                await AuthService.getCurrentUserName() ??
                'Unknown';
            approvalLevel = firstDiscount['approver_level'] as String? ??
                'Level $jobLevelId';
          }
        }

        // Get order letter info for notification
        final orderLetters = await getOrderLetters();
        final orderLetter = orderLetters.firstWhere(
          (ol) => (ol['id'] ?? ol['order_letter_id']) == orderLetterId,
          orElse: () => {},
        );

        final notificationService = NotificationService();

        // Parse creator user ID - handle both String and int
        int? creatorUserId;
        final creatorValue =
            orderLetter['creator'] ?? orderLetter['creator_id'];
        if (creatorValue != null) {
          if (creatorValue is int) {
            creatorUserId = creatorValue;
          } else if (creatorValue is String) {
            creatorUserId = int.tryParse(creatorValue);
          } else {
            creatorUserId = int.tryParse(creatorValue.toString());
          }
        }

        if (isApproveAction) {
          // Send approval notification
          await notificationService.notifyOnApproval(
            orderLetterId: orderLetterId,
            approvedLevelId: jobLevelId,
            approverName: approverName,
            approvalLevel: approvalLevel,
            isFinalApproval: isFinalApproval,
            orderId: orderLetter['id']?.toString() ??
                orderLetter['order_letter_id']?.toString(),
            noSp: orderLetter['no_sp'] ?? orderLetter['no_sp_number'],
            customerName: orderLetter['customer_name'],
            totalAmount: orderLetter['total'] != null
                ? double.tryParse(orderLetter['total'].toString())
                : null,
            creatorUserId: creatorUserId,
          );
        } else {
          // Send rejection notification
          await notificationService.notifyOnRejection(
            orderLetterId: orderLetterId,
            rejectedLevelId: jobLevelId,
            rejectorName: approverName,
            rejectionLevel: approvalLevel,
            orderId: orderLetter['id']?.toString() ??
                orderLetter['order_letter_id']?.toString(),
            noSp: orderLetter['no_sp'] ?? orderLetter['no_sp_number'],
            customerName: orderLetter['customer_name'],
            totalAmount: orderLetter['total'] != null
                ? double.tryParse(orderLetter['total'].toString())
                : null,
            creatorUserId: creatorUserId,
          );
        }
      } catch (e, stackTrace) {
        // Don't fail approval/rejection if notification fails
        await ErrorLogger.logError(
          e,
          stackTrace: stackTrace,
          context:
              'Failed to send ${isApproveAction ? "approval" : "rejection"} notification',
          extra: {'orderLetterId': orderLetterId, 'jobLevelId': jobLevelId},
          fatal: false,
        );
      }

      final actionMessage = isApproveAction ? 'approval' : 'rejection';
      return {
        'success': true,
        'message': 'Batch $actionMessage completed successfully',
        'approved_count': discountIdsToApprove.length,
        'discount_ids': discountIdsToApprove,
        'approve_results': approveResults,
        'update_results': updateResults,
        'order_letter_update_result': orderLetterUpdateResult,
        'is_final_approval': isFinalApproval,
        'action': action,
      };
    } catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Error in batch approval',
        extra: {'orderLetterId': orderLetterId, 'leaderId': leaderId},
        fatal: true,
      );
      return {
        'success': false,
        'message': 'Error in batch approval: $e',
        'approved_count': 0,
      };
    }
  }

  Future<Map<String, dynamic>> approveOrderLetterDiscount({
    required int discountId,
    required int leaderId,
    required int jobLevelId,
    required int orderLetterId,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not available');
      }

      final currentTime = DateTime.now().toIso8601String();

      // Get approver name for this level
      String approverName = await AuthService.getCurrentUserName() ?? 'Unknown';
      try {
        final leaderService = locator<LeaderService>();
        final leaderData = await leaderService.getLeaderByUser();
        if (leaderData != null) {
          final nameFromLeader = leaderService.getLeaderNameByDiscountLevel(
              leaderData, jobLevelId);
          if (nameFromLeader != null && nameFromLeader.isNotEmpty) {
            approverName = nameFromLeader;
          }
        }
      } catch (e, stackTrace) {
        // Fallback to current user name
        await ErrorLogger.logError(
          e,
          stackTrace: stackTrace,
          context: 'Failed to get approver name, using current user',
          fatal: false,
        );
      }

      // Get current location for approval
      String? approvalLocation;
      try {
        final locationInfo = await LocationService.getLocationInfo();
        if (locationInfo != null) {
          final address = locationInfo['address'] as String?;
          if (address != null && address.isNotEmpty) {
            approvalLocation = address;
          } else {
            final lat = locationInfo['latitude'] as double?;
            final lon = locationInfo['longitude'] as double?;
            if (lat != null && lon != null) {
              approvalLocation = '$lat,$lon';
            }
          }
        }
      } catch (e, stackTrace) {
        await ErrorLogger.logError(
          e,
          stackTrace: stackTrace,
          context: 'Failed to get location for approval',
          fatal: false,
        );
      }

      // Get the actual discount to determine its approver_level_id
      final allDiscounts =
          await getOrderLetterDiscounts(orderLetterId: orderLetterId);
      final discountToApprove = allDiscounts.firstWhere(
        (d) => (d['id'] ?? d['order_letter_discount_id']) == discountId,
        orElse: () => {},
      );

      // Get the actual approver_level_id from the discount being approved
      final actualApproverLevelId =
          discountToApprove['approver_level_id'] ?? jobLevelId;

      // Get approver name based on the actual discount level, not the jobLevelId parameter
      String actualApproverName = approverName;
      try {
        final leaderService = locator<LeaderService>();
        final leaderData = await leaderService.getLeaderByUser();
        if (leaderData != null) {
          final nameFromLeader = leaderService.getLeaderNameByDiscountLevel(
              leaderData, actualApproverLevelId);
          if (nameFromLeader != null && nameFromLeader.isNotEmpty) {
            actualApproverName = nameFromLeader;
          }
        }
      } catch (e) {
        // Fallback to default approverName
      }

      // POST to order_letter_approves endpoint
      final approveUrl = ApiConfig.getCreateOrderLetterApproveUrl(token: token);
      final approveData = {
        'order_letter_discount_id': discountId,
        'leader': leaderId,
        'job_level_id': actualApproverLevelId, // Use actual level from discount
        if (approvalLocation != null) 'location': approvalLocation,
      };

      final approveResponse = await dio.post(
        approveUrl,
        data: approveData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      // PUT to order_letter_discounts endpoint
      final updateUrl = ApiConfig.getUpdateOrderLetterDiscountUrl(
        token: token,
        discountId: discountId,
      );
      final updateData = {
        'approved': true,
        'approved_at': currentTime,
        'approver_level': _getApproverLevelName(actualApproverLevelId),
        'approver_name':
            actualApproverName, // Use name based on actual discount level
      };

      final updateResponse = await dio.put(
        updateUrl,
        data: updateData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      // Auto-approve disc5 (level 5) if disc4 (level 4) is being approved
      if (actualApproverLevelId == 4) {
        await _autoApproveDisc5FromDisc4(
          orderLetterId: orderLetterId,
          disc4DiscountId: discountId,
          disc4Data: updateData,
          currentTime: currentTime,
          token: token,
          approvalLocation: approvalLocation,
        );
      }

      // Check if this is the final approval (highest level)
      final isFinalApproval =
          await _isFinalApproval(orderLetterId, actualApproverLevelId);

      Map<String, dynamic>? orderLetterUpdateResult;
      if (isFinalApproval) {
        orderLetterUpdateResult =
            await _updateOrderLetterStatus(orderLetterId, 'Approved');
      }

      // Send notification after approval
      try {
        // Get approver name and level
        String approverName =
            await AuthService.getCurrentUserName() ?? 'Unknown';
        String approvalLevel = 'Level $jobLevelId';

        // Get discount info
        final discounts = await getOrderLetterDiscounts(
          orderLetterId: orderLetterId,
        );
        final discount = discounts.firstWhere(
          (d) => (d['id'] ?? d['order_letter_discount_id']) == discountId,
          orElse: () => {},
        );

        if (discount.isNotEmpty) {
          approverName = discount['approver_name'] as String? ?? approverName;
          approvalLevel =
              discount['approver_level'] as String? ?? approvalLevel;
        }

        // Get order letter info for notification
        final orderLetters = await getOrderLetters();
        final orderLetter = orderLetters.firstWhere(
          (ol) => (ol['id'] ?? ol['order_letter_id']) == orderLetterId,
          orElse: () => {},
        );

        final notificationService = NotificationService();

        // Parse creator user ID - handle both String and int
        int? creatorUserId;
        final creatorValue =
            orderLetter['creator'] ?? orderLetter['creator_id'];
        if (creatorValue != null) {
          if (creatorValue is int) {
            creatorUserId = creatorValue;
          } else if (creatorValue is String) {
            creatorUserId = int.tryParse(creatorValue);
          } else {
            creatorUserId = int.tryParse(creatorValue.toString());
          }
        }

        await notificationService.notifyOnApproval(
          orderLetterId: orderLetterId,
          approvedLevelId: jobLevelId,
          approverName: approverName,
          approvalLevel: approvalLevel,
          isFinalApproval: isFinalApproval,
          orderId: orderLetter['id']?.toString() ??
              orderLetter['order_letter_id']?.toString(),
          noSp: orderLetter['no_sp'] ?? orderLetter['no_sp_number'],
          customerName: orderLetter['customer_name'],
          totalAmount: orderLetter['total'] != null
              ? double.tryParse(orderLetter['total'].toString())
              : null,
          creatorUserId: creatorUserId,
        );
      } catch (e, stackTrace) {
        // Don't fail approval if notification fails
        await ErrorLogger.logError(
          e,
          stackTrace: stackTrace,
          context: 'Failed to send approval notification',
          extra: {'orderLetterId': orderLetterId, 'jobLevelId': jobLevelId},
          fatal: false,
        );
      }

      return {
        'approve_result': approveResponse.data,
        'update_result': updateResponse.data,
        'order_letter_update_result': orderLetterUpdateResult,
        'is_final_approval': isFinalApproval,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Check if this is the final approval (highest level)
  Future<bool> _isFinalApproval(
      int orderLetterId, int currentJobLevelId) async {
    try {
      // Get all discounts for this order letter
      final discounts =
          await getOrderLetterDiscounts(orderLetterId: orderLetterId);

      if (discounts.isEmpty) {
        return false;
      }

      // Find the highest level
      int highestLevel = 0;
      for (final discount in discounts) {
        final level = discount['approver_level_id'] ?? 0;
        if (level > highestLevel) {
          highestLevel = level;
        }
      }

      return currentJobLevelId == highestLevel;
    } catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to check if final approval',
        extra: {'orderLetterId': orderLetterId},
        fatal: false,
      );
      return false;
    }
  }

  /// Update order letter status
  Future<Map<String, dynamic>?> _updateOrderLetterStatus(
      int orderLetterId, String status) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not available');
      }

      final url = ApiConfig.getUpdateOrderLetterUrl(
          token: token, orderLetterId: orderLetterId);
      final updateData = {
        'status': status,
      };

      final response = await dio.put(
        url,
        data: updateData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.data;
    } catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to update order letter status',
        extra: {'orderLetterId': orderLetterId, 'status': status},
        fatal: false,
      );
      return null;
    }
  }

  /// Get Order Letters
  /// Automatically determines the correct API endpoint based on user role
  Future<List<Map<String, dynamic>>> getOrderLetters({
    String? creator,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final token = await AuthService.getToken();
      final currentUserId = await AuthService.getCurrentUserId();

      if (token == null) {
        throw Exception('Token not found');
      }

      if (currentUserId == null) {
        throw Exception('User ID not found');
      }

      // Determine user role to select the correct API endpoint
      final contactWorkExperienceService =
          locator<ContactWorkExperienceService>();
      final userRole = await contactWorkExperienceService
          .getUserRoleForOrderLetters(token: token, userId: currentUserId);

      // Select the appropriate API endpoint based on role
      String url;
      switch (userRole) {
        case 'controller':
          url = ApiConfig.getOrderLettersByControllerUrl(
              token: token,
              userId: currentUserId,
              dateFrom: dateFrom,
              dateTo: dateTo);
          break;
        case 'analyst':
          url = ApiConfig.getOrderLettersByAnalystUrl(
              token: token,
              userId: currentUserId,
              dateFrom: dateFrom,
              dateTo: dateTo);
          break;
        case 'indirect_leader':
          url = ApiConfig.getOrderLettersByIndirectLeaderUrl(
              token: token,
              userId: currentUserId,
              dateFrom: dateFrom,
              dateTo: dateTo);
          break;
        case 'direct_leader':
          url = ApiConfig.getOrderLettersByDirectLeaderUrl(
              token: token,
              userId: currentUserId,
              dateFrom: dateFrom,
              dateTo: dateTo);
          break;
        case 'staff':
        default:
          url = ApiConfig.getOrderLettersUrl(
              token: token,
              userId: currentUserId,
              creator: creator,
              dateFrom: dateFrom,
              dateTo: dateTo);
          break;
      }

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        // Use ApiResponseParser untuk simplify parsing
        return ApiResponseParser.parseOrderLettersList(data);
      } else {
        throw ExceptionHelper.convertDioException(
          DioException(
            requestOptions: RequestOptions(path: url),
            response: response,
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on ServerException catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to fetch order letters',
        fatal: false,
      );
      return [];
    } on NetworkException catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Network error fetching order letters',
        fatal: false,
      );
      return [];
    } catch (e, stackTrace) {
      final exception = ExceptionHelper.convertGenericException(e);
      await ErrorLogger.logError(
        exception,
        stackTrace: stackTrace,
        context: 'Unexpected error fetching order letters',
        fatal: false,
      );
      return [];
    }
  }

  /// Get Order Letters with Complete Data (optimized for approval monitoring)
  /// This method fetches order letters along with their details, discounts, and approvals in one API call
  Future<List<Map<String, dynamic>>> getOrderLettersWithCompleteData({
    String? creator,
    bool includeDetails = true,
    bool includeDiscounts = true,
    bool includeApprovals = true,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw CacheException('Token not found. Silakan login kembali.');
      }

      final url = ApiConfig.getOrderLettersWithCompleteDataUrl(
        token: token,
        creator: creator,
        includeDetails: includeDetails,
        includeDiscounts: includeDiscounts,
        includeApprovals: includeApprovals,
      );

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;

        List<Map<String, dynamic>> result = [];
        if (data is List) {
          result = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['result'] is List) {
          result = List<Map<String, dynamic>>.from(data['result']);
        } else {
          return await getOrderLetters(creator: creator);
        }

        return result;
      } else {
        return await getOrderLetters(creator: creator);
      }
    } catch (e, stackTrace) {
      // Fallback to original method
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get order letters with complete data, falling back',
        extra: {'creator': creator},
        fatal: false,
      );
      return await getOrderLetters(creator: creator);
    }
  }

  /// Get Order Letter Details
  Future<List<Map<String, dynamic>>> getOrderLetterDetails(
      {int? orderLetterId}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw CacheException('Token not found. Silakan login kembali.');
      }

      final url = ApiConfig.getOrderLetterDetailsUrl(
          token: token, orderLetterId: orderLetterId);

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        // Use ApiResponseParser untuk simplify parsing
        return ApiResponseParser.parseOrderLetterDetailsList(data);
      } else {
        throw ExceptionHelper.convertDioException(
          DioException(
            requestOptions: RequestOptions(path: url),
            response: response,
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on ServerException catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to fetch order letter details',
        fatal: false,
      );
      return [];
    } on NetworkException catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Network error fetching order letter details',
        fatal: false,
      );
      return [];
    } catch (e, stackTrace) {
      final exception = ExceptionHelper.convertGenericException(e);
      await ErrorLogger.logError(
        exception,
        stackTrace: stackTrace,
        context: 'Unexpected error fetching order letter details',
        fatal: false,
      );
      return [];
    }
  }

  /// Get Order Letter Discounts
  Future<List<Map<String, dynamic>>> getOrderLetterDiscounts(
      {int? orderLetterId}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw CacheException('Token not found. Silakan login kembali.');
      }

      final url = ApiConfig.getOrderLetterDiscountsUrl(
          token: token, orderLetterId: orderLetterId);

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        // Use ApiResponseParser untuk simplify parsing
        final allDiscounts =
            ApiResponseParser.parseOrderLetterDiscountsList(data);

        // Filter discounts by order_letter_id if specified
        List<Map<String, dynamic>> discountsToReturn = allDiscounts;
        if (orderLetterId != null) {
          discountsToReturn = allDiscounts.where((discount) {
            final discountOrderLetterId =
                discount['order_letter_id'] ?? discount['orderLetterId'];
            if (discountOrderLetterId == null) {
              return false;
            }
            final parsedId =
                int.tryParse(discountOrderLetterId.toString().trim());
            return parsedId == orderLetterId;
          }).toList();
        }

        return discountsToReturn;
      } else {
        throw ExceptionHelper.convertDioException(
          DioException(
            requestOptions: RequestOptions(path: url),
            response: response,
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on ServerException catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to fetch order letter discounts',
        fatal: false,
      );
      return [];
    } on NetworkException catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Network error fetching order letter discounts',
        fatal: false,
      );
      return [];
    } catch (e, stackTrace) {
      final exception = ExceptionHelper.convertGenericException(e);
      await ErrorLogger.logError(
        exception,
        stackTrace: stackTrace,
        context: 'Unexpected error fetching order letter discounts',
        fatal: false,
      );
      return [];
    }
  }

  /// Get Order Letter Approves
  Future<List<Map<String, dynamic>>> getOrderLetterApproves({
    int? orderLetterId,
    String? approverId,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw CacheException('Token not found. Silakan login kembali.');
      }

      final url = ApiConfig.getOrderLetterApprovesUrl(
        token: token,
        orderLetterId: orderLetterId,
        approverId: approverId,
      );
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        // Use ApiResponseParser untuk simplify parsing
        return ApiResponseParser.parseOrderLetterApprovesList(data);
      } else {
        throw ExceptionHelper.convertDioException(
          DioException(
            requestOptions: RequestOptions(path: url),
            response: response,
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on ServerException catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to fetch order letter approves',
        fatal: false,
      );
      return [];
    } on NetworkException catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Network error fetching order letter approves',
        fatal: false,
      );
      return [];
    } catch (e, stackTrace) {
      final exception = ExceptionHelper.convertGenericException(e);
      await ErrorLogger.logError(
        exception,
        stackTrace: stackTrace,
        context: 'Unexpected error fetching order letter approves',
        fatal: false,
      );
      return [];
    }
  }

  /// Create Order Letter Approve
  Future<Map<String, dynamic>> createOrderLetterApprove(
      Map<String, dynamic> approveData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw CacheException('Token not found. Silakan login kembali.');
      }

      final url = ApiConfig.getCreateOrderLetterApproveUrl(token: token);
      final response = await dio.post(url, data: approveData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Order letter approve created successfully',
        };
      } else {
        throw ExceptionHelper.convertDioException(
          DioException(
            requestOptions: RequestOptions(path: url),
            response: response,
            type: DioExceptionType.badResponse,
          ),
        );
      }
    } on ServerException catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to create order letter approve',
        fatal: false,
      );
      return {
        'success': false,
        'message': e.message,
      };
    } on NetworkException catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Network error creating order letter approve',
        fatal: false,
      );
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e, stackTrace) {
      final exception = ExceptionHelper.convertGenericException(e);
      await ErrorLogger.logError(
        exception,
        stackTrace: stackTrace,
        context: 'Unexpected error creating order letter approve',
        fatal: true,
      );
      return {
        'success': false,
        'message': exception is ServerException
            ? exception.message
            : 'Error creating order letter approve: $e',
      };
    }
  }

  /// Determine final order status after discount creation
  Future<String> _determineFinalOrderStatus(
      int? orderLetterId, dynamic discountsData) async {
    try {
      if (orderLetterId == null) return 'Pending';

      // Check if this is an indirect checkout (all items have isIndirect: true)
      bool isIndirectCheckout = false;
      if (discountsData is List<Map<String, dynamic>>) {
        isIndirectCheckout = discountsData.isNotEmpty &&
            discountsData.every((item) => item['isIndirect'] == true);
      }

      // For indirect checkout, all discounts are auto-approved
      if (isIndirectCheckout) {
        return 'Approved';
      }

      // Extract all discount values from either format
      List<double> allDiscounts = [];
      if (discountsData is List<double>) {
        // Legacy format - direct list of doubles
        allDiscounts = discountsData;
      } else if (discountsData is List<Map<String, dynamic>>) {
        // New structured format - extract discounts from each item
        for (final itemDiscount in discountsData) {
          final discounts = itemDiscount['discounts'] as List<dynamic>?;
          if (discounts != null) {
            allDiscounts.addAll(discounts.cast<double>());
          }
        }
      }

      // Filter significant discounts
      final significantDiscounts = allDiscounts.where((d) => d > 0.0).toList();

      if (significantDiscounts.isEmpty) {
        // No discounts → Still need Direct Leader approval
        return 'Pending';
      }

      // Get created discount records to check approval levels
      final discountRecords =
          await getOrderLetterDiscounts(orderLetterId: orderLetterId);

      if (discountRecords.isEmpty) {
        // No discount records created → Still need Direct Leader approval
        return 'Pending';
      }

      // Check approval status for all discount levels
      bool allRequiredApprovalsCompleted = true;
      bool hasPendingApprovals = false;

      for (final discount in discountRecords) {
        final level = discount['approver_level_id'] ?? 1;
        final approved = discount['approved'];

        // Check if this level needs approval
        if (level == 1) {
          // User level should always be auto-approved
          if (approved != true) {
            allRequiredApprovalsCompleted = false;
          }
        } else {
          // Higher levels: check if approval is needed
          if (approved == null) {
            // Pending approval
            hasPendingApprovals = true;
            allRequiredApprovalsCompleted = false;
          } else if (approved == false) {
            // Rejected
            return 'Rejected';
          }
          // If approved == true, continue checking other levels
        }
      }

      // Determine final status
      if (allRequiredApprovalsCompleted && !hasPendingApprovals) {
        return 'Approved';
      } else if (hasPendingApprovals) {
        return 'Pending';
      } else {
        return 'Approved'; // Default to approved if all checks pass
      }
    } catch (e, stackTrace) {
      // Default to Pending if there's any error
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to determine final order status',
        extra: {'orderLetterId': orderLetterId},
        fatal: false,
      );
      return 'Pending';
    }
  }

  /// Process structured discount data (per item)
  Future<void> _processStructuredDiscounts(
    List<Map<String, dynamic>> itemDiscounts,
    List<Map<String, dynamic>> detailResults,
    List<Map<String, dynamic>> discountResults,
    List<int?>? leaderIds,
    int orderLetterId, {
    int? selectedSpvId,
    String? selectedSpvName,
    int? selectedRsmId,
    String? selectedRsmName,
  }) async {
    try {
      // Fetch leader data ONCE at the beginning to avoid multiple API calls
      final leaderService = locator<LeaderService>();
      final leaderData = await leaderService.getLeaderByUser();

      final Set<String> createdDiscounts = {};

      String normalize(String value) => value.trim().toLowerCase();

      final Map<String, List<int>> availableDetailIds = {};

      // First, collect all kasur items
      final List<Map<String, dynamic>> kasurDetails = [];
      final List<Map<String, dynamic>> nonKasurDetails = [];

      for (final detailResult in detailResults) {
        if (detailResult['success'] && detailResult['data'] != null) {
          final rawData = detailResult['data'];
          final detailData = rawData['location'] ?? rawData;
          final detailType =
              (detailData['item_type'] ?? '').toString().toLowerCase();

          if (detailType == 'kasur') {
            kasurDetails.add(detailData);
          } else if (detailType == 'divan' ||
              detailType == 'headboard' ||
              detailType == 'sorong') {
            // Store non-kasur items in case we need them (when no kasur exists)
            nonKasurDetails.add(detailData);
          }
        }
      }

      // Use kasur items if available, otherwise use primary non-kasur items (divan, headboard, sorong)
      final List<Map<String, dynamic>> itemsToProcess =
          kasurDetails.isNotEmpty ? kasurDetails : nonKasurDetails;

      for (final detailData in itemsToProcess) {
        final detailName = normalize((detailData['desc_1'] ?? '').toString());
        final detailSize = normalize((detailData['desc_2'] ?? '').toString());

        final rawDetailId = detailData['id'] ??
            detailData['order_letter_detail_id'] ??
            detailData['detail_id'];
        final parsedId = rawDetailId is int
            ? rawDetailId
            : int.tryParse(rawDetailId?.toString() ?? '');

        if (parsedId == null) {
          continue;
        }

        final primaryKey = '$detailName|$detailSize';
        final secondaryKey = '$detailName|';

        availableDetailIds.putIfAbsent(primaryKey, () => <int>[]).add(parsedId);
        if (secondaryKey != primaryKey) {
          availableDetailIds
              .putIfAbsent(secondaryKey, () => <int>[])
              .add(parsedId);
        }
      }

      for (final itemDiscount in itemDiscounts) {
        final kasurNameRaw = (itemDiscount['kasurName'] ?? '').toString();
        final productSizeRaw = (itemDiscount['productSize'] ?? '').toString();
        final isIndirect = itemDiscount['isIndirect'] as bool? ?? false;
        final storeName = itemDiscount['storeName'] as String?;

        final discounts = itemDiscount['discounts'] as List<double>;

        final normalizedName = normalize(kasurNameRaw);
        final normalizedSize = normalize(productSizeRaw);

        int? kasurOrderLetterDetailId;

        final primaryKey = '$normalizedName|$normalizedSize';
        final secondaryKey = '$normalizedName|';

        for (final key in [primaryKey, secondaryKey]) {
          final pool = availableDetailIds[key];
          if (pool != null && pool.isNotEmpty) {
            kasurOrderLetterDetailId = pool.removeAt(0);
            break;
          }
        }

        // If matching failed, try to find first available kasur detail ID as fallback
        if (kasurOrderLetterDetailId == null) {
          // Log for debugging
          await ErrorLogger.logError(
            Exception('Failed to match discount item with order detail'),
            stackTrace: StackTrace.current,
            context: 'Discount item matching failed',
            extra: {
              'kasurName': kasurNameRaw,
              'productSize': productSizeRaw,
              'normalizedName': normalizedName,
              'normalizedSize': normalizedSize,
              'availableKeys': availableDetailIds.keys.toList(),
              'orderLetterId': orderLetterId,
            },
            fatal: false,
          );

          // Fallback: use first available kasur detail ID
          for (final detailResult in detailResults) {
            if (detailResult['success'] && detailResult['data'] != null) {
              final rawData = detailResult['data'];
              final detailData = rawData['location'] ?? rawData;
              final detailType =
                  (detailData['item_type'] ?? '').toString().toLowerCase();

              // Prefer kasur, but use divan/headboard/sorong if no kasur exists
              bool isPrimaryItem = detailType == 'kasur' ||
                  (detailType == 'divan' ||
                      detailType == 'headboard' ||
                      detailType == 'sorong');

              if (isPrimaryItem) {
                final rawDetailId = detailData['id'] ??
                    detailData['order_letter_detail_id'] ??
                    detailData['detail_id'];
                final parsedId = rawDetailId is int
                    ? rawDetailId
                    : int.tryParse(rawDetailId?.toString() ?? '');

                if (parsedId != null) {
                  kasurOrderLetterDetailId = parsedId;
                  break;
                }
              }
            }
          }

          // If still null, skip this item
          if (kasurOrderLetterDetailId == null) {
            await ErrorLogger.logError(
              Exception('No matching detail ID found for discount item'),
              stackTrace: StackTrace.current,
              context: 'No fallback detail ID available',
              extra: {
                'kasurName': kasurNameRaw,
                'orderLetterId': orderLetterId,
              },
              fatal: false,
            );
            continue;
          }
        }

        if (primaryKey != secondaryKey) {
          availableDetailIds[primaryKey]?.remove(kasurOrderLetterDetailId);
          availableDetailIds[secondaryKey]?.remove(kasurOrderLetterDetailId);
        } else {
          availableDetailIds[primaryKey]?.remove(kasurOrderLetterDetailId);
        }

        // For indirect checkout, process all store discounts differently
        if (isIndirect && storeName != null) {
          // Indirect checkout: All discounts belong to the store
          for (int i = 0; i < discounts.length; i++) {
            final discount = discounts[i];
            if (discount <= 0) continue;

            final discountKey = '${kasurOrderLetterDetailId}_${i}_$discount';
            if (createdDiscounts.contains(discountKey)) {
              continue;
            }

            await _createIndirectDiscount(
              orderLetterId: orderLetterId,
              kasurOrderLetterDetailId: kasurOrderLetterDetailId,
              discount: discount,
              discountIndex: i,
              discountResults: discountResults,
              storeName: storeName,
            );

            createdDiscounts.add(discountKey);
          }
        } else {
          // Direct checkout: Use user levels (User, Direct Leader, etc.)
          int maxLevelToCreate = discounts.length > 2 ? discounts.length : 2;

          for (int i = 0; i < maxLevelToCreate; i++) {
            final discount = i < discounts.length ? discounts[i] : 0.0;
            if (i > 1 && discount <= 0) continue;

            final discountKey = '${kasurOrderLetterDetailId}_${i}_$discount';
            if (createdDiscounts.contains(discountKey)) {
              continue;
            }

            await _createSingleDiscount(
              orderLetterId: orderLetterId,
              kasurOrderLetterDetailId: kasurOrderLetterDetailId,
              discount: discount,
              discountIndex: i,
              leaderIds: leaderIds,
              discountResults: discountResults,
              kasurName: kasurNameRaw,
              leaderData: leaderData,
              selectedSpvId: selectedSpvId,
              selectedSpvName: selectedSpvName,
              selectedRsmId: selectedRsmId,
              selectedRsmName: selectedRsmName,
            );

            createdDiscounts.add(discountKey);
          }
        }
      }
    } catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Error processing structured discounts',
        extra: {
          'orderLetterId': orderLetterId,
          'itemDiscountsCount': itemDiscounts.length,
          'detailResultsCount': detailResults.length,
        },
        fatal: false,
      );
      // Re-throw to allow fallback to default entries
      rethrow;
    }
  }

  /// Process legacy discount data (all to first kasur)
  Future<void> _processLegacyDiscounts(
    List<double> discounts,
    List<Map<String, dynamic>> detailResults,
    List<Map<String, dynamic>> discountResults,
    List<int?>? leaderIds,
    int orderLetterId, {
    int? selectedSpvId,
    String? selectedSpvName,
    int? selectedRsmId,
    String? selectedRsmName,
  }) async {
    // Fetch leader data ONCE at the beginning to avoid multiple API calls
    final leaderService = locator<LeaderService>();
    final leaderData = await leaderService.getLeaderByUser();

    // Find first kasur detail ID
    int? kasurOrderLetterDetailId;
    for (final detailResult in detailResults) {
      if (detailResult['success'] && detailResult['data'] != null) {
        final rawData = detailResult['data'];
        final detailData = rawData['location'] ?? rawData;
        if (detailData['item_type'] == 'Mattress' ||
            detailData['item_type'] == 'kasur') {
          // detailData sudah berisi location data, langsung akses ID
          kasurOrderLetterDetailId = detailData['id'] ??
              detailData['order_letter_detail_id'] ??
              detailData['detail_id'];
          break;
        }
      }
    }

    if (kasurOrderLetterDetailId == null) {
      return;
    }

    // Process all discounts for first kasur
    // Modified logic: Always create entries up to Direct Leader (level 2)

    // Always create up to Direct Leader level (2 levels total: User, Direct Leader)
    // If more discounts are provided (Indirect Leader, Controller, Analyst), create those too
    int maxLevelToCreate = discounts.length > 2 ? discounts.length : 2;

    for (int i = 0; i < maxLevelToCreate; i++) {
      final discount = i < discounts.length ? discounts[i] : 0.0;

      // Always create entries for:
      // - Level 0 (User)
      // - Level 1 (Direct Leader)
      // For levels 2+ (Indirect Leader, Analyst, Controller), only create if discount > 0
      if (i > 1 && discount <= 0) continue;

      await _createSingleDiscount(
        orderLetterId: orderLetterId,
        kasurOrderLetterDetailId: kasurOrderLetterDetailId,
        discount: discount,
        discountIndex: i,
        leaderIds: leaderIds,
        discountResults: discountResults,
        kasurName: 'First Kasur (Legacy)',
        leaderData: leaderData,
        selectedSpvId: selectedSpvId,
        selectedSpvName: selectedSpvName,
        selectedRsmId: selectedRsmId,
        selectedRsmName: selectedRsmName,
      );
    }
  }

  Future<void> _createDefaultEntriesForMissingItems(
    List<Map<String, dynamic>> itemDiscounts,
    List<Map<String, dynamic>> detailResults,
    List<Map<String, dynamic>> discountResults,
    List<int?>? leaderIds,
    int orderLetterId, {
    int? selectedSpvId,
    String? selectedSpvName,
    int? selectedRsmId,
    String? selectedRsmName,
  }) async {
    try {
      // Fetch leader data ONCE at the beginning to avoid multiple API calls
      final leaderService = locator<LeaderService>();
      final leaderData = await leaderService.getLeaderByUser();

      String normalize(String value) => value.trim().toLowerCase();

      // Build a set of item names that already have discounts
      final Set<String> processedItemNames = {};
      for (final itemDiscount in itemDiscounts) {
        final itemName =
            normalize((itemDiscount['kasurName'] ?? '').toString());
        if (itemName.isNotEmpty) {
          processedItemNames.add(itemName);
        }
      }

      // Process each detail to find items that weren't processed
      for (final detailResult in detailResults) {
        if (detailResult['success'] && detailResult['data'] != null) {
          final rawData = detailResult['data'];
          final detailData = rawData['location'] ?? rawData;

          // Process kasur items first, but if no kasur exists, process primary items (divan, headboard, sorong)
          // This ensures discount entries are created even when only divan/headboard/sorong exist
          final itemType =
              (detailData['item_type'] ?? '').toString().toLowerCase();

          // Skip bonus items - they should never receive discount entries
          if (itemType == 'bonus') {
            continue;
          }

          // Check if kasur exists in any detail result
          bool hasKasur = false;
          for (final dr in detailResults) {
            if (dr['success'] && dr['data'] != null) {
              final rd = dr['data'];
              final dd = rd['location'] ?? rd;
              if ((dd['item_type'] ?? '').toString().toLowerCase() == 'kasur') {
                hasKasur = true;
                break;
              }
            }
          }

          // If kasur exists, only process kasur. Otherwise, process primary items (divan, headboard, sorong).
          if (hasKasur && itemType != 'kasur') {
            continue;
          }

          final itemName = normalize((detailData['desc_1'] ?? '').toString());

          // Skip if this item was already processed (has discounts)
          if (processedItemNames.contains(itemName)) {
            continue;
          }

          final orderLetterDetailId = detailData['id'] ??
              detailData['order_letter_detail_id'] ??
              detailData['detail_id'];

          if (orderLetterDetailId == null) {
            continue;
          }

          // Create default discount entries (User and Direct Leader levels)
          for (int i = 0; i < 2; i++) {
            await _createSingleDiscount(
              orderLetterId: orderLetterId,
              kasurOrderLetterDetailId: orderLetterDetailId,
              discount: 0.0,
              discountIndex: i,
              leaderIds: leaderIds,
              discountResults: discountResults,
              kasurName: detailData['desc_1'] ?? 'Unknown',
              leaderData:
                  leaderData, // Pass leader data to avoid multiple API calls
              selectedSpvId: selectedSpvId,
              selectedSpvName: selectedSpvName,
              selectedRsmId: selectedRsmId,
              selectedRsmName: selectedRsmName,
            );
          }

          processedItemNames.add(itemName);
        }
      }
    } catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Error creating default entries for missing items',
        extra: {'orderLetterId': orderLetterId},
        fatal: false,
      );
    }
  }

  /// Create default discount entries when no discounts are provided
  Future<void> _createDefaultDiscountEntries(
    List<Map<String, dynamic>> detailResults,
    List<Map<String, dynamic>> discountResults,
    List<int?>? leaderIds,
    int orderLetterId, {
    int? selectedSpvId,
    String? selectedSpvName,
    int? selectedRsmId,
    String? selectedRsmName,
  }) async {
    try {
      // Fetch leader data ONCE at the beginning to avoid multiple API calls
      final leaderService = locator<LeaderService>();
      final leaderData = await leaderService.getLeaderByUser();

      // Process each detail (item) in the order
      for (int idx = 0; idx < detailResults.length; idx++) {
        final detailResult = detailResults[idx];

        if (detailResult['success'] && detailResult['data'] != null) {
          final rawData = detailResult['data'];
          final detailData = rawData['location'] ?? rawData;

          final itemType =
              (detailData['item_type'] ?? '').toString().toLowerCase();

          // Skip bonus items - they should never receive discount entries
          if (itemType == 'bonus') {
            continue;
          }

          // Check if kasur exists in any detail result
          bool hasKasur = false;
          for (final dr in detailResults) {
            if (dr['success'] && dr['data'] != null) {
              final rd = dr['data'];
              final dd = rd['location'] ?? rd;
              if ((dd['item_type'] ?? '').toString().toLowerCase() == 'kasur') {
                hasKasur = true;
                break;
              }
            }
          }

          // If kasur exists, only create discount entries for kasur items
          // Otherwise, create for primary items (divan, headboard, sorong)
          if (hasKasur && itemType != 'kasur') {
            continue;
          }

          final orderLetterDetailId = detailData['id'] ??
              detailData['order_letter_detail_id'] ??
              detailData['detail_id'];

          if (orderLetterDetailId == null) {
            continue;
          }

          final itemName = detailData['desc_1'] ?? 'Unknown';

          // Create discount entries up to Direct Leader (level 2)
          for (int i = 0; i < 2; i++) {
            await _createSingleDiscount(
              orderLetterId: orderLetterId,
              kasurOrderLetterDetailId: orderLetterDetailId,
              discount: 0.0,
              discountIndex: i,
              leaderIds: leaderIds,
              discountResults: discountResults,
              kasurName: itemName,
              leaderData: leaderData,
              selectedSpvId: selectedSpvId,
              selectedSpvName: selectedSpvName,
              selectedRsmId: selectedRsmId,
              selectedRsmName: selectedRsmName,
            );
          }
        }
      }
    } catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Error creating default discount entries',
        extra: {'orderLetterId': orderLetterId},
        fatal: false,
      );
    }
  }

  /// Create a single discount entry
  Future<void> _createSingleDiscount({
    required int orderLetterId,
    required int kasurOrderLetterDetailId,
    required double discount,
    required int discountIndex,
    required List<int?>? leaderIds,
    required List<Map<String, dynamic>> discountResults,
    required String kasurName,
    LeaderByUserModel? leaderData,
    int? selectedSpvId,
    String? selectedSpvName,
    int? selectedRsmId,
    String? selectedRsmName,
  }) async {
    int? approverId;
    String approverName = '';
    String approverLevel = '';
    String approverWorkTitle = '';
    bool? approvedValue;
    String? approvedAt;

    try {
      // Use provided leaderData, or fetch if not provided (fallback for legacy code)
      final effectiveLeaderData =
          leaderData ?? await locator<LeaderService>().getLeaderByUser();

      if (effectiveLeaderData != null) {
        final approvalLevel =
            _mapDiscountIndexToApprovalLevel(discountIndex + 1);

        switch (approvalLevel) {
          case 1: // User
            approverId = effectiveLeaderData.user.id;
            approverName = effectiveLeaderData.user.fullName
                .trim(); // Trim to remove trailing spaces
            approverWorkTitle = effectiveLeaderData.user.workTitle;
            break;
          case 2: // Direct Leader (SPV) - Use manually selected if available
            if (selectedSpvId != null && selectedSpvName != null) {
              approverId = selectedSpvId;
              approverName = selectedSpvName.trim();
              approverWorkTitle = 'Selected SPV';
            } else if (effectiveLeaderData.directLeader != null) {
              approverId = effectiveLeaderData.directLeader!.id;
              approverName = effectiveLeaderData.directLeader!.fullName
                  .trim(); // Trim to remove trailing spaces
              approverWorkTitle = effectiveLeaderData.directLeader!.workTitle;
            }
            break;
          case 3: // Indirect Leader (RSM) - Use manually selected if available
            if (selectedRsmId != null && selectedRsmName != null) {
              approverId = selectedRsmId;
              approverName = selectedRsmName.trim();
              approverWorkTitle = 'Selected RSM';
            } else if (effectiveLeaderData.indirectLeader != null) {
              approverId = effectiveLeaderData.indirectLeader!.id;
              approverName = effectiveLeaderData.indirectLeader!.fullName
                  .trim(); // Trim to remove trailing spaces
              approverWorkTitle = effectiveLeaderData.indirectLeader!.workTitle;
            }
            break;
          case 4: // Analyst - remains automatic
            if (effectiveLeaderData.analyst != null) {
              approverId = effectiveLeaderData.analyst!.id;
              approverName = effectiveLeaderData.analyst!.fullName
                  .trim(); // Trim to remove trailing spaces
              approverWorkTitle = effectiveLeaderData.analyst!.workTitle;
            }
            break;
          case 5: // Controller
            if (effectiveLeaderData.controller != null) {
              approverId = effectiveLeaderData.controller!.id;
              approverName = effectiveLeaderData.controller!.fullName
                  .trim(); // Trim to remove trailing spaces
              approverWorkTitle = effectiveLeaderData.controller!.workTitle;
            }
            break;
          default:
            approverId = null;
            approverName = '';
            approverWorkTitle = '';
        }

        approverLevel = _getApproverLevelName(approvalLevel);

        // Level 1 discounts should be auto-approved (user created the order)
        if (discountIndex == 0) {
          approvedValue = true;
          approvedAt = DateTime.now().toIso8601String();
        } else {
          approvedValue = null;
          approvedAt = null;
        }

        // Skip creating discount entry if approverId is null (for all levels except User)
        // This prevents creating entries without valid approvers, especially for Analyst/Controller
        if (approverId == null && approvalLevel > 1) {
          return;
        }
      } else {
        return; // Skip creating discount if no leader data
      }
    } catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to create single discount, skipping',
        extra: {
          'orderLetterId': orderLetterId,
          'discountIndex': discountIndex,
        },
        fatal: false,
      );
      return; // Skip creating discount on error
    }

    final discountData = {
      'order_letter_id': orderLetterId,
      'order_letter_detail_id': kasurOrderLetterDetailId,
      'discount': discount.toString(),
      'approver': approverId,
      'approver_name': approverName,
      'approver_level_id': _mapDiscountIndexToApprovalLevel(discountIndex + 1),
      'approver_level': approverLevel,
      'approver_work_title': approverWorkTitle,
      'approved': approvedValue,
      'approved_at': approvedAt,
    };

    final discountResult = await createOrderLetterDiscount(discountData);
    discountResults.add(discountResult);
  }

  /// Create a discount entry for INDIRECT checkout (store discounts)
  /// All discounts are attributed to the store, not user levels
  Future<void> _createIndirectDiscount({
    required int orderLetterId,
    required int kasurOrderLetterDetailId,
    required double discount,
    required int discountIndex,
    required List<Map<String, dynamic>> discountResults,
    required String storeName,
  }) async {
    // For indirect checkout:
    // - All discounts are store discounts
    // - approver_name = store name
    // - approver_level = "Store Discount {index+1}"
    // - Auto-approved (store discounts don't need approval)

    final approverLevel = 'Diskon Toko ${discountIndex + 1}';
    final approvedAt = DateTime.now().toIso8601String();

    final discountData = {
      'order_letter_id': orderLetterId,
      'order_letter_detail_id': kasurOrderLetterDetailId,
      'discount': discount.toString(),
      'approver': null, // No specific user approver for store discounts
      'approver_name': storeName, // Store name as approver
      'approver_level_id': discountIndex + 1,
      'approver_level': approverLevel,
      'approver_work_title': 'Toko', // Work title for store
      'approved': true, // Store discounts are auto-approved
      'approved_at': approvedAt,
    };

    final discountResult = await createOrderLetterDiscount(discountData);
    discountResults.add(discountResult);
  }

  /// Get count of pending discounts for a specific user level in an order letter
  Future<int> getPendingDiscountCount({
    required int orderLetterId,
    required int leaderId,
    required int jobLevelId,
  }) async {
    try {
      final allDiscounts =
          await getOrderLetterDiscounts(orderLetterId: orderLetterId);

      int pendingCount = 0;
      for (final discount in allDiscounts) {
        final approverId = discount['approver'];
        final approverLevelId = discount['approver_level_id'];
        final approved = discount['approved'];

        // Check if this discount is for the current user and level, and is pending
        if (approverId == leaderId &&
            approverLevelId == jobLevelId &&
            (approved == null || approved == false)) {
          pendingCount++;
        }
      }

      return pendingCount;
    } catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to get pending discount count',
        extra: {
          'orderLetterId': orderLetterId,
          'leaderId': leaderId,
          'jobLevelId': jobLevelId,
        },
        fatal: false,
      );
      return 0;
    }
  }

  /// Get approver level name
  int _mapDiscountIndexToApprovalLevel(int level) {
    switch (level) {
      case 1:
        return 1; // User
      case 2:
        return 2; // Direct Leader
      case 3:
        return 3; // Indirect Leader
      case 4:
        return 4; // Analyst
      case 5:
        return 5; // Controller
      default:
        return level;
    }
  }

  /// Auto-approve disc5 (level 5) when disc4 (level 4) is approved
  /// Copy all data from disc4 to disc5
  Future<void> _autoApproveDisc5FromDisc4({
    required int orderLetterId,
    required int disc4DiscountId,
    required Map<String, dynamic> disc4Data,
    required String currentTime,
    required String token,
    String? approvalLocation,
  }) async {
    try {
      // Get all discounts for this order letter
      final allDiscounts =
          await getOrderLetterDiscounts(orderLetterId: orderLetterId);

      // Find disc4 discount to get its detail_id
      final disc4Discount = allDiscounts.firstWhere(
        (d) => (d['id'] ?? d['order_letter_discount_id']) == disc4DiscountId,
        orElse: () => {},
      );

      if (disc4Discount.isEmpty) {
        return; // Disc4 not found, skip
      }

      final orderLetterDetailId =
          disc4Discount['order_letter_detail_id'] ?? disc4Discount['detail_id'];

      // Find disc5 discount (level 5) for the same order letter detail
      final disc5Discount = allDiscounts.firstWhere(
        (d) =>
            (d['approver_level_id'] ?? 0) == 5 &&
            (d['order_letter_detail_id'] ?? d['detail_id']) ==
                orderLetterDetailId,
        orElse: () => {},
      );

      if (disc5Discount.isEmpty) {
        return; // Disc5 not found, skip
      }

      final disc5DiscountId =
          disc5Discount['id'] ?? disc5Discount['order_letter_discount_id'];

      // Get approver info from disc4
      final disc4ApproverId = disc4Discount['approver'];
      final disc4ApproverName =
          disc4Data['approver_name'] ?? disc4Discount['approver_name'] ?? '';
      final disc4ApproverLevel =
          disc4Data['approver_level'] ?? disc4Discount['approver_level'] ?? '';

      // POST to order_letter_approves endpoint for disc5
      final approveUrl = ApiConfig.getCreateOrderLetterApproveUrl(token: token);
      final approveData = {
        'order_letter_discount_id': disc5DiscountId,
        'leader': disc4ApproverId, // Use same approver as disc4
        'job_level_id': 5, // Controller level
        if (approvalLocation != null) 'location': approvalLocation,
      };

      await dio.post(
        approveUrl,
        data: approveData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      // PUT to order_letter_discounts endpoint - copy data from disc4
      final updateUrl = ApiConfig.getUpdateOrderLetterDiscountUrl(
        token: token,
        discountId: disc5DiscountId,
      );
      final updateData = {
        'approved': true,
        'approved_at': currentTime, // Same time as disc4 approval
        'approver_level': disc4ApproverLevel, // Copy from disc4
        'approver_name': disc4ApproverName, // Copy from disc4
      };

      await dio.put(
        updateUrl,
        data: updateData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
    } catch (e, stackTrace) {
      // Log error but don't fail the disc4 approval
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to auto-approve disc5 from disc4',
        extra: {
          'orderLetterId': orderLetterId,
          'disc4DiscountId': disc4DiscountId,
        },
        fatal: false,
      );
    }
  }

  String _getApproverLevelName(int level) {
    switch (level) {
      case 1:
        return 'User';
      case 2:
        return 'Supervisor';
      case 3:
        return 'RSM';
      case 4:
        return 'Analyst';
      case 5:
        return 'Controller';
      default:
        return 'Unknown';
    }
  }
}
