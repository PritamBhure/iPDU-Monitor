import 'package:flutter/material.dart';
import '../constant/appColors_constant.dart';

class NavCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress; // Add this
  final Widget? trailing;

  const NavCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.onLongPress, // Add this
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress, // Hook it up
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.panelBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 14),
          ],
        ),
      ),
    );
  }
}