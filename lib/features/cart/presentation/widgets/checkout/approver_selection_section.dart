import 'package:flutter/material.dart';

import '../../../../../config/dependency_injection.dart';
import '../../../../../core/widgets/custom_dropdown.dart';
import '../../../../../features/approval/data/models/approval_sales_model.dart';
import '../../../../../services/approval_sales_service.dart';
import '../../../../../theme/app_colors.dart';

/// Widget for selecting SPV and RSM approvers during checkout
class ApproverSelectionSection extends StatefulWidget {
  final bool isDark;
  final bool requiresRsmApproval;
  final Function(ApprovalSalesUserModel?)? onSpvSelected;
  final Function(ApprovalSalesUserModel?)? onRsmSelected;
  final ApprovalSalesUserModel? initialSpv;
  final ApprovalSalesUserModel? initialRsm;

  const ApproverSelectionSection({
    super.key,
    required this.isDark,
    required this.requiresRsmApproval,
    this.onSpvSelected,
    this.onRsmSelected,
    this.initialSpv,
    this.initialRsm,
  });

  @override
  State<ApproverSelectionSection> createState() =>
      _ApproverSelectionSectionState();
}

class _ApproverSelectionSectionState extends State<ApproverSelectionSection> {
  List<ApprovalSalesUserModel> _approverList = [];
  ApprovalSalesUserModel? _selectedSpv;
  ApprovalSalesUserModel? _selectedRsm;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedSpv = widget.initialSpv;
    _selectedRsm = widget.initialRsm;
    _loadApprovers();
  }

  Future<void> _loadApprovers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final approvalSalesService = locator<ApprovalSalesService>();
      final response = await approvalSalesService.getApprovalSales();

      if (response != null && response.hasUsers) {
        setState(() {
          _approverList = response.users;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Tidak dapat memuat daftar approver';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat daftar approver: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        color: widget.isDark ? AppColors.cardDark : Colors.white,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        color: widget.isDark ? AppColors.cardDark : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: widget.isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadApprovers,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: widget.isDark ? AppColors.cardDark : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.approval_rounded,
                  size: 20,
                  color: widget.isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pilih Approver',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SPV Selection (always visible)
            _buildApproverDropdown(
              label: 'Supervisor (SPV)',
              hint: 'Pilih Supervisor',
              selectedValue: _selectedSpv,
              onChanged: (value) {
                setState(() {
                  _selectedSpv = value;
                });
                widget.onSpvSelected?.call(value);
              },
              isRequired: true,
            ),

            // RSM Selection (conditional based on discount level)
            if (widget.requiresRsmApproval) ...[
              const SizedBox(height: 12),
              _buildApproverDropdown(
                label: 'RSM',
                hint: 'Pilih RSM',
                selectedValue: _selectedRsm,
                onChanged: (value) {
                  setState(() {
                    _selectedRsm = value;
                  });
                  widget.onRsmSelected?.call(value);
                },
                isRequired: true,
              ),
            ],

            const SizedBox(height: 8),
            Text(
              'Analyst akan ditentukan secara otomatis oleh sistem',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: widget.isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApproverDropdown({
    required String label,
    required String hint,
    required ApprovalSalesUserModel? selectedValue,
    required Function(ApprovalSalesUserModel?) onChanged,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: widget.isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        CustomDropdown<ApprovalSalesUserModel>(
          labelText: '',
          selectedValue: selectedValue,
          items: _approverList,
          onChanged: onChanged,
          hintText: hint,
          isSearchable: true,
        ),
      ],
    );
  }
}
