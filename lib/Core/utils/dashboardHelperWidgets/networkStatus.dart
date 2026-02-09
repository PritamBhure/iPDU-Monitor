
import 'package:flutter/material.dart';

import '../../../Controller/provider/pdu_provider.dart';
import '../../constant/appColors_constant.dart';
import '../../constant/appTextWidget.dart';

Widget buildLoading() => const Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      CircularProgressIndicator(color: AppColors.primaryBlue),
      SizedBox(height: 16),
      AppText("Connecting...", size: TextSize.body, color: AppColors.textSecondary),
    ],
  ),
);

Widget buildOffline(BuildContext ctx, PduController c) => Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.wifi_off, size: 64, color: AppColors.accentRed),
      const SizedBox(height: 16),
      const AppText("PDU IS OFFLINE", size: TextSize.large, color: Colors.white),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: AppText(
          "Reason: ${c.connectionStatus}",
          size: TextSize.body,
          color: Colors.grey,
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
        onPressed: () => Navigator.pop(ctx),
        icon: const Icon(Icons.exit_to_app),
        label: const Text("Back"), // Keep native Text for Buttons usually
      ),
    ],
  ),
);

Widget buildStatusBadge(PduController c) {
  return Container(
    margin: const EdgeInsets.only(right: 16),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: c.isConnected ? AppColors.statusGreenBg : AppColors.statusRedBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: c.isConnected ? AppColors.accentGreen : AppColors.accentRed),
    ),
    child: AppText(
      c.isConnected ? "ONLINE" : "OFFLINE",
      size: TextSize.small,
      color: c.isConnected ? AppColors.accentGreen : AppColors.accentRed,
      fontWeight: FontWeight.bold,
    ),
  );
}