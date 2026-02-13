import 'package:flutter/material.dart';
import '../../../../Controller/provider/pdu_provider.dart';
import '../../../constant/appColors_constant.dart';
import '../../../constant/appTextWidget.dart';
import '../../widgets/customButton.dart';
// Ensure this path matches your project structure
import 'package:pdu_control_system/Core/utils/dashboardHelperWidgets/subDashboardWidget/sensorBox.dart';

import '../../widgets/tableInputBoxWidget.dart';

class SensorConfigEditScreen extends StatefulWidget {
  final PduController controller;
  const SensorConfigEditScreen({super.key, required this.controller});

  @override
  State<SensorConfigEditScreen> createState() => _SensorConfigEditScreenState();
}

class _SensorConfigEditScreenState extends State<SensorConfigEditScreen> {
  bool isCelsius = true;

  // Toggle States
  bool doorStatus = false;
  bool smokeStatus = false;
  bool waterStatus = false;

  final Map<String, Map<String, dynamic>> _sensorRows = {};
  final List<String> _sensorIds = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // 1. Initialize Dynamic Sensor Rows (th01, th02...)
    final RegExp regExp = RegExp(r'th(\d+)');
    final Set<String> foundIds = {};

    var sourceData = widget.controller.sensorData.isNotEmpty
        ? widget.controller.sensorData
        : widget.controller.sensorConfigData;

    for (var key in sourceData.keys) {
      final match = regExp.firstMatch(key);
      if (match != null) {
        foundIds.add(match.group(1)!);
      }
    }

    _sensorIds.addAll(foundIds.toList()..sort());

    for (var id in _sensorIds) {
      _sensorRows[id] = {
        "status": "Disable",
        "location": TextEditingController(text: "Level 1"),
        "tempLow": TextEditingController(text: "0"),
        "tempHigh": TextEditingController(text: "40"),
        "humLow": TextEditingController(text: "0"),
        "humHigh": TextEditingController(text: "40"),
      };
    }

    // Initialize switches if needed based on controller data
    // doorStatus = ...
  }

  @override
  void dispose() {
    for (var row in _sensorRows.values) {
      (row['location'] as TextEditingController).dispose();
      (row['tempLow'] as TextEditingController).dispose();
      (row['tempHigh'] as TextEditingController).dispose();
      (row['humLow'] as TextEditingController).dispose();
      (row['humHigh'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isWeb = MediaQuery.of(context).size.width > 900;
    int gridCount = isWeb ? 3 : 1;

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        title: const AppText(
          "Edit Environmental Sensors",
          size: TextSize.title,
          fontWeight: FontWeight.bold,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP TOGGLE ---
            Row(
              children: [
                const AppText(
                  "Temperature measure in : ",
                  size: TextSize.body,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(width: 10),
                const AppText("°C", size: TextSize.body),
                Switch(
                  value: !isCelsius,
                  onChanged: (val) => setState(() => isCelsius = !val),
                  activeColor: AppColors.primaryBlue,
                  inactiveThumbColor: AppColors.primaryBlue,
                  inactiveTrackColor: Colors.white24,
                ),
                const AppText("°F", size: TextSize.body),
              ],
            ),
            const SizedBox(height: 20),

            // --- TABLE CONTAINER ---
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                // color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.panelBorder),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: isWeb ? 1500 : 1200),
                  child: Table(
                    // Outer border
                    border: TableBorder.all(color: Colors.white12),
                    // 5 Columns Structure for perfect merging
                    columnWidths: const {
                      0: FixedColumnWidth(100), // Index
                      1: FixedColumnWidth(140), // Status
                      2: FixedColumnWidth(150), // Location
                      3: FlexColumnWidth(2),    // Temp Group (Double Width)
                      4: FlexColumnWidth(2),    // Hum Group (Double Width)
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      // --- HEADER ROW ---
                      TableRow(

                        children: const [
                          _HeaderCell("Index", height: 80),
                          _HeaderCell("Status", height: 80),
                          _HeaderCell("Sensor Location", height: 80),
                          // Merged Header for Temp
                          _GroupedHeaderCell(
                            title: "Temperature Sensor Threshold (°C)",
                            sub1: "Lower",
                            sub2: "Upper",
                          ),
                          // Merged Header for Humidity
                          _GroupedHeaderCell(
                            title: "Humidity Sensor Threshold (%)",
                            sub1: "Lower",
                            sub2: "Upper",
                          ),
                        ],
                      ),

                      // --- DATA ROWS ---
                      if (_sensorIds.isEmpty)
                        const TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                "No Sensors Found",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            SizedBox(), SizedBox(), SizedBox(), SizedBox(),
                          ],
                        )
                      else
                        ..._sensorIds.map((id) => _buildSensorRow(id)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- BOTTOM SENSORS (EDITABLE) ---
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridCount,
                childAspectRatio: 3.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              children: [
                buildSensorItem(
                  "Door Sensor Status",
                  doorStatus,
                      (v) => setState(() => doorStatus = v),
                ),
                buildSensorItem(
                  "Smoke Sensor Status",
                  smokeStatus,
                      (v) => setState(() => smokeStatus = v),
                ),
                buildSensorItem(
                  "Water Sensor Status",
                  waterStatus,
                      (v) => setState(() => waterStatus = v),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // --- ACTION BUTTONS ---
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: "Cancel",
                    isOutlined: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: "Apply",
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Configuration Updated"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- SENSOR ROW BUILDER ---
  TableRow _buildSensorRow(String id) {
    Map<String, dynamic> rowData = _sensorRows[id]!;
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      children: [
        // Col 1: Index
        Padding(
          padding: const EdgeInsets.all(12),
          child: AppText(
            "Sensor $id",
            size: TextSize.body,
            color: Colors.white70,
            textAlign: TextAlign.center,
          ),
        ),
        // Col 2: Status
        Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: rowData['status'],
                dropdownColor: AppColors.cardSurface,
                style: const TextStyle(color: Colors.white),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                isExpanded: true,
                items:
                ["Enable", "Disable"]
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => rowData['status'] = v!),
              ),
            ),
          ),
        ),
        // Col 3: Location
        tableInputBox(rowData['location']),

        // Col 4: Temp Group (Lower | Upper)
        Row(
          children: [
            Expanded(child: tableInputBox(rowData['tempLow'])),
            Expanded(child: tableInputBox(rowData['tempHigh'])),
          ],
        ),

        // Col 5: Hum Group (Lower | Upper)
        Row(
          children: [
            Expanded(child: tableInputBox(rowData['humLow'])),
            Expanded(child: tableInputBox(rowData['humHigh'])),
          ],
        ),
      ],
    );
  }
}

// --- NEW HEADER CLASSES ---

// 1. Standard Header (Single Column)
class _HeaderCell extends StatelessWidget {
  final String text;
  final double? height;
  const _HeaderCell(this.text, {this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.tableTiltleBg),
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      child: AppText(
        text,
        size: TextSize.subtitle,
        textAlign: TextAlign.center,
        fontWeight: FontWeight.normal,
        overflow: TextOverflow.visible,
      ),
    );
  }
}

// 2. Grouped Header (Merged Title + 2 Subtitles)
class _GroupedHeaderCell extends StatelessWidget {
  final String title;
  final String sub1;
  final String sub2;

  const _GroupedHeaderCell({
    required this.title,
    required this.sub1,
    required this.sub2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80, // Fixed height to match _HeaderCell
      decoration: BoxDecoration(color: AppColors.tableTiltleBg),
      child: Column(
        children: [
          // Main Title
          Expanded(
            flex: 1,
            child: Center(
              child: AppText(
                title,
                size: TextSize.title, // Larger for Main Header
                textAlign: TextAlign.center,
                fontWeight: FontWeight.normal,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          // Sub-Titles Row
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.white12)),
                    ),
                    child: AppText(
                      sub1,
                      size: TextSize.subtitle,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: AppText(
                      sub2,
                      size: TextSize.subtitle,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}