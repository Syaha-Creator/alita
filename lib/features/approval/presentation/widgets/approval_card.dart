import 'package:flutter/material.dart';
import '../../../../config/app_constant.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/entities/approval_entity.dart';
import '../../data/models/approval_model.dart';
import '../../../../config/dependency_injection.dart';
import '../../../../services/leader_service.dart';
import '../../../../services/auth_service.dart';
import '../../data/cache/approval_cache.dart';
import '../../../order_letter_document/presentation/pages/order_letter_document_page.dart';
import '../../data/repositories/approval_repository.dart';
import '../bloc/approval_bloc.dart';
import '../bloc/approval_event.dart';
import 'approval_card/approval_card_widgets.dart';
import '../../../../core/utils/format_helper.dart';

class ApprovalCard extends StatefulWidget {
  final ApprovalEntity approval;
  final VoidCallback onTap;
  final VoidCallback? onItemsTap;
  final bool isStaffLevel;
  final LeaderByUserModel? leaderData;

  const ApprovalCard({
    super.key,
    required this.approval,
    required this.onTap,
    this.onItemsTap,
    this.isStaffLevel = false,
    this.leaderData,
  });

  @override
  State<ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<ApprovalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  String? _overriddenStatus;

  List<Map<String, dynamic>>? _cachedDiscountData;
  bool _isLoadingTimeline = false;
  String? _timelineError;
  String? _creatorName;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _loadTimelineData();
    _fetchCreatorName();
  }

  @override
  void didUpdateWidget(ApprovalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.approval.id != widget.approval.id) {
      _loadTimelineData();
      _overriddenStatus = null;
    } else if (oldWidget.approval.status != widget.approval.status) {
      _overriddenStatus = null;
    }
  }

  void _initAnimation() {
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final status = _overriddenStatus ?? widget.approval.status;
    final statusColor = _getStatusColor(status);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _pressController.forward(),
            onTapUp: (_) => _pressController.reverse(),
            onTapCancel: () => _pressController.reverse(),
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.surfaceLight, // 30% - Card/Surface
                borderRadius: BorderRadius.circular(12),
                border: isDark
                    ? Border.all(
                        color: AppColors.borderDark, // 30% - Border
                        width: 1,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isDark ? AppColors.shadowDark : AppColors.shadowLight,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left accent border
                      Container(
                        width: 5,
                        color: statusColor,
                      ),

                      // Main content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row 1: Status + No. SP
                              _buildHeaderRow(status, statusColor, colorScheme),

                              const SizedBox(height: AppPadding.p14),

                              // Row 2: Customer + Total
                              _buildCustomerTotalRow(colorScheme),

                              const SizedBox(height: AppPadding.p12),

                              // Row 3: Items & Discount
                              _buildInfoRow(colorScheme, isDark),

                              const SizedBox(height: AppPadding.p12),

                              // Row 4: Creator | Date
                              _buildMetaRow(colorScheme),

                              // Timeline
                              _buildTimeline(isDark),

                              // Approval Info (staff only)
                              if (widget.isStaffLevel)
                                _buildApprovalInfoSection(colorScheme),

                              // Action button
                              _buildActionButton(colorScheme),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow(
      String status, Color statusColor, ColorScheme colorScheme) {
    final subtleColor = colorScheme.onSurface.withValues(alpha: 0.5);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Badge (left)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getStatusIcon(status), size: 14, color: statusColor),
              const SizedBox(width: AppPadding.p5),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // No. SP (right, label + value)
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'No. SP',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: subtleColor,
              ),
            ),
            const SizedBox(height: AppPadding.p2),
            Text(
              widget.approval.noSp,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerTotalRow(ColorScheme colorScheme) {
    final subtleColor = colorScheme.onSurface.withValues(alpha: 0.5);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer (left)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: subtleColor,
                ),
              ),
              const SizedBox(height: AppPadding.p2),
              Text(
                widget.approval.customerName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(width: AppPadding.p16),

        // Total (right)
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Total',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: subtleColor,
              ),
            ),
            const SizedBox(height: AppPadding.p2),
            Text(
              FormatHelper.formatCurrency(widget.approval.extendedAmount),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(ColorScheme colorScheme, bool isDark) {
    final hasDiscount = widget.approval.discounts.isNotEmpty &&
        widget.approval.discounts.any((d) => d.discount > 0.0);
    final subtleColor = colorScheme.onSurface.withValues(alpha: 0.5);

    return Row(
      children: [
        // Items
        Expanded(
          child: GestureDetector(
            onTap: widget.isStaffLevel ? null : widget.onItemsTap,
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 16, color: AppColors.info),
                const SizedBox(width: AppPadding.p6),
                Text(
                  '${widget.approval.details.length} items',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (widget.onItemsTap != null && !widget.isStaffLevel) ...[
                  const SizedBox(width: AppPadding.p4),
                  Icon(Icons.chevron_right, size: 16, color: subtleColor),
                ],
              ],
            ),
          ),
        ),

        // Discount (if any)
        if (hasDiscount) ...[
          Icon(Icons.local_offer_outlined, size: 16, color: AppColors.error),
          const SizedBox(width: AppPadding.p6),
          Text(
            widget.approval.getDiscountDisplayString(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetaRow(ColorScheme colorScheme) {
    final dateToDisplay =
        widget.approval.createdAt ?? widget.approval.orderDate;
    final subtleColor = colorScheme.onSurface.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          // Creator
          Icon(Icons.person_outline_rounded, size: 14, color: subtleColor),
          const SizedBox(width: AppPadding.p4),
          Expanded(
            child: Text(
              _creatorName ?? widget.approval.creator,
              style: TextStyle(fontSize: 12, color: subtleColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: colorScheme.onSurface.withValues(alpha: 0.15),
          ),

          // Date
          Icon(Icons.schedule_rounded, size: 14, color: subtleColor),
          const SizedBox(width: AppPadding.p4),
          Text(
            _formatDateTime(dateToDisplay),
            style: TextStyle(fontSize: 12, color: subtleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: HorizontalTimeline(
        discountData: _cachedDiscountData,
        isLoading: _isLoadingTimeline,
        error: _timelineError,
        creatorName: _creatorName,
        fallbackCreator: widget.approval.creator,
      ),
    );
  }

  Widget _buildApprovalInfoSection(ColorScheme colorScheme) {
    final status = _overriddenStatus ?? widget.approval.status;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ApprovalInfoSection(
        status: status,
        leaderData: widget.leaderData,
      ),
    );
  }

  Widget _buildActionButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _navigateToDocument,
        icon: const Icon(Icons.description_outlined, size: 18),
        label: const Text(
          'Lihat Dokumen',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToDocument() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderLetterDocumentPage(
            orderLetterId: widget.approval.id,
          ),
        ),
      ).then((result) {
        if (!mounted) return;

        bool shouldRefresh = false;
        String? updatedStatus;

        if (result is Map) {
          shouldRefresh = result['changed'] == true;
          final statusResult = result['status'];
          if (statusResult is String && statusResult.isNotEmpty) {
            updatedStatus = statusResult;
          }
        } else if (result == true) {
          shouldRefresh = true;
        }

        if (!shouldRefresh) return;

        if (updatedStatus != null && updatedStatus != widget.approval.status) {
          setState(() {
            _overriddenStatus = updatedStatus;
          });
        }

        refreshTimelineData();

        context
            .read<ApprovalBloc>()
            .add(UpdateSingleApproval(widget.approval.id));
      });
    } catch (e) {
      if (mounted) {
        CustomToast.showToast(
          'Gagal membuka dokumen: ${e.toString()}',
          ToastType.error,
          duration: 3,
        );
      }
    }
  }

  Future<void> _loadTimelineData({bool forceRefresh = false}) async {
    if (!mounted) return;

    final currentUserId = await AuthService.getCurrentUserId();
    if (currentUserId == null) return;

    if (forceRefresh) {
      ApprovalCache.clearDiscountCache(currentUserId, widget.approval.id);
    } else {
      final cached =
          ApprovalCache.getCachedDiscounts(currentUserId, widget.approval.id);
      if (cached != null) {
        setState(() {
          _cachedDiscountData = cached;
          _isLoadingTimeline = false;
          _timelineError = null;
        });
        return;
      }
    }

    setState(() {
      _isLoadingTimeline = true;
      _timelineError = null;
    });

    try {
      final repository = locator<ApprovalRepository>();
      final result =
          await repository.getDiscountsForTimeline(widget.approval.id);

      if (mounted) {
        setState(() {
          _cachedDiscountData = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _timelineError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTimeline = false;
        });
      }
    }
  }

  Future<void> _fetchCreatorName() async {
    try {
      final creator = widget.approval.creator;
      final creatorUserId = int.tryParse(creator);

      if (creatorUserId != null) {
        final leaderService = locator<LeaderService>();
        final leaderData = await leaderService.getLeaderByUser(
          userId: creator,
        );

        if (mounted &&
            leaderData != null &&
            leaderData.user.fullName.isNotEmpty) {
          setState(() {
            _creatorName = leaderData.user.fullName;
          });
        }
      }
    } catch (e) {
      // Silent error
    }
  }

  Future<void> refreshTimelineData() async {
    await _loadTimelineData(forceRefresh: true);
  }

  String _formatDateTime(String? date) {
    if (date == null) return '-';
    try {
      final dateTime = DateTime.parse(date).toLocal();
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute';
    } catch (e) {
      return '-';
    }
  }
}
