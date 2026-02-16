import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import ScreenUtil

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
  final List<List<TextEditingController>> _controllers = [];

  @override
  void initState() {
    super.initState();
    // Initialize 3 Rows x 4 Columns
    for (int i = 0; i < 3; i++) {
      List<TextEditingController> row = [];
      for (int j = 0; j < 4; j++) {
        row.add(TextEditingController(text: "0"));
      }
      _controllers.add(row);
    }
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
    // 1. Get Screen Dimensions
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: CommonAppBar(
        title: 'Edit Electrical Thresholds',
      ),
      body: Center(
        // 2. Constrain width for large 17" screens so the table doesn't look stretched
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1000.w),
          child: SingleChildScrollView(
            // 3. Use MediaQuery for outer padding to breathe based on window size
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03, // 3% of width
                vertical: screenHeight * 0.03   // 3% of height
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
                          // Keeping FlexColumnWidth is good for responsiveness
                          0: FlexColumnWidth(1.5),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                          4: FlexColumnWidth(1),
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          // 1. HEADER ROW
                          TableRow(
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05)),
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
                // ScreenUtil for vertical spacing
                SizedBox(height: 30.h),

                // --- BUTTONS ---
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
      ),
    );
  }

  TableRow _buildInputRow(String label, int rowIndex) {
    return TableRow(
      children: [
        // Label Column
        Padding(
          // Using ScreenUtil for internal table cell padding
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: AppText(label,
              size: TextSize.body,
              fontWeight: FontWeight.bold,
              color: Colors.white70),
        ),
        // Input Columns
        // Note: Assuming tableInputBox handles its own responsiveness internally
        // or fits the constraints of the parent TableCell.
        Padding(padding: EdgeInsets.all(4.r), child: tableInputBox(_controllers[rowIndex][0])),
        Padding(padding: EdgeInsets.all(4.r), child: tableInputBox(_controllers[rowIndex][1])),
        Padding(padding: EdgeInsets.all(4.r), child: tableInputBox(_controllers[rowIndex][2])),
        Padding(padding: EdgeInsets.all(4.r), child: tableInputBox(_controllers[rowIndex][3])),
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
      // Responsive padding for the header
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      child: AppText(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
            color: Colors.grey,
            size:TextSize.tableHeader , // Responsive font size
            fontWeight: FontWeight.bold),
    );
  }
}