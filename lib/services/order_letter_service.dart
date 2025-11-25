import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../config/dependency_injection.dart';
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
  }) async {
    try {
      // Step 1: POST Order Letter
      final orderLetterResult = await createOrderLetter(orderLetterData);
      if (orderLetterResult['success'] != true) {
        return orderLetterResult;
      }

      // Extract order letter ID and no_sp from response
      final responseData = orderLetterResult['data'];

      int? orderLetterId;
      String? noSp;

      // Try different possible response formats
      if (responseData is Map<String, dynamic>) {
        // Try direct access
        orderLetterId = responseData['id'] ?? responseData['order_letter_id'];
        noSp = responseData['no_sp'] ?? responseData['no_sp_number'];

        // If still null, try location object (common in API responses)
        if (orderLetterId == null &&
            responseData['location'] is Map<String, dynamic>) {
          final location = responseData['location'] as Map<String, dynamic>;
          orderLetterId = location['id'] ?? location['order_letter_id'];
          noSp = location['no_sp'] ?? location['no_sp_number'];
        }

        // If still null, try nested access
        if (orderLetterId == null &&
            responseData['result'] is Map<String, dynamic>) {
          final result = responseData['result'] as Map<String, dynamic>;
          orderLetterId = result['id'] ?? result['order_letter_id'];
          noSp = result['no_sp'] ?? result['no_sp_number'];
        }

        // If still null, try array access
        if (orderLetterId == null &&
            responseData['result'] is List &&
            (responseData['result'] as List).isNotEmpty) {
          final firstResult = (responseData['result'] as List).first;
          if (firstResult is Map<String, dynamic>) {
            orderLetterId = firstResult['id'] ?? firstResult['order_letter_id'];
            noSp = firstResult['no_sp'] ?? firstResult['no_sp_number'];
          }
        }
      }

      // If we still don't have the ID, we need to fetch the latest order letter
      if (orderLetterId == null) {
        final latestOrderLetters =
            await getOrderLetters(creator: orderLetterData['creator']);
        if (latestOrderLetters.isNotEmpty) {
          // Sort by created_at to get the most recent one
          latestOrderLetters.sort((a, b) {
            final aCreatedAt = a['created_at'] ?? '';
            final bCreatedAt = b['created_at'] ?? '';
            return bCreatedAt
                .compareTo(aCreatedAt); // Descending order (newest first)
          });

          final latestOrder = latestOrderLetters.first;
          orderLetterId = latestOrder['id'] ?? latestOrder['order_letter_id'];
          noSp = latestOrder['no_sp'] ?? latestOrder['no_sp_number'];
        }
      }

      if (orderLetterId == null) {
        return {
          'success': false,
          'message': 'Failed to get order letter ID from response',
          'responseData': responseData,
        };
      }

      // Step 2: POST Order Letter Details
      final List<Map<String, dynamic>> detailResults = [];
      for (final detail in detailsData) {
        final detailWithId = Map<String, dynamic>.from(detail);
        detailWithId['order_letter_id'] = orderLetterId;
        detailWithId['no_sp'] = noSp;

        final detailResult = await createOrderLetterDetail(detailWithId);
        detailResults.add(detailResult);

        if (detailResult['success']) {
        } else {}
      }

      // Step 3: POST Order Letter Discounts with Leader Data
      final List<Map<String, dynamic>> discountResults = [];

      // Handle different discount data formats
      if (discountsData is List<Map<String, dynamic>>) {
        // New structured format with per-item discount information
        if (discountsData.isEmpty) {
          // If no discounts, create default entries for all items up to Direct Leader
          await _createDefaultDiscountEntries(
              detailResults, discountResults, leaderIds, orderLetterId);
        } else {
          await _processStructuredDiscounts(discountsData, detailResults,
              discountResults, leaderIds, orderLetterId);
        }
      } else if (discountsData is List<double>) {
        // Legacy format - process all discounts for first kasur
        await _processLegacyDiscounts(discountsData, detailResults,
            discountResults, leaderIds, orderLetterId);
      } else {
        // No discounts data provided, create default entries
        await _createDefaultDiscountEntries(
            detailResults, discountResults, leaderIds, orderLetterId);
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
              case 1: // Direct Leader
                if (leaderData.directLeader != null) {
                  approverId = leaderData.directLeader!.id;
                  approverName = leaderData.directLeader!.fullName;
                  approverLevel = 'Direct Leader';
                  approverWorkTitle = leaderData.directLeader!.workTitle;
                }
                break;
              case 2: // Indirect Leader
                if (leaderData.indirectLeader != null) {
                  approverId = leaderData.indirectLeader!.id;
                  approverName = leaderData.indirectLeader!.fullName;
                  approverLevel = 'Indirect Leader';
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
        } catch (e) {
          // Fallback to current user data
        }

        // Smart approval logic - Modified to ensure all orders require Direct Leader approval
        String? approvedAt;
        String? approvedValue;

        if (i == 0) {
          // User level - always auto-approved (user created the order)
          approvedAt = DateTime.now().toIso8601String();
          approvedValue = 'true';
        } else {
          // For all other levels (Direct Leader, Indirect Leader, Controller, Analyst)
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
    } catch (e) {
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
        throw Exception('Token not found');
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
        throw Exception(
            'Failed to create order letter: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating order letter: $e',
      };
    }
  }

  /// Create Order Letter Detail
  Future<Map<String, dynamic>> createOrderLetterDetail(
      Map<String, dynamic> detailData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not found');
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
        throw Exception(
            'Failed to create order letter detail: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating order letter detail: $e',
      };
    }
  }

  /// Create Order Letter Discount
  Future<Map<String, dynamic>> createOrderLetterDiscount(
      Map<String, dynamic> discountData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not found');
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
        throw Exception(
            'Failed to create order letter discount: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating order letter discount: $e',
      };
    }
  }

  /// Batch approve all discounts for a specific user level in an order letter
  Future<Map<String, dynamic>> batchApproveOrderLetterDiscounts({
    required int orderLetterId,
    required int leaderId,
    required int jobLevelId,
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
      } catch (e) {
        // Fallback to current user name
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
      } catch (e) {
        // If location cannot be obtained, continue without it
        // Location will be null
        if (kDebugMode) {
          print('OrderLetterService: Failed to get location for approval: $e');
        }
      }

      // Approve all discounts in batch
      for (final discountId in discountIdsToApprove) {
        try {
          // POST to order_letter_approves endpoint
          final approveUrl =
              ApiConfig.getCreateOrderLetterApproveUrl(token: token);
          final approveData = {
            'order_letter_discount_id': discountId,
            'leader': leaderId,
            'job_level_id': jobLevelId,
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
          final updateData = {
            'approved': true,
            'approved_at': currentTime,
            'approver_level': _getApproverLevelName(jobLevelId),
            'approver_name': approverName,
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
        } catch (e) {
          // Continue with other discounts even if one fails
        }
      }

      // Check if this is the final approval (highest level)
      final isFinalApproval = await _isFinalApproval(orderLetterId, jobLevelId);

      Map<String, dynamic>? orderLetterUpdateResult;
      if (isFinalApproval) {
        orderLetterUpdateResult =
            await _updateOrderLetterStatus(orderLetterId, 'Approved');
      }

      // Send notification after approval
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
      } catch (e) {
        // Don't fail approval if notification fails
        if (kDebugMode) {
          print('Error sending approval notification: $e');
        }
      }

      return {
        'success': true,
        'message': 'Batch approval completed successfully',
        'approved_count': discountIdsToApprove.length,
        'discount_ids': discountIdsToApprove,
        'approve_results': approveResults,
        'update_results': updateResults,
        'order_letter_update_result': orderLetterUpdateResult,
        'is_final_approval': isFinalApproval,
      };
    } catch (e) {
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
      } catch (e) {
        // Fallback to current user name
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
      } catch (e) {
        if (kDebugMode) {
          print('OrderLetterService: Failed to get location for approval: $e');
        }
      }

      // POST to order_letter_approves endpoint
      final approveUrl = ApiConfig.getCreateOrderLetterApproveUrl(token: token);
      final approveData = {
        'order_letter_discount_id': discountId,
        'leader': leaderId,
        'job_level_id': jobLevelId,
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
        'approver_level': _getApproverLevelName(jobLevelId),
        'approver_name': approverName,
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

      // Check if this is the final approval (highest level)
      final isFinalApproval = await _isFinalApproval(orderLetterId, jobLevelId);

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
      } catch (e) {
        // Don't fail approval if notification fails
        if (kDebugMode) {
          print('Error sending approval notification: $e');
        }
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
    } catch (e) {
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
    } catch (e) {
      return null;
    }
  }

  /// Get Order Letters
  /// Automatically determines the correct API endpoint based on user role
  Future<List<Map<String, dynamic>>> getOrderLetters({String? creator}) async {
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
              token: token, userId: currentUserId);
          break;
        case 'analyst':
          url = ApiConfig.getOrderLettersByAnalystUrl(
              token: token, userId: currentUserId);
          break;
        case 'indirect_leader':
          url = ApiConfig.getOrderLettersByIndirectLeaderUrl(
              token: token, userId: currentUserId);
          break;
        case 'direct_leader':
          url = ApiConfig.getOrderLettersByDirectLeaderUrl(
              token: token, userId: currentUserId);
          break;
        case 'staff':
        default:
          url = ApiConfig.getOrderLettersUrl(
              token: token, userId: currentUserId, creator: creator);
          break;
      }

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is List) {
          final result = List<Map<String, dynamic>>.from(data);
          return result;
        } else if (data is Map && data['result'] != null) {
          // Handle different result formats
          if (data['result'] is List) {
            final result = List<Map<String, dynamic>>.from(data['result']);
            return result;
          } else if (data['result'] is Map) {
            // Result is a single order letter object (wrap in List)
            final result = data['result'] as Map<String, dynamic>;
            // Check if it has order_letter key (new nested format)
            if (result.containsKey('order_letter')) {
              // Return as list with single item containing the full structure
              return [result];
            } else {
              // Direct order letter object, wrap in List
              return [result];
            }
          }
        }
        return [];
      } else {
        throw Exception(
            'Failed to fetch order letters: ${response.statusCode}');
      }
    } catch (e) {
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
        throw Exception('Token not found');
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
    } catch (e) {
      // Fallback to original method
      return await getOrderLetters(creator: creator);
    }
  }

  /// Get Order Letter Details
  Future<List<Map<String, dynamic>>> getOrderLetterDetails(
      {int? orderLetterId}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final url = ApiConfig.getOrderLetterDetailsUrl(
          token: token, orderLetterId: orderLetterId);

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is List) {
          final result = List<Map<String, dynamic>>.from(data);
          return result;
        } else if (data is Map && data['result'] is List) {
          final result = List<Map<String, dynamic>>.from(data['result']);
          return result;
        }
        return [];
      } else {
        throw Exception(
            'Failed to fetch order letter details: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Get Order Letter Discounts
  Future<List<Map<String, dynamic>>> getOrderLetterDiscounts(
      {int? orderLetterId}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final url = ApiConfig.getOrderLetterDiscountsUrl(
          token: token, orderLetterId: orderLetterId);

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;

        List<Map<String, dynamic>> allDiscounts = [];

        if (data is List) {
          allDiscounts = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['result'] is List) {
          allDiscounts = List<Map<String, dynamic>>.from(data['result']);
        } else {
          return [];
        }

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
        throw Exception(
            'Failed to fetch order letter discounts: ${response.statusCode}');
      }
    } catch (e) {
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
        throw Exception('Token not found');
      }

      final url = ApiConfig.getOrderLetterApprovesUrl(
        token: token,
        orderLetterId: orderLetterId,
        approverId: approverId,
      );
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['result'] is List) {
          return List<Map<String, dynamic>>.from(data['result']);
        }
        return [];
      } else {
        throw Exception(
            'Failed to fetch order letter approves: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Create Order Letter Approve
  Future<Map<String, dynamic>> createOrderLetterApprove(
      Map<String, dynamic> approveData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not found');
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
        throw Exception(
            'Failed to create order letter approve: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating order letter approve: $e',
      };
    }
  }

  /// Determine final order status after discount creation
  Future<String> _determineFinalOrderStatus(
      int? orderLetterId, dynamic discountsData) async {
    try {
      if (orderLetterId == null) return 'Pending';

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
    } catch (e) {
      // Default to Pending if there's any error
      return 'Pending';
    }
  }

  /// Process structured discount data (per item)
  Future<void> _processStructuredDiscounts(
    List<Map<String, dynamic>> itemDiscounts,
    List<Map<String, dynamic>> detailResults,
    List<Map<String, dynamic>> discountResults,
    List<int?>? leaderIds,
    int orderLetterId,
  ) async {
    final Set<String> createdDiscounts = {};

    String normalize(String value) => value.trim().toLowerCase();

    final Map<String, List<int>> availableDetailIds = {};

    for (final detailResult in detailResults) {
      if (detailResult['success'] && detailResult['data'] != null) {
        final rawData = detailResult['data'];
        final detailData = rawData['location'] ?? rawData;

        final detailType =
            (detailData['item_type'] ?? '').toString().toLowerCase();
        if (detailType != 'mattress' && detailType != 'kasur') {
          continue;
        }

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
    }

    for (final itemDiscount in itemDiscounts) {
      final kasurNameRaw = (itemDiscount['kasurName'] ?? '').toString();
      final productSizeRaw = (itemDiscount['productSize'] ?? '').toString();

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

      if (kasurOrderLetterDetailId == null) {
        continue;
      }

      if (primaryKey != secondaryKey) {
        availableDetailIds[primaryKey]?.remove(kasurOrderLetterDetailId);
        availableDetailIds[secondaryKey]?.remove(kasurOrderLetterDetailId);
      } else {
        availableDetailIds[primaryKey]?.remove(kasurOrderLetterDetailId);
      }

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
        );

        createdDiscounts.add(discountKey);
      }
    }
  }

  /// Process legacy discount data (all to first kasur)
  Future<void> _processLegacyDiscounts(
    List<double> discounts,
    List<Map<String, dynamic>> detailResults,
    List<Map<String, dynamic>> discountResults,
    List<int?>? leaderIds,
    int orderLetterId,
  ) async {
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
      );
    }
  }

  /// Create default discount entries when no discounts are provided
  /// Creates entries with 0 discount up to Direct Leader level for all items
  Future<void> _createDefaultDiscountEntries(
    List<Map<String, dynamic>> detailResults,
    List<Map<String, dynamic>> discountResults,
    List<int?>? leaderIds,
    int orderLetterId,
  ) async {
    try {
      // Process each detail (item) in the order
      for (int idx = 0; idx < detailResults.length; idx++) {
        final detailResult = detailResults[idx];

        if (detailResult['success'] && detailResult['data'] != null) {
          final rawData = detailResult['data'];
          final detailData = rawData['location'] ?? rawData;

          // Only create for kasur/mattress items
          if (detailData['item_type'] != 'Mattress' &&
              detailData['item_type'] != 'kasur') {
            continue;
          }

          final kasurOrderLetterDetailId = detailData['id'] ??
              detailData['order_letter_detail_id'] ??
              detailData['detail_id'];

          if (kasurOrderLetterDetailId == null) {
            continue;
          }

          final kasurName = detailData['desc_1'] ?? 'Unknown';

          // Create discount entries up to Direct Leader (level 2)
          // Level 0: User (auto-approved)
          // Level 1: Direct Leader (pending)
          for (int i = 0; i < 2; i++) {
            await _createSingleDiscount(
              orderLetterId: orderLetterId,
              kasurOrderLetterDetailId: kasurOrderLetterDetailId,
              discount: 0.0,
              discountIndex: i,
              leaderIds: leaderIds,
              discountResults: discountResults,
              kasurName: kasurName,
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'OrderLetterService: Error creating default discount entries: $e');
      }
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
  }) async {
    // Get leader information
    final leaderId = (leaderIds != null && discountIndex < leaderIds.length)
        ? leaderIds[discountIndex]
        : null;

    int? approverId;
    String approverName = '';
    String approverLevel = '';
    String approverWorkTitle = '';
    bool?
        approvedValue; // Should be nullable - null for pending, true for approved, false for rejected
    String? approvedAt;

    // Always try to get leader data, regardless of leaderId
    try {
      final leaderService = locator<LeaderService>();
      final leaderData = await leaderService.getLeaderByUser();

      if (leaderData != null) {
        final approvalLevel =
            _mapDiscountIndexToApprovalLevel(discountIndex + 1);

        // Use leaderId if available, otherwise get from leaderData based on level
        approverId = leaderId ??
            leaderService.getLeaderIdByDiscountLevel(leaderData, approvalLevel);
        approverName = leaderService.getLeaderNameByDiscountLevel(
                leaderData, approvalLevel) ??
            '';
        approverLevel = _getApproverLevelName(approvalLevel);
        approverWorkTitle = leaderService.getLeaderWorkTitleByDiscountLevel(
                leaderData, approvalLevel) ??
            '';

        // Level 1 discounts should be auto-approved (user created the order)
        if (discountIndex == 0) {
          approvedValue = true; // Auto-approve level 1 (User level)
          approvedAt = DateTime.now().toIso8601String();
        } else {
          // For all other levels (Direct Leader, Indirect Leader, Analyst, Controller)
          // Set approved and approved_at to null - they need manual approval
          approvedValue = null;
          approvedAt = null;
        }
      } else {
        return; // Skip creating discount if no leader data
      }
    } catch (e) {
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
    } catch (e) {
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

  String _getApproverLevelName(int level) {
    switch (level) {
      case 1:
        return 'User';
      case 2:
        return 'Direct Leader';
      case 3:
        return 'Indirect Leader';
      case 4:
        return 'Analyst';
      case 5:
        return 'Controller';
      default:
        return 'Unknown';
    }
  }
}
