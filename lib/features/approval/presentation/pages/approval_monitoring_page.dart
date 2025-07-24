import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../theme/app_colors.dart';
import '../../data/models/order_letter_model.dart';
import '../../data/models/order_letter_detail_model.dart';
import '../bloc/approval_bloc.dart';
import '../bloc/approval_event.dart';
import '../bloc/approval_state.dart';
import '../../../../services/auth_service.dart';

enum FilterPeriod { all, daily, weekly, monthly }

class ApprovalMonitoringPage extends StatefulWidget {
  const ApprovalMonitoringPage({super.key});

  @override
  State<ApprovalMonitoringPage> createState() => _ApprovalMonitoringPageState();
}

class _ApprovalMonitoringPageState extends State<ApprovalMonitoringPage> {
  String? currentUser;
  FilterPeriod selectedPeriod = FilterPeriod.all;
  bool? isManagerLevel;
  bool isLoadingJobLevel = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userName = await AuthService.getCurrentUserName();
    final isManager = await AuthService.isManagerLevel();

    setState(() {
      currentUser = userName;
      isManagerLevel = isManager;
      isLoadingJobLevel = false;
    });

    // Fetch approvals for current user
    if (userName != null) {
      context.read<ApprovalBloc>().add(GetApprovals(
            creator: userName,
            isManager: isManager,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Show loading while determining job level
    if (isLoadingJobLevel) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Approval Monitoring'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading user permissions...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isManagerLevel == true
            ? 'Approval Monitoring (Manager)'
            : 'My Approvals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (currentUser != null) {
                context.read<ApprovalBloc>().add(GetApprovals(
                      creator: currentUser!,
                      isManager: isManagerLevel ?? false,
                    ));
              }
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocBuilder<ApprovalBloc, ApprovalState>(
        builder: (context, state) {
          if (state is ApprovalLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ApprovalError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: isDark ? AppColors.error : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.error : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (currentUser != null) {
                        context.read<ApprovalBloc>().add(GetApprovals(
                              creator: currentUser!,
                              isManager: isManagerLevel ?? false,
                            ));
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ApprovalsLoaded) {
            final filteredApprovals = _getFilteredApprovals(state.orderLetters);
            return Column(
              children: [
                _buildStatistics(filteredApprovals, state.orderLetters, isDark),
                Expanded(
                  child: _buildApprovalList(
                      filteredApprovals, state.orderLetterDetails, isDark),
                ),
              ],
            );
          }

          return const Center(
            child: Text('No approval data available'),
          );
        },
      ),
    );
  }

  Widget _buildStatistics(
    List<OrderLetterModel> filteredApprovals,
    List<OrderLetterModel> allApprovals,
    bool isDark,
  ) {
    final totalApprovals = filteredApprovals.length;
    final pendingApprovals = filteredApprovals
        .where((approval) => approval.status == 'Pending')
        .length;
    final approvedApprovals = filteredApprovals
        .where((approval) => approval.status == 'Approved')
        .length;
    final rejectedApprovals = filteredApprovals
        .where((approval) => approval.status == 'Rejected')
        .length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isManagerLevel == true
                    ? Icons.admin_panel_settings
                    : Icons.person,
                color: isDark ? AppColors.accentDark : AppColors.accentLight,
              ),
              const SizedBox(width: 8),
              Text(
                isManagerLevel == true
                    ? 'Manager Dashboard - ${_getPeriodText(selectedPeriod)}'
                    : 'My Approval Stats - ${_getPeriodText(selectedPeriod)}',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  totalApprovals.toString(),
                  Icons.list_alt,
                  isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Pending',
                  pendingApprovals.toString(),
                  Icons.pending,
                  Colors.orange,
                  isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Approved',
                  approvedApprovals.toString(),
                  Icons.check_circle,
                  Colors.green,
                  isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Rejected',
                  rejectedApprovals.toString(),
                  Icons.cancel,
                  Colors.red,
                  isDark,
                ),
              ),
            ],
          ),
          if (isManagerLevel == true) ...[
            const SizedBox(height: 12),
            _buildManagerSummary(allApprovals, isDark),
          ] else if (pendingApprovals > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$pendingApprovals approval perlu di-follow up',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManagerSummary(
      List<OrderLetterModel> allApprovals, bool isDark) {
    final totalAllApprovals = allApprovals.length;
    final pendingAllApprovals =
        allApprovals.where((approval) => approval.status == 'Pending').length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Colors.blue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Team Overview',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Team Approvals: $totalAllApprovals',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Pending Review: $pendingAllApprovals',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        pendingAllApprovals > 0 ? Colors.orange : Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalList(
    List<OrderLetterModel> orderLetters,
    List<OrderLetterDetailModel> orderLetterDetails,
    bool isDark,
  ) {
    if (orderLetters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              selectedPeriod == FilterPeriod.all
                  ? 'No Approvals Found'
                  : 'No Approvals in ${_getPeriodText(selectedPeriod)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              selectedPeriod == FilterPeriod.all
                  ? 'No approval requests have been submitted yet.'
                  : 'No approval requests found for the selected period.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orderLetters.length,
      itemBuilder: (context, index) {
        final orderLetter = orderLetters[index];
        final details = orderLetterDetails
            .where((detail) => detail.orderLetterId == orderLetter.id)
            .toList();

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'SP: ${orderLetter.noSp ?? 'N/A'}',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    _buildStatusChip(orderLetter.status, isDark),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Customer: ${orderLetter.customerName ?? 'N/A'}',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  'Created: ${orderLetter.createdAt?.split('T')[0] ?? 'N/A'} by ${orderLetter.creator ?? 'N/A'}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Letter Info
                    _buildInfoSection(
                        'Order Information',
                        [
                          _buildInfoRow(
                              'Order Date', orderLetter.orderDate ?? 'N/A'),
                          _buildInfoRow(
                              'Request Date', orderLetter.requestDate ?? 'N/A'),
                          _buildInfoRow('Phone', orderLetter.phone ?? 'N/A'),
                          _buildInfoRow(
                              'Address', orderLetter.address ?? 'N/A'),
                          _buildInfoRow(
                              'Ship To', orderLetter.addressShipTo ?? 'N/A'),
                          _buildInfoRow('PO Number', orderLetter.noPo ?? 'N/A'),
                          _buildInfoRow(
                              'Discount',
                              orderLetter.discount != null
                                  ? '${orderLetter.discount}%'
                                  : 'N/A'),
                          _buildInfoRow(
                              'Original Price',
                              orderLetter.hargaAwal != null
                                  ? FormatHelper.formatCurrency(
                                      orderLetter.hargaAwal!.toDouble())
                                  : 'N/A'),
                          _buildInfoRow(
                              'Extended Amount',
                              orderLetter.extendedAmount != null
                                  ? FormatHelper.formatCurrency(
                                      orderLetter.extendedAmount!)
                                  : 'N/A'),
                          _buildInfoRow(
                              'Type', orderLetter.keterangan ?? 'N/A'),
                          _buildInfoRow('Note', orderLetter.note ?? 'N/A'),
                        ],
                        isDark),

                    const SizedBox(height: 16),

                    // Order Details
                    if (details.isNotEmpty) ...[
                      _buildInfoSection(
                          'Order Details',
                          [
                            ...details.map(
                                (detail) => _buildDetailRow(detail, isDark)),
                          ],
                          isDark),
                    ] else ...[
                      _buildInfoSection(
                          'Order Details',
                          [
                            _buildInfoRow('Items', 'No items found', isDark),
                          ],
                          isDark),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String? status, bool isDark) {
    Color chipColor;
    Color textColor;

    switch (status?.toLowerCase()) {
      case 'approved':
        chipColor = AppColors.success;
        textColor = Colors.white;
        break;
      case 'pending':
        chipColor = AppColors.warning;
        textColor = Colors.white;
        break;
      case 'rejected':
        chipColor = AppColors.error;
        textColor = Colors.white;
        break;
      default:
        chipColor =
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
        textColor =
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status ?? 'Unknown',
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, [bool isDark = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(OrderLetterDetailModel detail, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  detail.desc1 ?? 'N/A',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              Text(
                'Qty: ${detail.qty ?? 0}',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.accentDark : AppColors.accentLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Size: ${detail.desc2 ?? 'N/A'}',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          Text(
            'Brand: ${detail.brand ?? 'N/A'}',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          Text(
            'Price: ${detail.unitPrice != null ? FormatHelper.formatCurrency(detail.unitPrice!.toDouble()) : 'N/A'}',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.success : AppColors.success,
            ),
          ),
          if (detail.itemNumber != null && detail.itemNumber!.isNotEmpty)
            Text(
              'Item #: ${detail.itemNumber}',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Filter Approval',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: FilterPeriod.values.map((period) {
              return RadioListTile<FilterPeriod>(
                title: Text(
                  _getPeriodText(period),
                  style: GoogleFonts.montserrat(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                value: period,
                groupValue: selectedPeriod,
                onChanged: (FilterPeriod? value) {
                  setState(() {
                    selectedPeriod = value!;
                  });
                  Navigator.of(context).pop();
                },
                activeColor:
                    isDark ? AppColors.accentDark : AppColors.accentLight,
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getPeriodText(FilterPeriod period) {
    switch (period) {
      case FilterPeriod.all:
        return 'Semua Approval';
      case FilterPeriod.daily:
        return 'Hari Ini';
      case FilterPeriod.weekly:
        return 'Minggu Ini';
      case FilterPeriod.monthly:
        return 'Bulan Ini';
    }
  }

  List<OrderLetterModel> _getFilteredApprovals(
      List<OrderLetterModel> allApprovals) {
    if (selectedPeriod == FilterPeriod.all) {
      return allApprovals;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return allApprovals.where((approval) {
      final approvalDate = _getApprovalDate(approval);
      if (approvalDate == null) return false;

      switch (selectedPeriod) {
        case FilterPeriod.daily:
          return approvalDate.isAfter(today.subtract(const Duration(days: 1)));
        case FilterPeriod.weekly:
          final weekAgo = today.subtract(const Duration(days: 7));
          return approvalDate.isAfter(weekAgo);
        case FilterPeriod.monthly:
          final monthAgo = DateTime(now.year, now.month - 1, now.day);
          return approvalDate.isAfter(monthAgo);
        case FilterPeriod.all:
          return true;
      }
    }).toList();
  }

  DateTime? _getApprovalDate(OrderLetterModel approval) {
    // Try to get the most accurate date
    if (approval.updatedAt != null) {
      return DateTime.tryParse(approval.updatedAt!);
    }
    if (approval.createdAt != null) {
      return DateTime.tryParse(approval.createdAt!);
    }
    if (approval.orderDate != null) {
      return DateTime.tryParse(approval.orderDate!);
    }
    return null;
  }
}
 