import 'package:flutter/material.dart';
import 'package:pdu_control_system/Core/utils/dashboardHelperWidgets/subDashboardWidget/sensorBox.dart';
import '../../../Controller/provider/pdu_provider.dart';
import '../../constant/appTextWidget.dart';

class SensorGridWidget extends StatelessWidget {
  final PduController controller;
  const SensorGridWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int gridCount = screenWidth > 1100 ? 4 : screenWidth > 700 ? 3 : 2;

    var allKeys = controller.sensorData.keys.toList();
    var tempKeys = allKeys.where((k) => k.toLowerCase().contains("temp")).toList();
    var humidKeys = allKeys.where((k) => k.toLowerCase().contains("humid")).toList();
    var otherKeys = allKeys.where((k) => !k.toLowerCase().contains("temp") && !k.toLowerCase().contains("humid")).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: AppText("ENVIRONMENTAL SENSORS", size: TextSize.small, color: Colors.grey, fontWeight: FontWeight.bold)
        ),

        // Temp & Humidity Rows
        if (tempKeys.isNotEmpty || humidKeys.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: tempKeys.map((key) => Padding(padding: const EdgeInsets.only(bottom: 10, right: 4), child: _buildSensorItem(key))).toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: humidKeys.map((key) => Padding(padding: const EdgeInsets.only(bottom: 10, left: 4), child: _buildSensorItem(key))).toList(),
                ),
              ),
            ],
          ),

        // Other Sensors Grid
        if (otherKeys.isNotEmpty) ...[
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCount,
              childAspectRatio: 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: otherKeys.length,
            itemBuilder: (ctx, index) => _buildSensorItem(otherKeys[index]),
          ),
        ],
      ],
    );
  }

  Widget _buildSensorItem(String key) {
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
}