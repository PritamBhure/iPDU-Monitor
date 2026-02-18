import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../Controller/provider/pdu_provider.dart';
import '../../../constant/appColors_constant.dart';
import '../../../constant/appTextWidget.dart';
import '../../widgets/commonAppBar.dart';
import '../../widgets/customButton.dart';
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

  // ---------------------------------------------------------------------------
  //  UPDATED INITIALIZATION LOGIC
  // ---------------------------------------------------------------------------
  void _initializeData() {
    var config = widget.controller.sensorConfigData;
    log("Loading Config Data: $config");

    // 1. Initialize Global Switches
    doorStatus = (config['doorSensorStatus']?.toString() == "1") || (config['doorStatus']?.toString() == "1");
    smokeStatus = (config['smokeSensorStatus']?.toString() == "1") || (config['smokeStatus']?.toString() == "1");
    waterStatus = (config['waterSensorStatus']?.toString() == "1") || (config['waterStatus']?.toString() == "1");

    // Initialize Temp Measure
    if (config['tempMeasure'] != null) {
      isCelsius = config['tempMeasure'].toString().toUpperCase() == "C";
    }

    // 2. Find Sensor IDs
    final RegExp regExp = RegExp(r'th(\d+)');
    final Set<String> foundIds = {};

    var sourceData = widget.controller.sensorData.isNotEmpty
        ? widget.controller.sensorData
        : widget.controller.sensorConfigData;

    for (var key in sourceData.keys) {
      final match = regExp.firstMatch(key);
      if (match != null) {
        foundIds.add(match.group(1)!); // Adds "01", "02"
      }
    }

    _sensorIds.addAll(foundIds.toList()..sort());

    // 3. Populate Rows using Keys from LOG
    for (var idStr in _sensorIds) {
      // Use the string directly ("01") to match keys like "th01..."
      String prefix = "th$idStr";

      // Helper to safely get string or default
      String getVal(String key, String def) => config[key]?.toString() ?? def;

      _sensorRows[idStr] = {
        // Status: Check "th01status"
        "status": (getVal("${prefix}status", "0") == "1") ? "Enable" : "Disable",

        // Location: "th01location"
        "location": TextEditingController(text: getVal("${prefix}location", "Level 1")),

        // Thresholds: Match the LOG keys exactly
        // "th01tempLowThreshold", "th01tempUpperThreshold"
        "tempLow": TextEditingController(text: getVal("${prefix}tempLowThreshold", "0")),
        "tempHigh": TextEditingController(text: getVal("${prefix}tempUpperThreshold", "40")),

        // "th01humidityLowThreshold", "th01humidityUpperThreshold"
        "humLow": TextEditingController(text: getVal("${prefix}humidityLowThreshold", "0")),
        "humHigh": TextEditingController(text: getVal("${prefix}humidityUpperThreshold", "40")),
      };
    }
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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    int gridCount = screenWidth > 1200 ? 3 : (screenWidth > 800 ? 2 : 1);

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: CommonAppBar(title: 'Edit Configuration'),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.08, vertical: screenHeight * 0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              // --- TOP TOGGLE ---
              Row(
                children: [
                  AppText("Temperature measure in : ", size: TextSize.body, fontWeight: FontWeight.bold),
                  SizedBox(width: 10.w),
                  AppText("°C", size: TextSize.body),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: !isCelsius,
                      onChanged: (val) => setState(() => isCelsius = !val),
                      activeColor: AppColors.primaryBlue,
                      inactiveThumbColor: AppColors.primaryBlue,
                      inactiveTrackColor: Colors.white24,
                    ),
                  ),
                  AppText("°F", size: TextSize.body),
                ],
              ),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.panelBorder),
                ),
                child: Table(
                  border: TableBorder.all(color: Colors.white12),
                  columnWidths: {
                    0: FixedColumnWidth(80.w),
                    1: FixedColumnWidth(120.w),
                    2: FixedColumnWidth(150.w),
                    3: const FlexColumnWidth(2),
                    4: const FlexColumnWidth(2),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      children: const [
                        _HeaderCell("Index"),
                        _HeaderCell("Status"),
                        _HeaderCell("Sensor Location"),
                        _GroupedHeaderCell(title: "Temperature Sensor Threshold (°C)", sub1: "Lower", sub2: "Upper"),
                        _GroupedHeaderCell(title: "Humidity Sensor Threshold (%)", sub1: "Lower", sub2: "Upper"),
                      ],
                    ),

                    if (_sensorIds.isEmpty)
                      const TableRow(children: [SizedBox(),SizedBox(),SizedBox(),SizedBox(),SizedBox()])
                    else
                      ..._sensorIds.map((id) => _buildSensorRow(id)),
                  ],
                ),
              ),

              SizedBox(height: 50.h),

              // --- GLOBAL SENSORS GRID ---
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridCount,
                  childAspectRatio: 4.5,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                ),
                children: [
                  SizedBox(height: 50.h, child: buildSensorItem("Door Sensor Status", doorStatus, (v) => setState(() => doorStatus = v))),
                  SizedBox(height: 50.h, child: buildSensorItem("Smoke Sensor Status", smokeStatus, (v) => setState(() => smokeStatus = v))),
                  SizedBox(height: 50.h, child: buildSensorItem("Water Sensor Status", waterStatus, (v) => setState(() => waterStatus = v))),
                ],
              ),

              SizedBox(height: 40.h),

              // --- ACTION BUTTONS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: CustomButton(
                      text: "Cancel",
                      isOutlined: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: CustomButton(
                      text: "Apply",
                      onPressed: () async {
                        // 1. CONSTRUCT API BODY
                        Map<String, String> body = {};

                        // Global
                        body["doorSensorStatus"] = doorStatus ? "1" : "0";
                        body["smokeSensorStatus"] = smokeStatus ? "1" : "0";
                        body["waterSensorStatus"] = waterStatus ? "1" : "0";
                        // body["tempMeasure"] = isCelsius ? "C" : "F"; // Optional

                        // Sensors
                        for (String idString in _sensorIds) {
                          int id = int.parse(idString);
                          String prefix = "th$id";

                          var row = _sensorRows[idString]!;

                          body["${prefix}s"] = (row['status'] == "Enable") ? "1" : "0";
                          body["${prefix}0location"] = row['location'].text;
                          body["${prefix}tLow"] = row['tempLow'].text;
                          body["${prefix}tUp"] = row['tempHigh'].text;
                          body["${prefix}hLow"] = row['humLow'].text;
                          body["${prefix}hUp"] = row['humHigh'].text;
                        }

                        // 2. CALL API
                        bool success = await widget.controller.updateSensorConfiguration(
                          username: "admin",
                          password: "Admin@123",
                          data: body,
                        );

                        if (!mounted) return;

                        if (success) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Sensors Updated Successfully!"), backgroundColor: Colors.green),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Update Failed."), backgroundColor: Colors.red),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SENSOR ROW BUILDER (Same as before) ---
  TableRow _buildSensorRow(String id) {
    Map<String, dynamic> rowData = _sensorRows[id]!;
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
          child: AppText("Sensor $id", size: TextSize.body, color: Colors.white70, textAlign: TextAlign.center),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
          child: Container(
            height: 40.h,
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.primaryBlue, width: 2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: rowData['status'],
                dropdownColor: AppColors.cardSurface,
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                isExpanded: true,
                items: ["Enable", "Disable"].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => setState(() => rowData['status'] = v!),
              ),
            ),
          ),
        ),
        Padding(padding: EdgeInsets.all(4.r), child: tableInputBox(rowData['location'])),
        Row(children: [
          Expanded(child: Padding(padding: EdgeInsets.all(4.r), child: tableInputBox(rowData['tempLow']))),
          Expanded(child: Padding(padding: EdgeInsets.all(4.r), child: tableInputBox(rowData['tempHigh']))),
        ]),
        Row(children: [
          Expanded(child: Padding(padding: EdgeInsets.all(4.r), child: tableInputBox(rowData['humLow']))),
          Expanded(child: Padding(padding: EdgeInsets.all(4.r), child: tableInputBox(rowData['humHigh']))),
        ]),
      ],
    );
  }

  Widget buildSensorItem(String title, bool status, Function(bool) onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.panelBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(title, size: TextSize.body, color: Colors.white),
          Switch(
            value: status,
            onChanged: onChanged,
            activeColor: AppColors.primaryBlue,
          )
        ],
      ),
    );
  }
}

// ... Header Classes (Keep them as they were) ...
class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.tableTiltleBg),
      height: 70.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      alignment: Alignment.center,
      child: AppText(text, size: TextSize.subtitle, textAlign: TextAlign.center, fontWeight: FontWeight.normal),
    );
  }
}

class _GroupedHeaderCell extends StatelessWidget {
  final String title;
  final String sub1;
  final String sub2;
  const _GroupedHeaderCell({required this.title, required this.sub1, required this.sub2});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(color: AppColors.tableTiltleBg),
      child: Column(
        children: [
          Expanded(flex: 1, child: Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 4.w), child: AppText(title, size: TextSize.subtitle, textAlign: TextAlign.center, fontWeight: FontWeight.normal, overflow: TextOverflow.ellipsis)))),
          const Divider(height: 1, color: Colors.white12),
          Expanded(flex: 1, child: Row(children: [
            Expanded(child: Container(alignment: Alignment.center, decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.white12))), child: AppText(sub1, size: TextSize.small, fontWeight: FontWeight.normal))),
            Expanded(child: Center(child: AppText(sub2, size: TextSize.small, fontWeight: FontWeight.normal))),
          ])),
        ],
      ),
    );
  }
}