import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? bgColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.bgColor,
    this.icon,
  });

  factory StatusBadge.confirmed() => const StatusBadge(
    label: 'Confirmado', color: AppTheme.success, bgColor: AppTheme.successLight, icon: Icons.check_circle,
  );
  factory StatusBadge.pending() => const StatusBadge(
    label: 'Pendente', color: AppTheme.warning, bgColor: AppTheme.warningLight, icon: Icons.schedule,
  );
  factory StatusBadge.absent() => const StatusBadge(
    label: 'Não vai', color: AppTheme.error, bgColor: AppTheme.errorLight, icon: Icons.cancel,
  );
  factory StatusBadge.released() => const StatusBadge(
    label: 'Liberado', color: AppTheme.success, bgColor: AppTheme.successLight, icon: Icons.exit_to_app,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
