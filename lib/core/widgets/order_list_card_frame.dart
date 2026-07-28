import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout_tokens.dart';

/// Reusable frame for order-like list cards.
///
/// Provides the shared shell (border/shadow/ripple), header (reference no +
/// status), and footer (date + total); [body] stays flexible per feature.
class OrderListCardFrame extends StatelessWidget {
  final String referenceNo;
  final Widget trailingStatus;
  final Widget body;
  final String dateText;
  final String totalText;
  final VoidCallback onTap;

  const OrderListCardFrame({
    super.key,
    required this.referenceNo,
    required this.trailingStatus,
    required this.body,
    required this.dateText,
    required this.totalText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Pesanan $referenceNo',
      child: Container(
        margin: AppLayoutTokens.listCardMargin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppLayoutTokens.radius16),
        border: Border.all(color: AppColors.surfaceLight),
        boxShadow: [AppLayoutTokens.cardShadowSoft],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppLayoutTokens.radius16),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppLayoutTokens.radius16),
          onTap: onTap,
          child: Padding(
            padding: AppLayoutTokens.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppLayoutTokens.space8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(
                          AppLayoutTokens.radius8,
                        ),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppLayoutTokens.space10),
                    Expanded(
                      child: Text(
                        referenceNo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    trailingStatus,
                  ],
                ),
                const Padding(
                  padding: AppLayoutTokens.verticalDividerPadding,
                  child: Divider(height: 1, color: AppColors.surfaceLight),
                ),
                body,
                const SizedBox(height: AppLayoutTokens.space14),
                Container(
                  padding: AppLayoutTokens.footerBoxPadding,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(
                      AppLayoutTokens.radius10,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: AppLayoutTokens.space4),
                          Text(
                            dateText,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        totalText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
