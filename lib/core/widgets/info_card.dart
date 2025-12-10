import 'package:flutter/material.dart';

/// Widget card untuk menampilkan informasi dengan icon, label, dan value.
/// Digunakan di ApprovalCard, checkout, dan berbagai tempat lainnya.
class InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool showArrow;
  final double? labelFontSize;
  final double? valueFontSize;
  final double padding;
  final double borderRadius;

  const InfoCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.showArrow = false,
    this.labelFontSize = 9,
    this.valueFontSize = 11,
    this.padding = 8,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
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
                    fontSize: labelFontSize,
                  ),
                ),
              ),
              if (showArrow && onTap != null)
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
              fontSize: valueFontSize,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}

/// Widget untuk menampilkan row informasi sederhana dengan icon
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final double iconSize;
  final double spacing;
  final Widget? trailing;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.labelStyle,
    this.valueStyle,
    this.iconSize = 20,
    this.spacing = 8,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: iconSize,
            color: iconColor ??
                (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Text(
              '$label ',
              style: labelStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (trailing != null)
            trailing!
          else
            Text(
              value.isNotEmpty ? value : '-',
              style: valueStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
        ],
      ),
    );
  }
}

/// Widget untuk footer info dengan icon, label kecil, dan value
class FooterInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool expanded;

  const FooterInfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 9,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );

    if (expanded) {
      return Expanded(child: content);
    }
    return content;
  }
}
