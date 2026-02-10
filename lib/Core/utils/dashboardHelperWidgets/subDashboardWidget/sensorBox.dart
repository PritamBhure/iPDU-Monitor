import 'package:flutter/material.dart';

import '../../../../Controller/provider/pdu_provider.dart';
import '../../../constant/appColors_constant.dart';
import '../../../constant/appTextWidget.dart';


Widget buildSensorWidget(PduController controller, String key) {
  IconData icon = Icons.sensors;
  Color color = Colors.blueAccent;
  String k = key.toLowerCase();
  if (k.contains("door")) { icon = Icons.door_sliding; color = Colors.orange; }
  else if (k.contains("smoke")) { icon = Icons.local_fire_department; color = Colors.red; }
  else if (k.contains("water")) { icon = Icons.water; color = Colors.cyan; }
  else if (k.contains("temp")) { icon = Icons.thermostat; color = Colors.redAccent; }
  else if (k.contains("humid")) { icon = Icons.water_drop; color = Colors.blue; }
  return sensorBox(key, controller.getSensorDisplay(key), icon, color);
}


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


