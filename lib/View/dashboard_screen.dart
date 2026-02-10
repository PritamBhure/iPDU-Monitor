import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controller/provider/pdu_provider.dart';
import '../Core/constant/appColors_constant.dart';
import '../Core/constant/appTextWidget.dart';
import '../Core/utils/dashboardHelperWidgets/alertBannerWidget.dart';
import '../Core/utils/dashboardHelperWidgets/circuitBreakerGridWidget.dart';
import '../Core/utils/dashboardHelperWidgets/configurationWidget.dart';
import '../Core/utils/dashboardHelperWidgets/sensorGridWidget.dart';
import '../Core/utils/dashboardHelperWidgets/electricalTableWidget.dart';
import '../Core/utils/dashboardHelperWidgets/subDashboardWidget/PhaseMetersWidget.dart';
import '../Core/utils/dashboardHelperWidgets/subDashboardWidget/networkStatus.dart';
import '../Core/utils/dashboardHelperWidgets/outletListWidget.dart';


class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<PduController>(context);

    // Global Logic: Check for Alerts
    bool anyMcbTripped = controller.mcbStatus.any((m) {
      var entry = m.entries.firstWhere((e) => e.key.contains("Status"), orElse: () => const MapEntry("", "1"));
      return entry.value.toString() == "0";
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: _buildAppBar(controller),
      body: controller.isLoading
          ? buildLoading()
          : !controller.isConnected
          ? buildOffline(context, controller)
          : _buildBody(context, controller, anyMcbTripped),
    );
  }

  PreferredSizeWidget _buildAppBar(PduController controller) {
    return AppBar(
      backgroundColor: AppColors.cardSurface,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            controller.pduName != "-" ? controller.pduName : controller.device.name,
            size: TextSize.title,
            fontWeight: FontWeight.bold,
          ),
          AppText(
            "IP: ${controller.device.ip}",
            size: TextSize.small,
            color: Colors.grey,
          ),
        ],
      ),
      actions: [buildStatusBadge(controller)],
    );
  }

  Widget _buildBody(BuildContext context, PduController controller, bool anyMcbTripped) {
    double maxAmps = double.tryParse(controller.rating) ?? 32.0;

    // Check Logic: IMIS + Delta
    bool isDeltaIMIS = (controller.type == "IMIS" || controller.type == "IMIS_DELTA") &&
        (controller.voltageType.toUpperCase().contains("DELTA"));

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Alert Banner
              if (anyMcbTripped) AlertBannerWidget(message: "CRITICAL: MCB TRIPPED!"),

              // 2. Circuit Breakers
              if (controller.mcbStatus.isNotEmpty)
                CircuitBreakerGridWidget(mcbStatus: controller.mcbStatus),

              // 3. Configuration
              ConfigurationWidget(controller: controller),
              const SizedBox(height: 24),

              // 4. Phase Meters
              SectionHeader(title: "REAL-TIME PHASE METERS"),
              buildPhaseMeters(controller, maxAmps, context, isDeltaIMIS),
              const SizedBox(height: 24),

              // 5. Electrical Table
              ElectricalTableWidget(controller: controller, isDeltaIMIS: isDeltaIMIS),
              const SizedBox(height: 24),

              // 6. Sensors
              if (controller.sensorData.isNotEmpty)
                SensorGridWidget(controller: controller),

              // 7. Outlets (Contains Search Logic)
              if (controller.outlets.isNotEmpty)
                OutletListWidget(controller: controller, maxAmps: maxAmps),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple Helper for Headers
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppText(title, size: TextSize.small, color: Colors.grey, fontWeight: FontWeight.bold)
    );
  }
}