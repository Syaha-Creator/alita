import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/approval_entity.dart';
import '../../data/models/approval_model.dart';
import '../../../../config/dependency_injection.dart';
import '../../../../services/order_letter_service.dart';
import '../../../order_letter_document/presentation/pages/order_letter_document_page.dart';

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
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _bounceController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _bounceAnimation;

  // Add state for timeline data
  List<Map<String, dynamic>>? _cachedDiscountData;
  bool _isLoadingTimeline = false;
  String? _timelineError;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTimelineData();
  }

  @override
  void didUpdateWidget(ApprovalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload timeline data if approval ID changed
    if (oldWidget.approval.id != widget.approval.id) {
      _loadTimelineData();
    }
  }

  void _initializeAnimations() {
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _bounceController.forward();
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _hoverController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _hoverController.reverse();
  }

  void _onTapCancel() {
    _hoverController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([_hoverController, _bounceController]),
      builder: (context, child) {
        return Transform.scale(
          scale: 0.98 + (_bounceAnimation.value * 0.02),
          child: Transform.translate(
            offset: Offset(0, -4 * _hoverAnimation.value),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.05),
                    blurRadius: 10 + (5 * _hoverAnimation.value),
                    offset: Offset(0, 4 + (2 * _hoverAnimation.value)),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  onTapDown: _onTapDown,
                  onTapUp: _onTapUp,
                  onTapCancel: _onTapCancel,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with Status and Amount
                        _buildHeader(theme, colorScheme),

                        const SizedBox(height: 16),

                        // Customer Info
                        _buildCustomerSection(theme, colorScheme),

                        const SizedBox(height: 12),

                        // Order Details
                        _buildOrderDetails(theme, colorScheme),

                        const SizedBox(height: 12),

                        // Footer
                        _buildFooter(theme, colorScheme),

                        // Approval Timeline (Horizontal)
                        _buildHorizontalTimeline(theme, colorScheme),

                        // Approval Info Section (for staff level)
                        if (widget.isStaffLevel)
                          _buildApprovalInfoSection(theme, colorScheme),

                        // Action Buttons
                        _buildActionButtons(theme, colorScheme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(widget.approval.status),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(widget.approval.status),
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                widget.approval.status,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Order ID
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.secondary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_rounded,
                color: colorScheme.secondary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '#${widget.approval.id}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Amount
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Rp ${_formatNumber(widget.approval.extendedAmount.toInt())}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSection(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
                Text(
                  widget.approval.customerName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        // Items Count - Conditional Tappable based on job level
        Expanded(
          child: widget.isStaffLevel || widget.onItemsTap == null
              ? _buildDetailCard(
                  'Items',
                  '${widget.approval.details.length} items',
                  Icons.inventory_2_rounded,
                  AppColors.info,
                  theme,
                )
              : GestureDetector(
                  onTap: widget.onItemsTap,
                  child: _buildTappableDetailCard(
                    'Items',
                    '${widget.approval.details.length} items',
                    Icons.inventory_2_rounded,
                    AppColors.info,
                    theme,
                    colorScheme,
                  ),
                ),
        ),

        const SizedBox(width: 8),

        // Discount (if exists)
        if (widget.approval.discounts.isNotEmpty)
          Expanded(
            child: _buildDetailCard(
              'Discount',
              widget.approval.getDiscountDisplayString(),
              Icons.discount_rounded,
              AppColors.error,
              theme,
            ),
          ),
      ],
    );
  }

  Widget _buildDetailCard(
      String label, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTappableDetailCard(String label, String value, IconData icon,
      Color color, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 9,
                  ),
                ),
              ),
              if (widget.onItemsTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: color,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Creator Info
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created by',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: 9,
                        ),
                      ),
                      Text(
                        widget.approval.creator,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Date Info
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 9,
                    ),
                  ),
                  Text(
                    _formatDate(widget.approval.orderDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalTimeline(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoadingTimeline) {
      return SizedBox(
        height: 45, // Increased height to prevent overflow
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_timelineError != null) {
      return SizedBox(
        height: 45, // Increased height to prevent overflow
        child: Center(
          child: Text(
            'Error loading timeline',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      );
    }

    if (_cachedDiscountData == null || _cachedDiscountData!.isEmpty) {
      return SizedBox(
        height: 45, // Increased height to prevent overflow
        child: Center(
          child: Text(
            'No approval data',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }

    // Sort discounts by approver_level_id for sequential display
    final sortedDiscounts =
        List<Map<String, dynamic>>.from(_cachedDiscountData!)
          ..sort((a, b) {
            final levelA = a['approver_level_id'] ?? 0;
            final levelB = b['approver_level_id'] ?? 0;
            return levelA.compareTo(levelB);
          });

    final Map<int, Map<String, dynamic>> approvalLevelsMap = {};

    // Add creator (User level) as the first level
    approvalLevelsMap[1] = {
      'level': 1,
      'title': 'User',
      'name': widget.approval.creator,
      'status': 'completed'
    };

    // Add levels based on actual discount data with sequential logic
    bool previousLevelApproved = true; // User level is always approved

    for (final discount in sortedDiscounts) {
      final approverLevelId = discount['approver_level_id'];
      final approved = discount['approved'];
      final approverName = discount['approver_name'];
      final approverId = discount['approver'];

      if (approverLevelId != null) {
        String title = '';
        switch (approverLevelId) {
          case 1:
            title = 'User';
            break;
          case 2:
            title = 'Direct';
            break; // Compact title for horizontal
          case 3:
            title = 'Indirect';
            break;
          case 4:
            title = 'Controller';
            break;
          case 5:
            title = 'Analyst';
            break;
          default:
            title = 'Level $approverLevelId';
        }

        String status = 'pending';
        if (approved == true) {
          status = 'completed';
          previousLevelApproved = true;
        } else if (approved == false) {
          status = 'rejected';
          previousLevelApproved = false;
        } else if (approverId != null) {
          // Check if previous level is approved for sequential logic
          if (previousLevelApproved) {
            status = 'pending';
          } else {
            status =
                'blocked'; // Cannot approve until previous level is approved
          }
        }

        approvalLevelsMap[approverLevelId] = {
          'level': approverLevelId,
          'title': title,
          'name': approverName ?? 'Pending',
          'status': status
        };
      }
    }

    // Convert map to sorted list
    final approvalLevels = approvalLevelsMap.values.toList()
      ..sort((a, b) => (a['level'] as int).compareTo(b['level'] as int));

    // Ensure User level is always completed
    if (approvalLevels.isNotEmpty) {
      approvalLevels[0]['status'] = 'completed';
    }

    return SizedBox(
      height: 45, // Increased height to prevent overflow
      child: Row(
        children: approvalLevels.asMap().entries.map((entry) {
          final index = entry.key;
          final level = entry.value;
          final isLast = index == approvalLevels.length - 1;

          Color dotColor;
          Color lineColor;
          IconData iconData;

          switch (level['status']) {
            case 'completed':
              dotColor = Colors.green;
              lineColor = Colors.green;
              iconData = Icons.check_circle;
              break;
            case 'rejected':
              dotColor = Colors.red;
              lineColor = Colors.red;
              iconData = Icons.cancel;
              break;
            case 'blocked':
              dotColor = Colors.grey;
              lineColor = Colors.grey;
              iconData = Icons.lock;
              break;
            case 'pending':
            default:
              dotColor = Colors.orange;
              lineColor = Colors.orange;
              iconData = Icons.schedule;
              break;
          }

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // Prevent overflow
                    children: [
                      Icon(
                        iconData,
                        size: 16,
                        color: dotColor,
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(
                          level['title'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: dotColor,
                          ),
                          textAlign: TextAlign.center,
                          overflow:
                              TextOverflow.ellipsis, // Handle text overflow
                          maxLines: 1, // Limit to 1 line
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _loadTimelineData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingTimeline = true;
      _timelineError = null;
    });
    try {
      final orderLetterService = locator<OrderLetterService>();
      final result = await orderLetterService.getOrderLetterDiscounts(
        orderLetterId: widget.approval.id,
      );

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

  // Public method to refresh timeline data
  Future<void> refreshTimelineData() async {
    await _loadTimelineData();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatDate(String? date) {
    if (date == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Widget _buildApprovalInfoSection(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.info.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.info,
              ),
              const SizedBox(width: 8),
              Text(
                'Informasi Approval',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Status Info
          Row(
            children: [
              Icon(
                _getStatusIcon(widget.approval.status),
                size: 14,
                color: _getStatusColor(widget.approval.status),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Status: ${widget.approval.status}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(widget.approval.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Leader Info
          if (widget.leaderData?.directLeader != null) ...[
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Direct Leader: ${widget.leaderData!.directLeader!.fullName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.work_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Jabatan: ${widget.leaderData!.directLeader!.workTitle}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tidak ada atasan langsung yang ditemukan',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderLetterDocumentPage(
                      orderLetterId: widget.approval.id,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.description, size: 16),
              label: const Text('Lihat Dokumen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
