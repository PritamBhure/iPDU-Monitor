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

// CHANGED: Converted to StatefulWidget to handle Search State
class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  // --- SEARCH STATE ---
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

    // --- 1. DETERMINE RESTRICTED VIEW (IMIS + Delta) ---
    // Check if Type is IMIS and Voltage Config contains "Delta" (case-insensitive)
    bool isDeltaIMIS = (controller.type == "IMIS" || controller.type == "IMIS_DELTA") &&
        (controller.voltageType.toUpperCase().contains("DELTA"));

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
              buildPhaseMeters(controller, maxAmps, context, isDeltaIMIS), // <--- PASS FLAG              const SizedBox(height: 24),

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
                    // --- 2. CENTER LOGIC ---
                    // If DeltaIMIS (small table), allow it to shrink and center.
                    // If Normal (big table), force min-width on Web so it doesn't squish.
                    constraints: BoxConstraints(
                        minWidth: (isWeb && !isDeltaIMIS) ? 1100 : MediaQuery.of(context).size.width - 60
                    ),
                    child: Center( // <--- This centers the DataTable within the scrollable area
                      child: DataTable(
                        headingTextStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                        // Reduce column spacing if in Delta mode to keep it compact
                        columnSpacing: isDeltaIMIS ? 40 : (isWeb ? 40 : 15),
                        columns: [
                          const DataColumn(label: AppText("PHASE  ", size: TextSize.tableHeader, color: Colors.grey)),
                          const DataColumn(label: AppText("VOLTAGE", size: TextSize.tableHeader, color: Colors.grey)),
                          const DataColumn(label: AppText("CURRENT", size: TextSize.tableHeader, color: Colors.grey)),
                          if (!isDeltaIMIS) const DataColumn(label: AppText("ACTIVE ENERGY", size: TextSize.tableHeader, color: Colors.grey)),
                          if (!isDeltaIMIS) const DataColumn(label: AppText("POWER FACTOR", size: TextSize.tableHeader, color: Colors.grey)),
                          if (!isDeltaIMIS) const DataColumn(label: AppText("APPARENT POWER", size: TextSize.tableHeader, color: Colors.grey)),
                          if (!isDeltaIMIS) const DataColumn(label: AppText("FREQUENCY", size: TextSize.tableHeader, color: Colors.grey)),
                        ],
                        rows: controller.phasesData.map((d) {
                          return DataRow(cells: [
                            DataCell(AppText(d['Phase'] ?? "-", size: TextSize.body, color: AppColors.accentOrange)),
                            DataCell(AppText(d['voltage']?.toString() ?? "0", size: TextSize.body)),
                            DataCell(AppText(d['current']?.toString() ?? "0", size: TextSize.body)),
                            if (!isDeltaIMIS) DataCell(AppText(d['kWattHr']?.toString() ?? "0", size: TextSize.body)),
                            if (!isDeltaIMIS) DataCell(AppText(d['powerFactor']?.toString() ?? "0", size: TextSize.body)),
                            if (!isDeltaIMIS) DataCell(AppText(d['VA']?.toString() ?? "0", size: TextSize.body)),
                            if (!isDeltaIMIS) DataCell(AppText(d['freqInHz']?.toString() ?? "0", size: TextSize.body)),
                          ]);
                        }).toList(),
                      ),
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
                          children: tempKeys.map((key) => Padding(padding: const EdgeInsets.only(bottom: 10, right: 4), child: buildSensorWidget(controller, key))).toList(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: humidKeys.map((key) => Padding(padding: const EdgeInsets.only(bottom: 10, left: 4), child: buildSensorWidget(controller, key))).toList(),
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
                    itemBuilder: (ctx, index) => buildSensorWidget(controller, otherKeys[index]),
                  ),
                ],
              ],

              // 7. OUTLETS (With Search)
              if (controller.outlets.isNotEmpty) ...[
                const SizedBox(height: 24),
                // --- NEW SEARCH HEADER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _header("OUTLET LOAD METERS"),
                    IconButton(
                      icon: Icon(
                        _isSearchVisible ? Icons.close : Icons.search,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearchVisible = !_isSearchVisible;
                          if (!_isSearchVisible) {
                            _searchQuery = "";
                            _searchController.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),

                // --- SEARCH BAR ---
                if (_isSearchVisible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Search Outlet (e.g. 1, 24)",
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
                        filled: true,
                        fillColor: AppColors.cardSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),

                // --- FILTER LOGIC ---
                Builder(
                  builder: (context) {
                    // Filter outlets based on search query
                    final filteredOutlets = controller.outlets.where((outlet) {
                      return outlet.id.toLowerCase().contains(_searchQuery.toLowerCase());
                    }).toList();

                    if (filteredOutlets.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: AppText("No outlets found", size: TextSize.body, color: Colors.grey)),
                      );
                    }

                    // Display Filtered List
                    return isWeb
                        ? GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, childAspectRatio: 2.5, crossAxisSpacing: 16, mainAxisSpacing: 16),
                      itemCount: filteredOutlets.length,
                      itemBuilder: (ctx, i) => _buildOutletCard(filteredOutlets[i], maxAmps),
                    )
                        : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredOutlets.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => _buildOutletCard(filteredOutlets[i], maxAmps),
                    );
                  },
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
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.panelBorder)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            // Green/Red Power Icon
            Icon(
                Icons.power_settings_new,
                color: outlet.isOn ? AppColors.accentGreen : AppColors.accentRed,
                size: 24
            ),
            const SizedBox(width: 8),
            AppText(outlet.id, size: TextSize.subtitle, fontWeight: FontWeight.bold)
          ]),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(outlet.isOn ? "${outlet.current.toStringAsFixed(2)} A" : "---", size: TextSize.title, fontWeight: FontWeight.bold, color: outlet.isOn ? getLoadColor(outlet.current, maxAmps / 8) : AppColors.accentRed),
              AppText(
                outlet.isOn ? "ON" : "OFF",
                size: TextSize.small,
                color: outlet.isOn ? AppColors.accentGreen : AppColors.accentRed,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
        ]),
        const Divider(color: Colors.white10, height: 20),
        Row(children: [
          Expanded(child: progressMetric("VOLTAGE", "${outlet.voltage.toStringAsFixed(1)} V", outlet.voltage, 260.0, Colors.blueAccent)), const SizedBox(width: 16),
          Expanded(child: progressMetric("POWER", "${outlet.activePower.toStringAsFixed(2)} kW", outlet.activePower, 4.0, Colors.orangeAccent)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: progressMetric("ENERGY", "${outlet.energy.toStringAsFixed(2)} kWh", outlet.energy, 1000.0, Colors.greenAccent)), const SizedBox(width: 16),
          Expanded(child: progressMetric("P.F.", outlet.powerFactor.toStringAsFixed(2), outlet.powerFactor, 1.0, Colors.purpleAccent)),
        ]),
      ]),
    );
  }
}