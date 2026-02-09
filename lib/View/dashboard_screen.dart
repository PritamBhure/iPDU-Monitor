import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controller/provider/pdu_provider.dart';
import '../Core/constant/appColors_constant.dart';
import '../Core/constant/appTextWidget.dart';
import '../Core/utils/dashboardHelperWidgets/PhaseMetersWidget.dart';
import '../Core/utils/dashboardHelperWidgets/mcbCardWidget.dart';
import '../Core/utils/dashboardHelperWidgets/networkStatus.dart';
import '../Core/utils/dashboardHelperWidgets/sensorBox.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<PduController>(context);
    bool anyMcbTripped = controller.mcbStatus.any((m) {
      var entry = m.entries.firstWhere((e) => e.key.contains("Status"), orElse: () => const MapEntry("", "1"));
      return entry.value.toString() == "0";
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(
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
      ),
      body: controller.isLoading
          ? buildLoading()
          : !controller.isConnected
          ? buildOffline(context, controller)
          : _buildBody(context, controller, anyMcbTripped),
    );
  }

  Widget _buildBody(BuildContext context, PduController controller, bool anyMcbTripped) {
    double maxAmps = double.tryParse(controller.rating) ?? 32.0;

    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 800;
    int gridCount = screenWidth > 1100 ? 4 : screenWidth > 700 ? 3 : 2;
    double gridRatio = screenWidth > 1100 ? 2.5 : 2.2;

    var allKeys = controller.sensorData.keys.toList();
    var tempKeys = allKeys.where((k) => k.toLowerCase().contains("temp")).toList();
    var humidKeys = allKeys.where((k) => k.toLowerCase().contains("humid")).toList();
    var otherKeys = allKeys.where((k) => !k.toLowerCase().contains("temp") && !k.toLowerCase().contains("humid")).toList();

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. GLOBAL ALERT BANNER
              if (anyMcbTripped) ...[
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
                      const AppText("CRITICAL: MCB TRIPPED!", size: TextSize.title, fontWeight: FontWeight.bold, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 2. CIRCUIT BREAKERS
              if (controller.mcbStatus.isNotEmpty) ...[
                _header("CIRCUIT BREAKERS"),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridCount,
                    childAspectRatio: gridRatio,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: controller.mcbStatus.length,
                  itemBuilder: (ctx, index) => buildMcbCard(controller.mcbStatus[index]),
                ),
                const SizedBox(height: 24),
              ],

              // 3. CONFIGURATION
              _header("DEVICE CONFIGURATION"),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.panelBorder),
                ),
                child: Column(
                  children: [
                    _row("Product Code", controller.productCode, "Serial No", controller.serialNo),
                    const Divider(color: Colors.white10),
                    _row("PDU Rating", "${controller.kva} KVA", "ProcessorType", "${controller.processorType} "),
                    const Divider(color: Colors.white10),
                    _row("Location", controller.location, "Outlets", controller.outletsCount),
                    const Divider(color: Colors.white10),
                    _row("Type", controller.type, "Config", controller.voltageType),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. PHASE METERS
              _header("REAL-TIME PHASE METERS"),
              buildPhaseMeters(controller, maxAmps, context),
              const SizedBox(height: 24),

              // 5. ELECTRICAL TABLE
              _header("ELECTRICAL PARAMETERS"),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.panelBorder),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: isWeb ? 1100 : 0),
                    child: DataTable(
                      headingTextStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                      columnSpacing: isWeb ? 40 : 15,
                      columns: const [
                        DataColumn(label: AppText("PHASE  ", size: TextSize.tableHeader, color: Colors.grey)),
                        DataColumn(label: AppText("VOLTAGE", size: TextSize.tableHeader, color: Colors.grey)),
                        DataColumn(label: AppText("CURRENT", size: TextSize.tableHeader, color: Colors.grey)),
                        DataColumn(label: AppText("ACTIVE ENERGY", size: TextSize.tableHeader, color: Colors.grey)),
                        DataColumn(label: AppText("POWER FACTOR", size: TextSize.tableHeader, color: Colors.grey)),
                        DataColumn(label: AppText("APPARENT POWER", size: TextSize.tableHeader, color: Colors.grey)),
                        DataColumn(label: AppText("FREQUENCY", size: TextSize.tableHeader, color: Colors.grey)),
                      ],
                      rows: controller.phasesData.map((d) {
                        return DataRow(cells: [
                          DataCell(AppText(d['Phase'] ?? "-", size: TextSize.body, color: AppColors.accentOrange)),
                          DataCell(AppText(d['voltage']?.toString() ?? "0", size: TextSize.body)),
                          DataCell(AppText(d['current']?.toString() ?? "0", size: TextSize.body)),
                          DataCell(AppText(d['kWattHr']?.toString() ?? "0", size: TextSize.body)),
                          DataCell(AppText(d['powerFactor']?.toString() ?? "0", size: TextSize.body)),
                          DataCell(AppText(d['VA']?.toString() ?? "0", size: TextSize.body)),
                          DataCell(AppText(d['freqInHz']?.toString() ?? "0", size: TextSize.body)),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 6. SENSORS
              if (controller.sensorData.isNotEmpty) ...[
                _header("ENVIRONMENTAL SENSORS"),
                if (tempKeys.isNotEmpty || humidKeys.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: tempKeys.map((key) => Padding(padding: const EdgeInsets.only(bottom: 10, right: 4), child: _buildSensorWidget(controller, key))).toList(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: humidKeys.map((key) => Padding(padding: const EdgeInsets.only(bottom: 10, left: 4), child: _buildSensorWidget(controller, key))).toList(),
                        ),
                      ),
                    ],
                  ),
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
                    itemBuilder: (ctx, index) => _buildSensorWidget(controller, otherKeys[index]),
                  ),
                ],
              ],

              // 7. OUTLETS
              if (controller.outlets.isNotEmpty) ...[
                const SizedBox(height: 24),
                _header("OUTLET LOAD METERS"),
                isWeb
                    ? GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.5, crossAxisSpacing: 16, mainAxisSpacing: 16),
                  itemCount: controller.outlets.length,
                  itemBuilder: (ctx, i) => _buildOutletCard(controller.outlets[i], maxAmps),
                )
                    : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.outlets.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _buildOutletCard(controller.outlets[i], maxAmps),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildSensorWidget(PduController controller, String key) {
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

  Widget _header(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: AppText(t, size: TextSize.small, color: Colors.grey, fontWeight: FontWeight.bold));

  Widget _row(String l1, String v1, String l2, String v2) {
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [AppText(l1, size: TextSize.small, color: Colors.grey), AppText(v1, size: TextSize.subtitle)])),
      Container(width: 1, height: 30, color: Colors.white10), const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [AppText(l2, size: TextSize.small, color: Colors.grey), AppText(v2, size: TextSize.subtitle)])),
    ]);
  }

  Widget _buildOutletCard(dynamic outlet, double maxAmps) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.panelBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                // --- LOGIC CHANGE HERE ---
                // Show Green if ON, Red if OFF
                Icon(
                    Icons.power_settings_new, // Use power icon
                    color: outlet.isOn ? AppColors.accentGreen : AppColors.accentRed,
                    size: 24
                ),
                const SizedBox(width: 8),
                AppText(outlet.id, size: TextSize.subtitle, fontWeight: FontWeight.bold),
              ]),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppText(outlet.isOn ?
                  "${outlet.current.toStringAsFixed(2)} A":"---",
                    size: TextSize.title,
                    fontWeight: FontWeight.bold,
                    color:outlet.isOn ? getLoadColor(outlet.current, maxAmps / 8): AppColors.accentRed,
                  ),
                  // Optional: Show text status below amps
                  AppText(
                    outlet.isOn ? "ON" : "OFF",
                    size: TextSize.small,
                    color: outlet.isOn ? AppColors.accentGreen : AppColors.accentRed,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
          Row(
            children: [
              Expanded(child: progressMetric("VOLTAGE", "${outlet.voltage.toStringAsFixed(1)} V", outlet.voltage, 260.0, Colors.blueAccent)),
              const SizedBox(width: 16),
              Expanded(child: progressMetric("POWER", "${outlet.activePower.toStringAsFixed(2)} kW", outlet.activePower, 4.0, Colors.orangeAccent)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: progressMetric("ENERGY", "${outlet.energy.toStringAsFixed(2)} kWh", outlet.energy, 1000.0, Colors.greenAccent)),
              const SizedBox(width: 16),
              Expanded(child: progressMetric("P.F.", outlet.powerFactor.toStringAsFixed(2), outlet.powerFactor, 1.0, Colors.purpleAccent)),
            ],
          ),
        ],
      ),
    );
  }
}