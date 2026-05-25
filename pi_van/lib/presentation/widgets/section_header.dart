import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.grey900)),
        if (actionLabel != null)
          TextButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon ?? Icons.add, size: 18),
            label: Text(actionLabel!, style: const TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
              backgroundColor: AppTheme.primaryLight,
            ),
          ),
      ],
    );
  }
}
