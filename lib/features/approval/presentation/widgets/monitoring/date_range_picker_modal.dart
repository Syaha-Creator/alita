import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/widgets/styled_container.dart';
import '../../../../../theme/app_colors.dart';

/// Modal untuk memilih rentang tanggal filter
class DateRangePickerModal extends StatefulWidget {
  final DateTime? initialDateFrom;
  final DateTime? initialDateTo;
  final bool isDateFilterActive;
  final void Function(DateTime dateFrom, DateTime dateTo) onApply;
  final VoidCallback onClear;

  const DateRangePickerModal({
    super.key,
    this.initialDateFrom,
    this.initialDateTo,
    required this.isDateFilterActive,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<DateRangePickerModal> createState() => _DateRangePickerModalState();
}

class _DateRangePickerModalState extends State<DateRangePickerModal> {
  late DateTime _tempDateFrom;
  late DateTime _tempDateTo;

  @override
  void initState() {
    super.initState();
    _tempDateFrom = widget.initialDateFrom ??
        DateTime.now().subtract(const Duration(days: 30));
    _tempDateTo = widget.initialDateTo ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
          _buildHandleBar(colorScheme),
          _buildHeader(theme, colorScheme, isDark),
          _buildDatePickers(colorScheme, theme),
          _buildActionButtons(colorScheme),
        ],
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
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
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
        color: colorScheme.primary.withValues(alpha: 0.05),
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
              Icons.date_range_rounded,
              color: isDark ? AppColors.primaryDark : Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: AppPadding.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Rentang Waktu',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Pilih tanggal untuk filter approval',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.close_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickers(ColorScheme colorScheme, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Date From
          _DatePickerTile(
            label: 'Tanggal Dari',
            date: _tempDateFrom,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _tempDateFrom,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(colorScheme: colorScheme),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _tempDateFrom = picked;
                });
              }
            },
            colorScheme: colorScheme,
            theme: theme,
          ),
          const SizedBox(height: AppPadding.p16),

          // Date To
          _DatePickerTile(
            label: 'Tanggal Sampai',
            date: _tempDateTo,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _tempDateTo,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(colorScheme: colorScheme),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _tempDateTo = picked;
                });
              }
            },
            colorScheme: colorScheme,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          // Clear Filter Button
          if (widget.isDateFilterActive)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  widget.onClear();
                  context.pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.clear_rounded, size: 18),
                    SizedBox(width: AppPadding.p8),
                    Text(
                      'Hapus Filter',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.isDateFilterActive) const SizedBox(width: AppPadding.p12),

          // Apply Button
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_tempDateFrom, _tempDateTo);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, size: 18),
                  SizedBox(width: AppPadding.p8),
                  Text(
                    'Terapkan',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onTap,
    required this.colorScheme,
    required this.theme,
  });

  String _formatDateForDisplay(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: StyledContainer.surface(
        padding: const EdgeInsets.all(16),
        borderWidth: 1,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: colorScheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: AppPadding.p16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: AppPadding.p4),
                  Text(
                    _formatDateForDisplay(date),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
