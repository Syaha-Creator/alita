import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/filter_pill.dart';

/// Satu opsi filter kompak untuk [ApprovalInboxFilterBar].
class ApprovalInboxFilterChipSpec {
  const ApprovalInboxFilterChipSpec({
    required this.icon,
    required this.allLabel,
    required this.selectedValue,
    required this.onTap,
  });

  final IconData icon;
  final String allLabel;
  final String? selectedValue;
  final VoidCallback onTap;

  String get displayLabel {
    final v = selectedValue;
    if (v == null || v.isEmpty) return allLabel;
    return AppFormatters.titleCase(v.toLowerCase());
  }

  bool get isActive => selectedValue != null && selectedValue!.isNotEmpty;
}

/// Bar filter horizontal (pill) — ringan, bukan kartu penuh lebar.
class ApprovalInboxFilterBar extends StatelessWidget {
  const ApprovalInboxFilterBar({
    super.key,
    required this.chips,
    this.countCaption,
  });

  final List<ApprovalInboxFilterChipSpec> chips;
  final String? countCaption;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppLayoutTokens.space16,
        AppLayoutTokens.space4,
        AppLayoutTokens.space16,
        AppLayoutTokens.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < chips.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppLayoutTokens.space8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: FilterPill(
                      icon: chips[i].icon,
                      text: chips[i].displayLabel,
                      isActive: chips[i].isActive,
                      onTap: chips[i].onTap,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (countCaption != null && countCaption!.isNotEmpty) ...[
            const SizedBox(height: AppLayoutTokens.space6),
            Text(
              countCaption!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
