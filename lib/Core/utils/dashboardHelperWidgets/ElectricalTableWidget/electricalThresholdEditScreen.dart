import 'package:flutter/material.dart';

import '../../../../Controller/provider/pdu_provider.dart';
import '../../../constant/appColors_constant.dart';
import '../../../constant/appTextWidget.dart';
import '../../widgets/customButton.dart';
import '../../widgets/tableInputBoxWidget.dart';


class ElectricalThresholdEditScreen extends StatefulWidget {
  final PduController controller;

  const ElectricalThresholdEditScreen({super.key, required this.controller});

  @override
  State<ElectricalThresholdEditScreen> createState() => _ElectricalThresholdEditScreenState();
}

class _ElectricalThresholdEditScreenState extends State<ElectricalThresholdEditScreen> {
  // --- CONTROLLERS GRID ---
  // Rows: 0=Overload, 1=Near Overload, 2=Low Load
  // Cols: 0=Aggregate, 1=L1, 2=L2, 3=L3
  final List<List<TextEditingController>> _controllers = [];

  @override
  void initState() {
    super.initState();
    // Initialize 3 Rows x 4 Columns with dummy or existing data
    // TODO: Connect this to actual data from your controller if available
    for (int i = 0; i < 3; i++) {
      List<TextEditingController> row = [];
      for (int j = 0; j < 4; j++) {
        // Defaulting to "0" or "10" as placeholders like the image
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
    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        title: const AppText("Edit Electrical Thresholds", size: TextSize.title, fontWeight: FontWeight.bold),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.panelBorder),
              ),
              child: Column(
                children: [
                  // --- TABLE STRUCTURE ---
                  Table(
                    border: TableBorder.all(color: Colors.white12), // Grid lines
                    columnWidths: const {
                      0: FlexColumnWidth(1.5), // Header Column is wider
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(1),
                      4: FlexColumnWidth(1),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      // 1. HEADER ROW
                      TableRow(
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05)),
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
            const SizedBox(height: 30),

            // --- BUTTONS ---
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
                      // TODO: Implement Save Logic
                      // Use _controllers[row][col].text to get values
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Thresholds Updated"), backgroundColor: Colors.green),
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

  TableRow _buildInputRow(String label, int rowIndex) {
    return TableRow(
      children: [
        // Label Column
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: AppText(label, size: TextSize.body, fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        // Input Columns
        tableInputBox(_controllers[rowIndex][0]), // Aggregate
        tableInputBox(_controllers[rowIndex][1]), // L1
        tableInputBox(_controllers[rowIndex][2]), // L2
        tableInputBox(_controllers[rowIndex][3]), // L3
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
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}