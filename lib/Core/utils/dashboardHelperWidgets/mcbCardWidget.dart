import 'package:flutter/material.dart';

import '../../constant/appColors_constant.dart';
import '../../constant/appTextWidget.dart';

Widget buildMcbCard(Map<String, dynamic> mcbData) {
  // 1. Dynamically find keys (e.g., MCB1Status, MCB1Load)
  String statusKey = mcbData.keys.firstWhere((k) => k.contains("Status"), orElse: () => "");
  String loadKey = mcbData.keys.firstWhere((k) => k.contains("Load"), orElse: () => "");

  // 2. Parse Data
  String name = statusKey.replaceAll("Status", ""); // Extract "MCB1" from "MCB1Status"
  bool isOn = mcbData[statusKey].toString() == "1";
  String load = mcbData[loadKey]?.toString() ?? "0.00";

  Color statusColor = isOn ? AppColors.accentGreen : AppColors.accentRed;

  return Container(

    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.cardSurface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: statusColor.withOpacity(0.5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(name, size: TextSize.subtitle, color: Colors.white),
            Icon(isOn ? Icons.toggle_on : Icons.toggle_off, color: statusColor, size: 28),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText(
              isOn ? "ON" : "TRIPPED",
              size: TextSize.title,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
            AppText(
              "$load A",
              size: TextSize.title,
              color: Colors.green,
            ),
          ],
        ),


      ],
    ),
  );
}
