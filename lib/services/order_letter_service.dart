import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../config/dependency_injection.dart';
import 'auth_service.dart';
import 'leader_service.dart';

class OrderLetterService {
  final Dio dio;

  OrderLetterService(this.dio);

  /// Create Order Letter with Details and Discounts
  Future<Map<String, dynamic>> createOrderLetterWithDetails({
    required Map<String, dynamic> orderLetterData,
    required List<Map<String, dynamic>> detailsData,
    required List<double> discountsData,
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
          print('OrderLetterService: Detail created successfully');
        } else {
          print(
              'OrderLetterService: Failed to create detail: ${detailResult['message']}');
        }
      }

      // Step 3: POST Order Letter Discounts with Leader Data
      final List<Map<String, dynamic>> discountResults = [];
      for (int i = 0; i < discountsData.length; i++) {
        final discount = discountsData[i];
        if (discount <= 0) continue; // Skip zero discounts

        // Find the kasur detail ID (first detail with mattress type)
        int? kasurOrderLetterDetailId;
        for (final detailResult in detailResults) {
          if (detailResult['success'] && detailResult['data'] != null) {
            final detailData = detailResult['data'];
            // Check for both 'Mattress' and 'kasur' item types
            if (detailData['item_type'] == 'Mattress' ||
                detailData['item_type'] == 'kasur') {
              // Try to get ID from location object first
              if (detailData['location'] is Map<String, dynamic>) {
                final location = detailData['location'] as Map<String, dynamic>;
                kasurOrderLetterDetailId = location['id'] ??
                    location['order_letter_detail_id'] ??
                    location['detail_id'];
                print(
                    'OrderLetterService: Found kasur detail ID from location: $kasurOrderLetterDetailId');
              } else {
                // Fallback to direct access
                kasurOrderLetterDetailId = detailData['id'] ??
                    detailData['order_letter_detail_id'] ??
                    detailData['detail_id'];
                print(
                    'OrderLetterService: Found kasur detail ID from direct access: $kasurOrderLetterDetailId');
              }
              break; // Found the first kasur detail, no need to continue
            }
          }
        }

        // If no kasur detail found, use the first available detail
        if (kasurOrderLetterDetailId == null) {
          for (final detailResult in detailResults) {
            if (detailResult['success'] && detailResult['data'] != null) {
              final detailData = detailResult['data'];
              if (detailData['location'] is Map<String, dynamic>) {
                final location = detailData['location'] as Map<String, dynamic>;
                kasurOrderLetterDetailId = location['id'] ??
                    location['order_letter_detail_id'] ??
                    location['detail_id'];
                print(
                    'OrderLetterService: Using first available detail ID from location: $kasurOrderLetterDetailId');
                break;
              } else {
                kasurOrderLetterDetailId = detailData['id'] ??
                    detailData['order_letter_detail_id'] ??
                    detailData['detail_id'];
                print(
                    'OrderLetterService: Using first available detail ID from direct access: $kasurOrderLetterDetailId');
                break;
              }
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
              case 3: // Controller
                if (leaderData.controller != null) {
                  approverId = leaderData.controller!.id;
                  approverName = leaderData.controller!.fullName;
                  approverLevel = 'Controller';
                  approverWorkTitle = leaderData.controller!.workTitle;
                }
                break;
              case 4: // Analyst
                if (leaderData.analyst != null) {
                  approverId = leaderData.analyst!.id;
                  approverName = leaderData.analyst!.fullName;
                  approverLevel = 'Analyst';
                  approverWorkTitle = leaderData.analyst!.workTitle;
                }
                break;
            }
          }
        } catch (e) {
          print('OrderLetterService: Error getting leader data: $e');
          // Fallback to current user data
        }

        print(
            'OrderLetterService: Discount $i - Approver: $approverName ($approverId), Level: $approverLevel, Title: $approverWorkTitle');

        // Auto-approve for User level (level 1)
        bool isApproved = false;
        String? approvedAt;

        if (i == 0) {
          // User level
          isApproved = true;
          approvedAt = DateTime.now().toIso8601String();
          print('OrderLetterService: Auto-approving User level discount');
        }

        // For level 2-5, set approved to null (pending), not false (rejected)
        final approvedValue = i == 0 ? 'true' : null;

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

        print('OrderLetterService: Discount $i - Final data being sent:');
        print('  - Level: ${i + 1} ($approverLevel)');
        print('  - Approver: $approverName ($approverId)');
        print('  - Approved: $isApproved');
        print('  - Approved At: $approvedAt');
        print('  - Full data: $discountData');

        final discountResult = await createOrderLetterDiscount(discountData);
        discountResults.add(discountResult);

        if (discountResult['success']) {
          print('OrderLetterService: Discount created successfully');
        } else {
          print(
              'OrderLetterService: Failed to create discount: ${discountResult['message']}');
        }
      }

      // Check if all operations were successful
      final allDetailsSuccess =
          detailResults.every((result) => result['success']);
      final allDiscountsSuccess =
          discountResults.every((result) => result['success']);

      return {
        'success': allDetailsSuccess && allDiscountsSuccess,
        'message': allDetailsSuccess && allDiscountsSuccess
            ? 'Order letter created successfully with all details and discounts'
            : 'Order letter created but some details or discounts failed',
        'orderLetterId': orderLetterId,
        'noSp': noSp,
        'detailResults': detailResults,
        'discountResults': discountResults,
      };
    } catch (e) {
      print('OrderLetterService: Error in createOrderLetterWithDetails: $e');
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
      print(
          'OrderLetterService: Creating order letter with data: $orderLetterData');
      print(
          'OrderLetterService: Shipping fields in request: ship_to_code=${orderLetterData['ship_to_code']}, address_ship_to=${orderLetterData['address_ship_to']}');

      final response = await dio.post(url, data: orderLetterData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('OrderLetterService: Order letter response: ${response.data}');
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
      print('OrderLetterService: Error creating order letter: $e');
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
      print('OrderLetterService: Creating detail with data: $detailData');

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
      print('OrderLetterService: Error creating order letter detail: $e');
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
      print('OrderLetterService: Creating discount with data: $discountData');

      final response = await dio.post(url, data: discountData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print(
            'OrderLetterService: Discount creation response: ${response.data}');
        return {
          'success': true,
          'data': response.data,
          'message': 'Order letter discount created successfully',
        };
      } else {
        print(
            'OrderLetterService: Discount creation failed with status: ${response.statusCode}');
        print('OrderLetterService: Error response: ${response.data}');
        throw Exception(
            'Failed to create order letter discount: ${response.statusCode}');
      }
    } catch (e) {
      print('OrderLetterService: Error creating order letter discount: $e');
      return {
        'success': false,
        'message': 'Error creating order letter discount: $e',
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

      // POST to order_letter_approves endpoint
      final approveUrl = ApiConfig.getCreateOrderLetterApproveUrl(token: token);
      final approveData = {
        'order_letter_discount_id': discountId,
        'leader': leaderId,
        'job_level_id': jobLevelId,
      };

      print('OrderLetterService: Approving discount with URL: $approveUrl');
      print('OrderLetterService: Approve data: $approveData');

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

      print('OrderLetterService: Approve response: ${approveResponse.data}');

      // PUT to order_letter_discounts endpoint
      final updateUrl = ApiConfig.getUpdateOrderLetterDiscountUrl(
        token: token,
        discountId: discountId,
      );
      final updateData = {
        'approved': true,
        'approved_at': currentTime,
      };

      print('OrderLetterService: Updating discount with URL: $updateUrl');
      print('OrderLetterService: Update data: $updateData');

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

      print('OrderLetterService: Update response: ${updateResponse.data}');

      // Check if this is the final approval (highest level)
      final isFinalApproval = await _isFinalApproval(orderLetterId, jobLevelId);

      Map<String, dynamic>? orderLetterUpdateResult;
      if (isFinalApproval) {
        print(
            'OrderLetterService: This is the final approval, updating order letter status');
        orderLetterUpdateResult =
            await _updateOrderLetterStatus(orderLetterId, 'Approved');
      }

      return {
        'approve_result': approveResponse.data,
        'update_result': updateResponse.data,
        'order_letter_update_result': orderLetterUpdateResult,
        'is_final_approval': isFinalApproval,
      };
    } catch (e) {
      print('OrderLetterService: Error approving discount: $e');
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
        print(
            'OrderLetterService: No discounts found for order letter $orderLetterId');
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

      print(
          'OrderLetterService: Highest level: $highestLevel, Current level: $currentJobLevelId');
      return currentJobLevelId == highestLevel;
    } catch (e) {
      print('OrderLetterService: Error checking final approval: $e');
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

      print('OrderLetterService: Updating order letter status with URL: $url');
      print('OrderLetterService: Update data: $updateData');

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

      print(
          'OrderLetterService: Order letter status update response: ${response.data}');
      return response.data;
    } catch (e) {
      print('OrderLetterService: Error updating order letter status: $e');
      return null;
    }
  }

  /// Get Order Letters
  Future<List<Map<String, dynamic>>> getOrderLetters({String? creator}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final url = ApiConfig.getOrderLettersUrl(token: token, creator: creator);
      print('OrderLetterService: Getting order letters with URL: $url');
      print('OrderLetterService: Creator filter: $creator');

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        print('OrderLetterService: Order letters response data: $data');

        if (data is List) {
          final result = List<Map<String, dynamic>>.from(data);
          print(
              'OrderLetterService: Returning ${result.length} order letters from list');
          return result;
        } else if (data is Map && data['result'] is List) {
          final result = List<Map<String, dynamic>>.from(data['result']);
          print(
              'OrderLetterService: Returning ${result.length} order letters from result map');
          return result;
        }
        print(
            'OrderLetterService: No valid order letters data found, returning empty list');
        return [];
      } else {
        throw Exception(
            'Failed to fetch order letters: ${response.statusCode}');
      }
    } catch (e) {
      print('OrderLetterService: Error getting order letters: $e');
      return [];
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

      print('OrderLetterService: Getting details with URL: $url');
      print('OrderLetterService: Order Letter ID filter: $orderLetterId');

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        print('OrderLetterService: Response data: $data');

        if (data is List) {
          final result = List<Map<String, dynamic>>.from(data);
          print(
              'OrderLetterService: Returning ${result.length} details from list');
          return result;
        } else if (data is Map && data['result'] is List) {
          final result = List<Map<String, dynamic>>.from(data['result']);
          print(
              'OrderLetterService: Returning ${result.length} details from result map');
          return result;
        }
        print('OrderLetterService: No valid data found, returning empty list');
        return [];
      } else {
        throw Exception(
            'Failed to fetch order letter details: ${response.statusCode}');
      }
    } catch (e) {
      print('OrderLetterService: Error getting order letter details: $e');
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

      print('OrderLetterService: Getting discounts with URL: $url');
      print('OrderLetterService: Order Letter ID filter: $orderLetterId');

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        print('OrderLetterService: Discounts response data: $data');

        List<Map<String, dynamic>> allDiscounts = [];

        if (data is List) {
          allDiscounts = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['result'] is List) {
          allDiscounts = List<Map<String, dynamic>>.from(data['result']);
        } else {
          print(
              'OrderLetterService: No valid discount data found, returning empty list');
          return [];
        }

        // Filter discounts by order_letter_id if specified
        if (orderLetterId != null) {
          final filteredDiscounts = allDiscounts.where((discount) {
            final discountOrderLetterId = discount['order_letter_id'];
            final matches = discountOrderLetterId == orderLetterId;
            print(
                'OrderLetterService: Checking discount ID ${discount['id']} - order_letter_id: $discountOrderLetterId vs filter: $orderLetterId -> matches: $matches');
            return matches;
          }).toList();

          print(
              'OrderLetterService: Filtered ${filteredDiscounts.length} discounts for order letter ID: $orderLetterId');
          return filteredDiscounts;
        }

        print(
            'OrderLetterService: Returning ${allDiscounts.length} discounts (no filter)');
        return allDiscounts;
      } else {
        throw Exception(
            'Failed to fetch order letter discounts: ${response.statusCode}');
      }
    } catch (e) {
      print('OrderLetterService: Error getting order letter discounts: $e');
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
      print('OrderLetterService: Error getting order letter approves: $e');
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
      print('OrderLetterService: Error creating order letter approve: $e');
      return {
        'success': false,
        'message': 'Error creating order letter approve: $e',
      };
    }
  }
}
