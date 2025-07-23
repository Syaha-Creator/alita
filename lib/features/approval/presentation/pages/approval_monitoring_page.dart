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

class ApprovalMonitoringPage extends StatefulWidget {
  const ApprovalMonitoringPage({super.key});

  @override
  State<ApprovalMonitoringPage> createState() => _ApprovalMonitoringPageState();
}

class _ApprovalMonitoringPageState extends State<ApprovalMonitoringPage> {
  String? currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userName = await AuthService.getCurrentUserName();
    setState(() {
      currentUser = userName;
    });

    // Fetch approvals for current user
    if (userName != null) {
      context.read<ApprovalBloc>().add(GetApprovals(creator: userName));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Monitoring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (currentUser != null) {
                context
                    .read<ApprovalBloc>()
                    .add(GetApprovals(creator: currentUser));
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
                        context
                            .read<ApprovalBloc>()
                            .add(GetApprovals(creator: currentUser));
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ApprovalsLoaded) {
            return _buildApprovalList(
                state.orderLetters, state.orderLetterDetails, isDark);
          }

          return const Center(
            child: Text('No approval data available'),
          );
        },
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
              'No Approvals Found',
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
              'No approval requests have been submitted yet.',
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
}
 