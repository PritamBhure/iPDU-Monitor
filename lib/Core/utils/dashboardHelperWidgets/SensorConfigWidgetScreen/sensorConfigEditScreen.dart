import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import ScreenUtil
import '../../../../Controller/provider/pdu_provider.dart';
import '../../../constant/appColors_constant.dart';
import '../../../constant/appTextWidget.dart';
import '../../widgets/commonAppBar.dart';
import '../../widgets/customButton.dart';
// Ensure this path matches your project structure

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
    // 1. Get Screen Dimensions
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Determine grid count based on width (Responsive Breakpoint)
    int gridCount = screenWidth > 1200 ? 3 : (screenWidth > 800 ? 2 : 1);

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: CommonAppBar(
        title: 'Edit Configuration',
      ),
      body: Center(
        // 2. Constrain Max Width for Large Laptops
        child: SingleChildScrollView(
          // 3. Responsive Outer Padding
          padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.08, // 2% width padding
              vertical: screenHeight * 0.02   // 2% height padding
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              // --- TOP TOGGLE ---
              Row(
                children: [
                  AppText(
                    "Temperature measure in : ",
                    size: TextSize.body,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(width: 10.w),
                  AppText("°C", size: TextSize.body),
                  Transform.scale(
                    scale: 0.8, // Slightly smaller switch for desktop elegance
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
                    // Outer border
                    border: TableBorder.all(color: Colors.white12),
                    // 5 Columns Structure - Using FixedColumnWidth with .w for scaling
                    columnWidths: {
                      0: FixedColumnWidth(80.w),  // Index
                      1: FixedColumnWidth(120.w), // Status
                      2: FixedColumnWidth(150.w), // Location
                      3: const FlexColumnWidth(2),      // Temp Group
                      4: const FlexColumnWidth(2),      // Hum Group
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      // --- HEADER ROW ---
                      TableRow(
                        children: const [
                          _HeaderCell("Index"),
                          _HeaderCell("Status"),
                          _HeaderCell("Sensor Location"),
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
                        TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(20.r),
                              child: const Text(
                                "No Sensors Found",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(), const SizedBox(), const SizedBox(), const SizedBox(),
                          ],
                        )
                      else
                        ..._sensorIds.map((id) => _buildSensorRow(id)),
                    ],
                  ),
                ),


              // --- TABLE CONTAINER ---
              SizedBox(height: 20.h),

              SizedBox(height: 30.h),

              // --- BOTTOM SENSORS (EDITABLE) ---
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridCount,
                  childAspectRatio: 4.5, // Adjusted for laptop landscape look
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                ),
                children: [
                  // Wrapped in Container to give height control if needed
                  SizedBox(
                    height: 50.h,
                    child: buildSensorItem(
                      "Door Sensor Status",
                      doorStatus,
                          (v) => setState(() => doorStatus = v),
                    ),
                  ),
                  SizedBox(
                    height: 50.h,
                    child: buildSensorItem(
                      "Smoke Sensor Status",
                      smokeStatus,
                          (v) => setState(() => smokeStatus = v),
                    ),
                  ),
                  SizedBox(
                    height: 50.h,
                    child: buildSensorItem(
                      "Water Sensor Status",
                      waterStatus,
                          (v) => setState(() => waterStatus = v),
                    ),
                  ),
                ],
              ),


              // --- ACTION BUTTONS ---
              SizedBox(height: 40.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  // CANCEL BUTTON
                  Expanded(
                    child: CustomButton(
                      text: "Cancel",

                      isOutlined: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  SizedBox(width: 16.w),

                  // APPLY BUTTON
                  Expanded(
                    child: CustomButton(
                      text: "Apply",
                      onPressed: () {
                        // Save Logic...
                        Navigator.pop(context);
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
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
          child: AppText(
            "Sensor $id",
            size: TextSize.body,
            color: Colors.white70,
            textAlign: TextAlign.center,
          ),
        ),
        // Col 2: Status
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
          child: Container(
            height: 40.h, // Fixed height for dropdown
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: rowData['status'],
                dropdownColor: AppColors.cardSurface,
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                isExpanded: true,
                items: ["Enable", "Disable"]
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => rowData['status'] = v!),
              ),
            ),
          ),
        ),
        // Col 3: Location
        Padding(
            padding: EdgeInsets.all(4.r),
            child: tableInputBox(rowData['location'])
        ),

        // Col 4: Temp Group (Lower | Upper)
        Row(
          children: [
            Expanded(child: Padding(padding: EdgeInsets.all(4.r), child: tableInputBox(rowData['tempLow']))),
            Expanded(child: Padding(padding: EdgeInsets.all(4.r), child: tableInputBox(rowData['tempHigh']))),
          ],
        ),

        // Col 5: Hum Group (Lower | Upper)
        Row(
          children: [
            Expanded(child: Padding(padding: EdgeInsets.all(4.r), child: tableInputBox(rowData['humLow']))),
            Expanded(child: Padding(padding: EdgeInsets.all(4.r), child: tableInputBox(rowData['humHigh']))),
          ],
        ),
      ],
    );
  }

  // Helper for bottom sensors if not imported
  Widget buildSensorItem(String title, bool status, Function(bool) onChanged) {
    // Assuming sensorBox or similar widget is used here.
    // Adapting for responsive layout context if necessary.
    // For now, implementing a basic switch row if 'sensorBox' is custom.
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

// --- NEW RESPONSIVE HEADER CLASSES ---

// 1. Standard Header (Single Column)
class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.tableTiltleBg),
      height: 70.h, // Responsive height
      padding: EdgeInsets.symmetric(horizontal: 4.w),
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
      height: 70.h, // Fixed responsive height
      decoration: BoxDecoration(color: AppColors.tableTiltleBg),
      child: Column(
        children: [
          // Main Title
          Expanded(
            flex: 1,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: AppText(
                  title,
                  size: TextSize.subtitle, // Scaled subtitle size
                  textAlign: TextAlign.center,
                  fontWeight: FontWeight.normal,
                  overflow: TextOverflow.ellipsis,
                ),
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
                      size: TextSize.small, // Smaller for sub-header
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: AppText(
                      sub2,
                      size: TextSize.small,
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