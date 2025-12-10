import 'package:flutter/foundation.dart';

import '../config/dependency_injection.dart';
import 'api_client.dart';
import 'lookup_item_service.dart';
import '../features/cart/domain/entities/cart_entity.dart';
import '../features/cart/domain/usecases/apply_discounts_usecase.dart';
import '../features/product/presentation/bloc/product_bloc.dart';
import '../features/approval/data/repositories/approval_repository.dart';
import '../services/auth_service.dart';
import '../services/order_letter_service.dart';
import '../services/attendance_service.dart';
import '../services/notification_service.dart';

class CheckoutService {
  late final OrderLetterService _orderLetterService;
  late final AttendanceService _attendanceService;

  CheckoutService() {
    // Initialize services without circular dependency
    _orderLetterService = locator<OrderLetterService>();
    _attendanceService = locator<AttendanceService>();
  }

  /// Check if item value should be uploaded to server
  /// Returns false for empty, invalid, or "tanpa" items
  bool _shouldUploadItem(String value) {
    if (value.isEmpty) return false;
    final trimmed = value.trim();
    if (trimmed == '-') return false;
    if (trimmed == '0') return false;
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('tanpa')) return false;
    if (lower == 'tidak ada kasur') return false;
    if (lower == 'tidak ada divan') return false;
    if (lower == 'tidak ada headboard') return false;
    if (lower == 'tidak ada sorong') return false;
    return true;
  }

  /// Check if bonus should be uploaded to server
  bool _shouldUploadBonus(String name, int quantity) {
    if (name.isEmpty) return false;
    final trimmed = name.trim();
    if (trimmed == '0') return false;
    if (trimmed == '-') return false;
    if (quantity <= 0) return false;
    return true;
  }

  // Resolve item number and item description using lookup service
  Future<Map<String, String?>> _resolveItemInfoFor(
      CartEntity item, String itemType) async {
    if (kDebugMode) {
      print(
          '[CheckoutService] _resolveItemInfoFor type=$itemType, brand=${item.product.brand}');
    }

    // Check for prefilled item number first
    String? prefilled;
    switch (itemType) {
      case 'kasur':
        prefilled = item.product.itemNumberKasur ?? item.product.itemNumber;
        break;
      case 'divan':
        prefilled = item.product.itemNumberDivan;
        break;
      case 'headboard':
        prefilled = item.product.itemNumberHeadboard;
        break;
      case 'sorong':
        prefilled = item.product.itemNumberSorong;
        break;
    }

    // Helper to check invalid item number
    bool isInvalid(String? s) =>
        s == null ||
        s.isEmpty ||
        s == '0' ||
        s == 'null' ||
        s.toLowerCase() == 'undefined';

    try {
      final lookup = LookupItemService(client: locator<ApiClient>());
      final list = await lookup.fetchLookupItems(
        brand: item.product.brand,
        kasur: item.product.kasur,
        divan: item.product.divan.isNotEmpty ? item.product.divan : null,
        headboard:
            item.product.headboard.isNotEmpty ? item.product.headboard : null,
        sorong: item.product.sorong.isNotEmpty ? item.product.sorong : null,
        ukuran: item.product.ukuran,
        contextItemType: itemType,
      );

      if (list.isNotEmpty) {
        final lookupItem = list.first;
        return {
          'item_number': !isInvalid(prefilled)
              ? prefilled
              : (!isInvalid(lookupItem.itemNumber)
                  ? lookupItem.itemNumber
                  : item.product.id.toString()),
          'item_description': lookupItem.itemDesc,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('[CheckoutService] Error fetching lookup for $itemType: $e');
      }
    }

    return {
      'item_number':
          !isInvalid(prefilled) ? prefilled : item.product.id.toString(),
      'item_description': null,
    };
  }

  // Resolve per-unit item info (number + description) if available
  Future<List<Map<String, String?>>> _resolveItemInfoPerUnit(
      CartEntity item, String itemType) async {
    final qty = item.quantity;
    if (kDebugMode) {
      print(
          '[CheckoutService] _resolveItemInfoPerUnit type=$itemType, qty=$qty');
    }

    // If per-unit selections exist, use them with item_description from selection
    final perUnit = item.selectedItemNumbersPerUnit?[itemType];
    if (perUnit != null && perUnit.isNotEmpty) {
      final List<Map<String, String?>> results = [];
      for (int i = 0; i < qty; i++) {
        final sel = i < perUnit.length ? perUnit[i] : null;
        final numSel = sel != null ? (sel['item_number'] ?? '') : '';
        final descSel =
            sel != null ? sel['item_description']?.toString() : null;
        if (numSel.isNotEmpty) {
          results.add({
            'item_number': numSel,
            'item_description': descSel,
          });
        } else {
          // fallback per-unit to lookup resolution
          results.add(await _resolveItemInfoFor(item, itemType));
        }
      }
      if (kDebugMode) {
        print('[CheckoutService] per-unit info for $itemType => $results');
      }
      return results;
    }

    // No per-unit selections; get single info from lookup and reuse
    final info = await _resolveItemInfoFor(item, itemType);
    final all = List<Map<String, String?>>.filled(qty, info);
    if (kDebugMode) {
      print(
          '[CheckoutService] single info for $itemType => $info (reused x$qty)');
    }
    return all;
  }

  /// Create Order Letter from Cart Items
  Future<Map<String, dynamic>> createOrderLetterFromCart({
    required List<CartEntity> cartItems,
    required String customerName,
    required String customerPhone,
    required String email,
    required String customerAddress,
    required String shipToName,
    required String addressShipTo,
    required String requestDate,
    required String note,
    String? spgCode,
    bool isTakeAway = false,
    double? postage,
  }) async {
    try {
      // Get current user ID for creator field
      final userId = await AuthService.getCurrentUserId();
      final creatorId = userId?.toString() ?? '0';

      final now = DateTime.now();
      final orderDateStr = now.toIso8601String().split('T')[0];
      final requestDateStr =
          requestDate.isNotEmpty ? requestDate.split('T')[0] : orderDateStr;

      // Calculate totals
      double totalExtendedAmount = 0;
      int totalHargaAwal = 0;
      final List<Map<String, dynamic>> itemDiscounts =
          []; // Store discounts with item info
      double totalDiscountPercentage = 0;

      final applyDiscountsUsecase = const ApplyDiscountsUsecase();

      for (final item in cartItems) {
        totalExtendedAmount += item.netPrice * item.quantity;
        totalHargaAwal += (item.product.pricelist * item.quantity).toInt();

        // Collect discounts from each item with item information
        if (item.discountPercentages.isNotEmpty) {
          final validDiscounts =
              item.discountPercentages.where((d) => d > 0.0).toList();
          if (validDiscounts.isNotEmpty) {
            // Get primary item name based on priority: Kasur → Divan → Headboard → Sorong
            String primaryItemName = '';
            if (_shouldUploadItem(item.product.kasur) &&
                item.product.plKasur > 0) {
              primaryItemName = item.product.kasur;
            } else if (_shouldUploadItem(item.product.divan) &&
                item.product.plDivan > 0) {
              primaryItemName = item.product.divan;
            } else if (_shouldUploadItem(item.product.headboard) &&
                item.product.plHeadboard > 0) {
              primaryItemName = item.product.headboard;
            } else if (_shouldUploadItem(item.product.sorong) &&
                item.product.plSorong > 0) {
              primaryItemName = item.product.sorong;
            }

            // Only add discount if there's a valid primary item
            if (primaryItemName.isNotEmpty) {
              itemDiscounts.add({
                'productId': item.product.id,
                'kasurName':
                    primaryItemName, // Now uses the actual primary item
                'productSize': item.product.ukuran,
                'discounts': validDiscounts,
              });
              totalDiscountPercentage += item.discountPercentages.fold(
                0.0,
                (sum, d) => sum + d,
              );
            }
          }
        }
      }

      // Flatten all discounts for status determination
      final List<double> allDiscounts = [];
      for (final itemDiscount in itemDiscounts) {
        allDiscounts.addAll(itemDiscount['discounts']);
      }

      // Determine smart status based on discount approval requirements
      String orderStatus = _determineOrderStatus(allDiscounts);

      // Get work_place_id from attendance API
      final workPlaceId = await _attendanceService.getWorkPlaceId();

      // Parse postage value (ensure it's a number, not null)
      final double postageValue = postage ?? 0.0;

      // Add postage to total extended amount
      if (postageValue > 0) {
        totalExtendedAmount += postageValue;
      }

      // Prepare Order Letter Data
      final orderLetterData = <String, dynamic>{
        'order_date': orderDateStr,
        'request_date': requestDateStr,
        'creator': creatorId,
        'customer_name': customerName,
        'phone': customerPhone,
        'email': email,
        'address': customerAddress,
        'ship_to_name': shipToName,
        'address_ship_to': addressShipTo,
        'extended_amount': totalExtendedAmount,
        'harga_awal': totalHargaAwal,
        'discount': totalDiscountPercentage,
        'note': note,
        'status': orderStatus,
        'sales_code': spgCode ?? '',
        'work_place_id': workPlaceId,
        'take_away': isTakeAway,
        'postage': postageValue,
      };

      // Prepare Details Data
      final List<Map<String, dynamic>> detailsData = [];

      for (final item in cartItems) {
        // Add main product (kasur) - only if valid
        if (_shouldUploadItem(item.product.kasur) && item.product.plKasur > 0) {
          // Convert boolean to string format that backend expects
          String? takeAwayString;
          if (isTakeAway) {
            takeAwayString = 'TAKE AWAY';
          } else {
            takeAwayString = null;
          }

          final itemInfoList = await _resolveItemInfoPerUnit(item, 'kasur');
          // If numbers vary per unit, split lines per unit with qty 1
          final nums = itemInfoList.map((e) => e['item_number'] ?? '').toList();
          final bool hasVariety = nums.toSet().length > 1;
          final double kasurUnitPrice = item.product.plKasur;
          final double kasurCustomerPrice = item.product.eupKasur;
          final double kasurNetPrice = applyDiscountsUsecase.applySequentially(
              kasurCustomerPrice, item.discountPercentages);
          if (hasVariety) {
            for (final info in itemInfoList) {
              detailsData.add({
                'item_number': info['item_number'],
                'item_description': info['item_description'],
                'desc_1': item.product.kasur,
                'desc_2': item.product.ukuran,
                'brand': item.product.brand,
                'unit_price': kasurUnitPrice,
                'customer_price': kasurCustomerPrice,
                'net_price': kasurNetPrice,
                'qty': 1,
                'item_type': 'kasur',
                'take_away': takeAwayString,
              });
            }
          } else {
            detailsData.add({
              'item_number': itemInfoList.first['item_number'],
              'item_description': itemInfoList.first['item_description'],
              'desc_1': item.product.kasur,
              'desc_2': item.product.ukuran,
              'brand': item.product.brand,
              'unit_price': kasurUnitPrice,
              'customer_price': kasurCustomerPrice,
              'net_price': kasurNetPrice,
              'qty': item.quantity,
              'item_type': 'kasur',
              'take_away': takeAwayString,
            });
          }
        }

        // Add divan
        if (_shouldUploadItem(item.product.divan) && item.product.plDivan > 0) {
          // Convert boolean to string format that backend expects
          String? takeAwayString;
          if (isTakeAway) {
            takeAwayString = 'TAKE AWAY';
          } else {
            takeAwayString = null;
          }

          final itemInfoList = await _resolveItemInfoPerUnit(item, 'divan');
          final nums = itemInfoList.map((e) => e['item_number'] ?? '').toList();
          final bool hasVariety = nums.toSet().length > 1;
          final double divanUnitPrice = item.product.plDivan;
          final double divanCustomerPrice = item.product.eupDivan;
          final double divanNetPrice = applyDiscountsUsecase.applySequentially(
              divanCustomerPrice, item.discountPercentages);
          if (hasVariety) {
            for (final info in itemInfoList) {
              detailsData.add({
                'item_number': info['item_number'],
                'item_description': info['item_description'],
                'desc_1': item.product.divan,
                'desc_2': item.product.ukuran,
                'brand': item.product.brand,
                'unit_price': divanUnitPrice,
                'customer_price': divanCustomerPrice,
                'net_price': divanNetPrice,
                'qty': 1,
                'item_type': 'divan',
                'take_away': takeAwayString,
              });
            }
          } else {
            detailsData.add({
              'item_number': itemInfoList.first['item_number'],
              'item_description': itemInfoList.first['item_description'],
              'desc_1': item.product.divan,
              'desc_2': item.product.ukuran,
              'brand': item.product.brand,
              'unit_price': divanUnitPrice,
              'customer_price': divanCustomerPrice,
              'net_price': divanNetPrice,
              'qty': item.quantity,
              'item_type': 'divan',
              'take_away': takeAwayString,
            });
          }
        }

        // Add headboard
        if (_shouldUploadItem(item.product.headboard) &&
            item.product.plHeadboard > 0) {
          // Convert boolean to string format that backend expects
          String? takeAwayString;
          if (isTakeAway) {
            takeAwayString = 'TAKE AWAY';
          } else {
            takeAwayString = null;
          }

          final itemInfoList = await _resolveItemInfoPerUnit(item, 'headboard');
          final nums = itemInfoList.map((e) => e['item_number'] ?? '').toList();
          final bool hasVariety = nums.toSet().length > 1;
          final double headboardUnitPrice = item.product.plHeadboard;
          final double headboardCustomerPrice = item.product.eupHeadboard;
          final double headboardNetPrice =
              applyDiscountsUsecase.applySequentially(
                  headboardCustomerPrice, item.discountPercentages);
          if (hasVariety) {
            for (final info in itemInfoList) {
              detailsData.add({
                'item_number': info['item_number'],
                'item_description': info['item_description'],
                'desc_1': item.product.headboard,
                'desc_2': item.product.ukuran,
                'brand': item.product.brand,
                'unit_price': headboardUnitPrice,
                'customer_price': headboardCustomerPrice,
                'net_price': headboardNetPrice,
                'qty': 1,
                'item_type': 'headboard',
                'take_away': takeAwayString,
              });
            }
          } else {
            detailsData.add({
              'item_number': itemInfoList.first['item_number'],
              'item_description': itemInfoList.first['item_description'],
              'desc_1': item.product.headboard,
              'desc_2': item.product.ukuran,
              'brand': item.product.brand,
              'unit_price': headboardUnitPrice,
              'customer_price': headboardCustomerPrice,
              'net_price': headboardNetPrice,
              'qty': item.quantity,
              'item_type': 'headboard',
              'take_away': takeAwayString,
            });
          }
        }

        // Add sorong
        if (_shouldUploadItem(item.product.sorong) &&
            item.product.plSorong > 0) {
          // Convert boolean to string format that backend expects
          String? takeAwayString;
          if (isTakeAway) {
            takeAwayString = 'TAKE AWAY';
          } else {
            takeAwayString = null;
          }

          final sorongInfo = await _resolveItemInfoFor(item, 'sorong');
          detailsData.add({
            'item_number': sorongInfo['item_number'],
            'item_description': sorongInfo['item_description'],
            'desc_1': item.product.sorong,
            'desc_2': item.product.ukuran,
            'brand': item.product.brand,
            'unit_price': item.product.plSorong,
            'customer_price': item.product.eupSorong,
            'net_price': applyDiscountsUsecase.applySequentially(
                item.product.eupSorong, item.discountPercentages),
            'qty': item.quantity,
            'item_type': 'sorong',
            'take_away': takeAwayString,
          });
        }

        // Add bonuses
        for (int i = 0; i < item.product.bonus.length; i++) {
          final bonus = item.product.bonus[i];
          if (_shouldUploadBonus(bonus.name, bonus.quantity)) {
            String? bonusItemNumber;
            switch (i) {
              case 0:
                bonusItemNumber = item.product.itemNumberBonus1;
                break;
              case 1:
                bonusItemNumber = item.product.itemNumberBonus2;
                break;
              case 2:
                bonusItemNumber = item.product.itemNumberBonus3;
                break;
              case 3:
                bonusItemNumber = item.product.itemNumberBonus4;
                break;
              case 4:
                bonusItemNumber = item.product.itemNumberBonus5;
                break;
            }

            // Determine take away status for bonus
            bool? bonusTakeAway;
            if (isTakeAway) {
              // If full take away, all bonus items are take away
              bonusTakeAway = true;
            } else {
              // Check individual bonus take away status from cart item
              bonusTakeAway = item.bonusTakeAway?[bonus.name];
            }

            // Convert boolean to string format that backend expects
            String? takeAwayString;
            if (bonusTakeAway == true) {
              takeAwayString = 'TAKE AWAY';
            } else if (bonusTakeAway == false) {
              takeAwayString = null;
            } else {
              takeAwayString = null;
            }

            bool isInvalidItemNum(String? v) {
              if (v == null) return true;
              final s = v.trim();
              return s.isEmpty || s == '0' || s == '0.0';
            }

            // Resolve missing/invalid bonus item number via lookup by type (bonus name)
            String resolvedBonusNumber = bonusItemNumber ?? '';
            String? resolvedBonusDescription;
            if (isInvalidItemNum(resolvedBonusNumber)) {
              try {
                final lookup = LookupItemService(client: locator<ApiClient>());
                final list = await lookup.fetchLookupItems(
                  brand: item.product.brand,
                  kasur: bonus.name, // treat bonus name as 'tipe'
                  ukuran: item.product.ukuran,
                );
                // Prefer entries that clearly match bonus by description and brand
                String norm(String s) => s.toLowerCase().trim();
                final normBonus = norm(bonus.name);
                final normBrand = norm(item.product.brand.split(' - ').first);
                bool descMatches(String? d) {
                  final desc = norm(d ?? '');
                  // All words in bonus name should appear in desc
                  final tokens = normBonus.split(RegExp(r"\s+"));
                  return tokens.every((t) => t.isEmpty || desc.contains(t));
                }

                final filtered = list.where((e) {
                  final brandOk =
                      e.brand != null && norm(e.brand!) == normBrand;
                  final descOk = descMatches(e.itemDesc);
                  return descOk && brandOk && !isInvalidItemNum(e.itemNumber);
                }).toList();
                if (filtered.isNotEmpty) {
                  resolvedBonusNumber = filtered.first.itemNumber;
                  resolvedBonusDescription = filtered.first.itemDesc;
                } else if (list.isNotEmpty &&
                    !isInvalidItemNum(list.first.itemNumber)) {
                  // fallback to first valid from API
                  resolvedBonusNumber = list.first.itemNumber;
                  resolvedBonusDescription = list.first.itemDesc;
                } else {
                  resolvedBonusNumber = item.product.id.toString();
                }
              } catch (_) {
                resolvedBonusNumber = item.product.id.toString();
              }
            }

            detailsData.add({
              'item_number': resolvedBonusNumber,
              'item_description': resolvedBonusDescription,
              'desc_1': bonus.name,
              'desc_2': 'Bonus',
              'brand': item.product.brand,
              'unit_price': 0,
              'net_price': 0,
              'qty': bonus.quantity,
              'item_type': 'Bonus',
              'take_away': takeAwayString,
            });
          }
        }
      }

      // Get leader IDs from product state with item mapping
      final Map<String, List<int?>> itemLeaderIds = {};
      for (final item in cartItems) {
        final state = locator<ProductBloc>().state;
        final productLeaderIds = state.productLeaderIds[item.product.id] ?? [];
        if (productLeaderIds.isNotEmpty) {
          // Get primary item name based on priority
          String primaryName = '';
          if (_shouldUploadItem(item.product.kasur) &&
              item.product.plKasur > 0) {
            primaryName = item.product.kasur;
          } else if (_shouldUploadItem(item.product.divan) &&
              item.product.plDivan > 0) {
            primaryName = item.product.divan;
          } else if (_shouldUploadItem(item.product.headboard) &&
              item.product.plHeadboard > 0) {
            primaryName = item.product.headboard;
          } else if (_shouldUploadItem(item.product.sorong) &&
              item.product.plSorong > 0) {
            primaryName = item.product.sorong;
          }
          if (primaryName.isNotEmpty) {
            itemLeaderIds[primaryName] = productLeaderIds;
          }
        }
      }

      // For backward compatibility, flatten all leader IDs
      final List<int?> leaderIds = [];
      for (final item in cartItems) {
        final state = locator<ProductBloc>().state;
        final productLeaderIds = state.productLeaderIds[item.product.id] ?? [];
        leaderIds.addAll(productLeaderIds);
      }

      // Create Order Letter with Details and Discounts
      final result = await _orderLetterService.createOrderLetterWithDetails(
        orderLetterData: orderLetterData,
        detailsData: detailsData,
        discountsData: itemDiscounts, // Pass structured discount data
        leaderIds: leaderIds,
      );

      // Send notification if order letter created successfully
      if (result['success'] == true) {
        // Invalidate approval cache so new order appears immediately
        try {
          final approvalRepository = locator<ApprovalRepository>();
          approvalRepository.clearCache();
        } catch (e) {
          // Don't fail if cache clear fails
        }

        // Send notification to leaders about new order letter
        try {
          final notificationService = NotificationService();
          final orderLetterId = result['orderLetterId']?.toString() ??
              result['id']?.toString() ??
              'Unknown';
          final noSp = result['noSp'] ?? result['no_sp'] ?? 'Unknown';
          final customerName = orderLetterData['customer_name'] as String?;
          final totalAmount = orderLetterData['total'] != null
              ? double.tryParse(orderLetterData['total'].toString())
              : null;

          // Get leader IDs from the result or use the ones we passed
          List<int>? leaderIdsForNotification;
          if (leaderIds.isNotEmpty) {
            leaderIdsForNotification = leaderIds.whereType<int>().toList();
          }

          await notificationService.notifyLeadersOnOrderLetterCreated(
            orderId: orderLetterId,
            noSp: noSp,
            customerName: customerName,
            totalAmount: totalAmount,
            leaderIds: leaderIdsForNotification,
          );
        } catch (e) {
          // Don't fail checkout if notification fails
          if (kDebugMode) {
            print('Error sending notification: $e');
          }
        }
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Error creating order letter: $e'};
    }
  }

  /// Determine order status based on discount approval requirements
  String _determineOrderStatus(List<double> discounts) {
    // Filter out zero discounts (no approval needed)
    final significantDiscounts = discounts.where((d) => d > 0.0).toList();

    if (significantDiscounts.isEmpty) {
      return 'Pending';
    }

    if (significantDiscounts.every((d) => d <= 5.0)) {
      return 'Pending';
    }

    return 'Pending';
  }
}
