import 'package:flutter/material.dart';

import '../../constant/appColors_constant.dart';
import '../../constant/appTextWidget.dart';

Widget sensorBox(String l, String v, IconData i, Color c) {
  // Format label nicely (e.g. th01temperature -> TH01 Temp)
  String label = l.replaceAll("temperature", " Temp").replaceAll("humidity", " Hum").toUpperCase();

  // Check for special values to change color
  Color valColor = Colors.white;
  if(v == "Error" || v == "Not Connected") {
    valColor = Colors.red;
  } else if (v == "Disable") valColor = Colors.grey;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: AppColors.cardSurface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.panelBorder),
    ),
    child: Row(
      children: [
        Icon(i, color: c, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(label, size: TextSize.small, color: Colors.grey),
              const SizedBox(height: 2),
              AppText(v, size: TextSize.body, color: valColor, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    ),
  );
}
