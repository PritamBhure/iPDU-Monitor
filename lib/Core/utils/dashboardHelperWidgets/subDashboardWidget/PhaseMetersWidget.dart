import 'package:flutter/material.dart';

import '../../../../Controller/provider/pdu_provider.dart';
import '../../../constant/appColors_constant.dart';
import '../../../constant/appTextWidget.dart';
import '../../electricMeterUI.dart';



Widget buildPhaseMeters(PduController controller, double maxAmps, BuildContext context, bool isDeltaIMIS) {
  double screenWidth = MediaQuery.of(context).size.width;
  double cardWidth = screenWidth < 600 ? screenWidth * 0.85 : 390.0;

  // --- 1. DYNAMIC HEIGHT ADJUSTMENT ---
  // If Delta/IMIS, reduce height to remove empty space
  double containerHeight = isDeltaIMIS ? 240 : 320;

  return SizedBox(
    height: containerHeight, // Use dynamic height
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: controller.phasesData.length,
      separatorBuilder: (c, i) => const SizedBox(width: 12),
      itemBuilder: (ctx, i) {
        final phase = controller.phasesData[i];

        double currentVal = double.tryParse(phase['current']?.toString() ?? "0") ?? 0.0;
        double voltVal = double.tryParse(phase['voltage']?.toString() ?? "0") ?? 0.0;
        double energyVal = isDeltaIMIS ? 0 : double.tryParse(phase['kWattHr']?.toString() ?? "0") ?? 0.0;
        double pfVal = isDeltaIMIS ? 0 : double.tryParse(phase['powerFactor']?.toString() ?? "0") ?? 0.0;
        double freqVal = isDeltaIMIS ? 0 : double.tryParse(phase['freqInHz']?.toString() ?? "0") ?? 0.0;

        String phaseName = phase['Phase'] ?? "L${i + 1}";

        return Container(
          width: cardWidth,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.panelBorder),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText("PHASE $phaseName", size: TextSize.body, color: Colors.grey, fontWeight: FontWeight.bold),
                  const Icon(Icons.bolt, color: AppColors.accentOrange, size: 16),
                ],
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 100, width: 100,
                child: CustomPaint(
                  painter: GaugePainter(value: currentVal, maxValue: maxAmps, color: getLoadColor(currentVal, maxAmps)),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        AppText(currentVal.toStringAsFixed(1), size: TextSize.large, fontWeight: FontWeight.bold),
                        const AppText("Current", size: TextSize.micro, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(color: Colors.white10, height: 20),

              Expanded(
                child: isDeltaIMIS
                    ? Center(
                  // Voltage is centered vertically in the reduced space
                  child: progressMetric("VOLTAGE", "${voltVal.toStringAsFixed(1)} V", voltVal, 440.0, Colors.blueAccent),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      children: [
                        Expanded(child: progressMetric("VOLTAGE", "${voltVal.toStringAsFixed(1)} V", voltVal, 260.0, Colors.blueAccent)),
                        const SizedBox(width: 16),
                        Expanded(child: progressMetric("ENERGY", "${energyVal.toStringAsFixed(1)} kWh", energyVal, 1000.0, Colors.greenAccent)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: progressMetric("POWER FACTOR", pfVal.toStringAsFixed(2), pfVal, 1.0, Colors.orangeAccent)),
                        const SizedBox(width: 16),
                        Expanded(child: progressMetric("FREQUENCY", "${freqVal.toStringAsFixed(1)} Hz", freqVal, 65.0, Colors.purpleAccent)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}



Color getLoadColor(double val, double max) {
  if (max == 0) return AppColors.accentGreen;
  double pct = val / max;
  if (pct < 0.5) return AppColors.accentGreen;
  if (pct < 0.8) return AppColors.accentOrange;
  return AppColors.accentRed;
}

Widget progressMetric(String label, String valueText, double value, double max, Color color) {
  double progress = (value / max).clamp(0.0, 1.0);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(label, size: TextSize.small, color: Colors.grey),
          AppText(valueText, size: TextSize.body, fontWeight: FontWeight.bold),
        ],
      ),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
        ),
      ),
    ],
  );
}

