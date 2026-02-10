import 'package:flutter/material.dart';

import '../../constant/appColors_constant.dart';
import '../../constant/appTextWidget.dart';


class AlertBannerWidget extends StatelessWidget {
  final String message;
  const AlertBannerWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accentRed,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 12),
              AppText(message, size: TextSize.title, fontWeight: FontWeight.bold, color: Colors.white),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}