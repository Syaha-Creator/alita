import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/approval_entity.dart';
import '../../../../config/dependency_injection.dart';
import '../../../../services/leader_service.dart';
import '../../../../services/order_letter_service.dart';

class ApprovalModal extends StatefulWidget {
  final ApprovalEntity approval;
  final Function(String action, String comment) onApprovalAction;
  final int? pendingDiscountCount; // Add pending discount count parameter

  const ApprovalModal({
    super.key,
    required this.approval,
    required this.onApprovalAction,
    this.pendingDiscountCount,
  });

  @override
  State<ApprovalModal> createState() => _ApprovalModalState();
}

class _ApprovalModalState extends State<ApprovalModal>
    with TickerProviderStateMixin {
  String _selectedAction = '';
  final TextEditingController _commentController = TextEditingController();

  // Add state for user permissions
  bool _isStaffLevel = false;
  bool _isLoadingUserInfo = true;

  // Add state for discount data
  Map<String, List<Map<String, dynamic>>> _discountsByKasur = {};
  bool _isLoadingDiscounts = true;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserInfo();
    _loadDiscountData();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
  }

  Future<void> _loadUserInfo() async {
    try {
      final leaderService = locator<LeaderService>();
      final leaderData = await leaderService.getLeaderByUser();

      if (leaderData != null) {
        // For now, let's assume all users can approve
        // In real implementation, you might want to check specific roles or permissions
        final isStaff = false; // All users can approve for now

        setState(() {
          _isStaffLevel = isStaff;
          _isLoadingUserInfo = false;
        });
      } else {
        setState(() {
          _isLoadingUserInfo = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingUserInfo = false;
      });
    }
  }

  Future<void> _loadDiscountData() async {
    try {
      final orderLetterService = locator<OrderLetterService>();
      final discounts = await orderLetterService.getOrderLetterDiscounts(
          orderLetterId: widget.approval.id);

      // Group discounts by kasur name
      final Map<String, List<Map<String, dynamic>>> groupedDiscounts = {};

      for (final discount in discounts) {
        final detailId = discount['order_letter_detail_id'];

        // Find the corresponding detail to get kasur name
        final detail = widget.approval.details.firstWhere(
          (d) => d.id == detailId,
          orElse: () => widget.approval.details.first,
        );

        // Only group discounts for kasur items
        if (detail.itemType.toLowerCase() == 'kasur') {
          final kasurName = detail.desc1;

          if (!groupedDiscounts.containsKey(kasurName)) {
            groupedDiscounts[kasurName] = [];
          }
          groupedDiscounts[kasurName]!.add(discount);
        }
      }

      // Sort discounts within each kasur group by level
      for (final kasurDiscounts in groupedDiscounts.values) {
        kasurDiscounts.sort((a, b) => (a['approver_level_id'] ?? 0)
            .compareTo(b['approver_level_id'] ?? 0));
      }

      if (mounted) {
        setState(() {
          _discountsByKasur = groupedDiscounts;
          _isLoadingDiscounts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDiscounts = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _handleAction(String action) {
    setState(() {
      _selectedAction = action;
    });
  }

  void _submitAction() {
    if (_selectedAction.isEmpty) {
      _showWarningSnackBar('Please select an action');
      return;
    }

    widget.onApprovalAction(_selectedAction, _commentController.text);
    context.pop();
  }

  void _showWarningSnackBar(String message) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: isDark ? AppColors.primaryDark : Colors.white,
                  size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.primaryDark : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        elevation: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle Bar
              _buildHandleBar(colorScheme),

              // Header
              _buildHeader(theme, colorScheme, isDark),

              // Content Area
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Order Summary
                      _buildOrderSummary(theme, colorScheme, isDark),

                      const SizedBox(height: 20),

                      // Customer Info
                      _buildCustomerInfo(theme, colorScheme, isDark),

                      const SizedBox(height: 20),

                      // Action Selection
                      _buildActionSelection(theme, colorScheme, isDark),

                      const SizedBox(height: 20),

                      // Comment Section
                      _buildCommentSection(theme, colorScheme),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Loading State for User Info
              if (_isLoadingUserInfo) _buildLoadingState(theme, colorScheme),

              // Staff Level Warning
              if (_isStaffLevel && !_isLoadingUserInfo)
                _buildStaffLevelWarning(theme, colorScheme),

              // Action Buttons
              _buildActionButtons(theme, colorScheme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandleBar(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
      ),
      child: Row(
        children: [
          // Order Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID Badge
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Order #${widget.approval.id}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.primaryDark
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Customer Info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        color: isDark ? AppColors.primaryDark : Colors.white,
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
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            widget.approval.customerName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Close Button
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _waveAnimation.value * 0.1,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: colorScheme.error,
                      size: 24,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(
      ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.summarize_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Order Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
                'Total Amount',
                'Rp ${_formatNumber(widget.approval.extendedAmount.toInt())}',
                Icons.attach_money_rounded,
                colorScheme.primary),
            _buildSummaryRow(
                'Items Count',
                '${widget.approval.details.length} items',
                Icons.inventory_2_rounded,
                AppColors.info),
            // Show discount breakdown by kasur
            if (!_isLoadingDiscounts && _discountsByKasur.isNotEmpty)
              _buildDiscountBreakdown(theme, colorScheme),
            // Show pending discount count if available
            if (widget.pendingDiscountCount != null &&
                widget.pendingDiscountCount! > 0)
              _buildSummaryRow(
                  'Pending Approvals',
                  '${widget.pendingDiscountCount} diskon menunggu persetujuan',
                  Icons.pending_actions_rounded,
                  AppColors.warning),
            _buildSummaryRow(
                'Status',
                widget.approval.status,
                _getStatusIcon(widget.approval.status),
                _getStatusColor(widget.approval.status)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
      String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(
      ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.secondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Customer Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCustomerRow('Full Name', widget.approval.customerName,
                Icons.person_rounded, colorScheme.primary),
            _buildCustomerRow('Phone Number', widget.approval.phone,
                Icons.phone_rounded, AppColors.info),
            _buildCustomerRow('Email Address', widget.approval.email,
                Icons.email_rounded, AppColors.warning),
            _buildCustomerRow('Delivery Address', widget.approval.address,
                Icons.location_on_rounded, AppColors.error),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerRow(
      String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSelection(
      ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Action',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'Approve',
                Icons.check_circle_outline_rounded,
                AppColors.success,
                'approve',
                colorScheme,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'Reject',
                Icons.cancel_outlined,
                AppColors.error,
                'reject',
                colorScheme,
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon,
      Color color, String action, ColorScheme colorScheme, bool isDark) {
    final isSelected = _selectedAction == action;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleAction(action),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? color
                  : colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isSelected ? color : colorScheme.outline.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : color,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected ? Colors.white : color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Comment (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter your comment here...',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.outline.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextButton(
                onPressed: () => context.pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.close_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Close',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Only show submit button for non-staff users
          if (!_isStaffLevel) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: _isLoadingUserInfo ? null : _submitAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Submit',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
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

  /// Format discount percentage with max 2 decimal places
  String _formatDiscountPercentage(double percentage) {
    // If it's a whole number, show without decimals
    if (percentage == percentage.toInt()) {
      return percentage.toInt().toString();
    }

    // Format with max 2 decimal places and remove trailing zeros
    final formatted = percentage.toStringAsFixed(2);
    return formatted
        .replaceAll(RegExp(r'0*$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  /// Build discount breakdown section similar to order letter document page
  Widget _buildDiscountBreakdown(ThemeData theme, ColorScheme colorScheme) {
    final List<Widget> discountWidgets = [];

    for (final entry in _discountsByKasur.entries) {
      final kasurName = entry.key;
      final kasurDiscounts = entry.value;

      // Filter out discounts with 0.0 or null values first
      final validKasurDiscounts = kasurDiscounts.where((discount) {
        final percentage = (discount['discount'] is String)
            ? double.tryParse(discount['discount']) ?? 0.0
            : (discount['discount'] ?? 0.0).toDouble();
        return percentage > 0.0;
      }).toList();

      if (validKasurDiscounts.isNotEmpty) {
        // Add kasur name as header
        discountWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              kasurName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        );

        // Add discount rows for this kasur (only show discounts > 0)
        for (final discount in validKasurDiscounts) {
          final level = discount['approver_level_id'] ?? 1;
          final percentage = (discount['discount'] is String)
              ? double.tryParse(discount['discount']) ?? 0.0
              : (discount['discount'] ?? 0.0).toDouble();

          String levelLabel = '';
          switch (level) {
            case 1:
              levelLabel = 'Disc 1';
              break;
            case 2:
              levelLabel = 'Disc 2';
              break;
            case 3:
              levelLabel = 'Disc 3';
              break;
            case 4:
              levelLabel = 'Disc 4';
              break;
            case 5:
              levelLabel = 'Disc 5';
              break;
            default:
              levelLabel = 'Disc $level';
          }

          discountWidgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    levelLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '-${_formatDiscountPercentage(percentage)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    if (discountWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.discount_rounded,
                  size: 14,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Discount Breakdown',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...discountWidgets,
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Memeriksa permission...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffLevelWarning(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Staff Level - View Only',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Anda hanya dapat melihat detail approval. Untuk melakukan approve/reject, hubungi atasan Anda.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
