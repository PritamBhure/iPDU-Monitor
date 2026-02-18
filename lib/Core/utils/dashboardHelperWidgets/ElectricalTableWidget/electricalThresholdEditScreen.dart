import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../Controller/provider/pdu_provider.dart';
import '../../../constant/appColors_constant.dart';
import '../../../constant/appTextWidget.dart';
import '../../widgets/commonAppBar.dart';
import '../../widgets/customButton.dart';
import '../../widgets/tableInputBoxWidget.dart';

class ElectricalThresholdEditScreen extends StatefulWidget {
  final PduController controller;

  const ElectricalThresholdEditScreen({super.key, required this.controller});

  @override
  State<ElectricalThresholdEditScreen> createState() =>
      _ElectricalThresholdEditScreenState();
}

class _ElectricalThresholdEditScreenState
    extends State<ElectricalThresholdEditScreen> {
  // --- CONTROLLERS GRID ---
  // Row 0: Overload, Row 1: Near Overload, Row 2: Low Load
  // Col 0: Aggregate, Col 1: R(L1), Col 2: Y(L2), Col 3: B(L3)
  final List<List<TextEditingController>> _controllers = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // 1. Get the data from controller
    var data = widget.controller.electricalThresholds;

    // Helper to safely get value or default to "0"
    String getVal(String key) => data[key] ?? "0";

    // 2. Initialize 3 Rows x 4 Columns
    // ROW 0: OVERLOAD
    _controllers.add([
      TextEditingController(text: getVal("aggOverloadThreshold")), // Col 0: Agg
      TextEditingController(text: getVal("overLoadThreshold_R")), // Col 1: R
      TextEditingController(text: getVal("overLoadThreshold_Y")), // Col 2: Y
      TextEditingController(text: getVal("overLoadThreshold_B")), // Col 3: B
    ]);

    // ROW 1: NEAR OVERLOAD
    _controllers.add([
      TextEditingController(
        text: getVal("aggNearOverloadThreshold"),
      ), // Col 0: Agg
      TextEditingController(
        text: getVal("nearOverloadThreshold_R"),
      ), // Col 1: R
      TextEditingController(
        text: getVal("nearOverloadThreshold_Y"),
      ), // Col 2: Y
      TextEditingController(
        text: getVal("nearOverloadThreshold_B"),
      ), // Col 3: B
    ]);

    // ROW 2: LOW LOAD
    _controllers.add([
      TextEditingController(text: getVal("aggLowLoadThreshold")), // Col 0: Agg
      TextEditingController(text: getVal("lowLoadThreshold_R")), // Col 1: R
      TextEditingController(text: getVal("lowLoadThreshold_Y")), // Col 2: Y
      TextEditingController(text: getVal("lowLoadThreshold_B")), // Col 3: B
    ]);
  }

  @override
  void dispose() {
    for (var row in _controllers) {
      for (var c in row) c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: CommonAppBar(title: 'Edit Electrical Thresholds'),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1000.w),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenHeight * 0.03,
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.panelBorder),
                  ),
                  child: Column(
                    children: [
                      // --- TABLE STRUCTURE ---
                      Table(
                        border: TableBorder.all(color: Colors.white12),
                        columnWidths: const {
                          0: FlexColumnWidth(1.5),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(1),
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          // 1. HEADER ROW
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                            ),
                            children: const [
                              _HeaderCell("Threshold Level", alignLeft: true),
                              _HeaderCell("Aggregate (A)"),
                              _HeaderCell("L1 (A)"),
                              _HeaderCell("L2 (A)"),
                              _HeaderCell("L3 (A)"),
                            ],
                          ),

                          // 2. DATA ROWS
                          _buildInputRow("Overload Alarm", 0),
                          _buildInputRow("Near Overload Warning", 1),
                          _buildInputRow("Low Load Warning", 2),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30.h),

                // --- BUTTONS ---
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
                          // 1. Prepare Data Map
                          Map<String, String> body = {
                            "phase": "3",

                            // Row 0: Overload
                            "aggOverloadThreshold": _controllers[0][0].text,
                            "overLoadThreshold_R": _controllers[0][1].text,
                            "overLoadThreshold_Y": _controllers[0][2].text,
                            "overLoadThreshold_B": _controllers[0][3].text,

                            // Row 1: Near Overload
                            "aggNearOverloadThreshold": _controllers[1][0].text,
                            "nearOverloadThreshold_R": _controllers[1][1].text,
                            "nearOverloadThreshold_Y": _controllers[1][2].text,
                            "nearOverloadThreshold_B": _controllers[1][3].text,

                            // Row 2: Low Load
                            "aggLowLoadThreshold": _controllers[2][0].text,
                            "lowLoadThreshold_R": _controllers[2][1].text,
                            "lowLoadThreshold_Y": _controllers[2][2].text,
                            "lowLoadThreshold_B": _controllers[2][3].text,
                          };

                          // 2. Call API
                          bool success = await widget.controller
                              .updateElectricalThresholds(
                                username:
                                    "admin", // Replace with actual credentials
                                password:
                                    "Admin", // Replace with actual credentials
                                data: body,
                              );

                          if (!mounted) return;

                          if (success) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Thresholds Updated Successfully!",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Update Failed. Check connection.",
                                ),
                                backgroundColor: Colors.red,
                              ),
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
      ),
    );
  }

  TableRow _buildInputRow(String label, int rowIndex) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: AppText(
            label,
            size: TextSize.body,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        Padding(
          padding: EdgeInsets.all(4.r),
          child: tableInputBox(_controllers[rowIndex][0]),
        ),
        Padding(
          padding: EdgeInsets.all(4.r),
          child: tableInputBox(_controllers[rowIndex][1]),
        ),
        Padding(
          padding: EdgeInsets.all(4.r),
          child: tableInputBox(_controllers[rowIndex][2]),
        ),
        Padding(
          padding: EdgeInsets.all(4.r),
          child: tableInputBox(_controllers[rowIndex][3]),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool alignLeft;
  const _HeaderCell(this.text, {this.alignLeft = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      child: AppText(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        color: Colors.grey,
        size: TextSize.tableHeader,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
