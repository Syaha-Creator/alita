import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_choice_chip.dart';

/// Self-contained installment simulation widget.
///
/// Shows tenor chips and a monthly payment calculation based on
/// [effectiveTotal] divided by the selected tenor.
class InstallmentSimulationSection extends StatelessWidget {
  final double effectiveTotal;
  final int selectedTenor;
  final List<int> tenorOptions;
  final ValueChanged<int> onTenorChanged;

  const InstallmentSimulationSection({
    super.key,
    required this.effectiveTotal,
    required this.selectedTenor,
    required this.tenorOptions,
    required this.onTenorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.credit_card_outlined,
                color: AppColors.textPrimary, size: 20),
            SizedBox(width: 8),
            Text(
              'Simulasi Cicilan 0%',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: tenorOptions.map((tenor) {
                    final isSelected = selectedTenor == tenor;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: AppChoiceChip(
                        label: '$tenor Bulan',
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) onTenorChanged(tenor);
                        },
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Cicilan per bulan',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: AppFormatters.currencyIdr(
                            effectiveTotal / selectedTenor,
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const TextSpan(
                          text: ' / bln',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  '*Estimasi menggunakan kartu kredit cicilan 0%. Hubungi bank terkait untuk detail biaya layanan.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
