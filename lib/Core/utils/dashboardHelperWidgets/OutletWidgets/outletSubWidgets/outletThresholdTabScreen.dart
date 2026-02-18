
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../Model/outletModel/outletThresholdModle.dart';
import '../../../../constant/appColors_constant.dart';
import '../../../../constant/appTextWidget.dart';


// ===========================================================================
//  TAB 3: THRESHOLD (Heavy Widget Optimized)
// ===========================================================================

class outletThresholdTab extends StatefulWidget {
  final List<dynamic> outlets;
  final Map<String, OutletThresholdForm> forms;

  const outletThresholdTab({required this.outlets, required this.forms});

  @override
  State<outletThresholdTab> createState() => _outletThresholdTabState();
}

class _outletThresholdTabState extends State<outletThresholdTab> with AutomaticKeepAliveClientMixin {
  // KeepAlive ensures this heavy tab doesn't rebuild when switching tabs
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for keepAlive
    double screenWidth = MediaQuery.of(context).size.width;
    double minTableWidth = screenWidth > 1400 ? 1100.w : 800.w;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minTableWidth),
          child: Table(
            border: TableBorder.all(color: Colors.white12),
            columnWidths: {
              0: FixedColumnWidth(140.h),
              1: FixedColumnWidth(120.h),
              2: const FlexColumnWidth(1),
              3: const FlexColumnWidth(1),
              4: const FlexColumnWidth(1)
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(decoration: BoxDecoration(color: Colors.white.withOpacity(0.1)), children: [
                _HeaderCell("Outlet"), _HeaderCell("Status"), _HeaderCell("Low Load (A)"), _HeaderCell("Near Over (A)"), _HeaderCell("Over Load (A)")
              ]),
              ...widget.outlets.map((outlet) {
                String id = outlet.id;
                if (!widget.forms.containsKey(id)) return const TableRow(children: [SizedBox(), SizedBox(), SizedBox(), SizedBox(), SizedBox()]);
                var form = widget.forms[id]!;
                return TableRow(
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
                    children: [
                      Padding(padding: EdgeInsets.all(12.r), child: AppText(id, size: TextSize.body, fontWeight: FontWeight.bold, textAlign: TextAlign.center)),
                      // We must use a separate widget for Dropdown to manage setState locally if needed,
                      // or rely on the parent rebuild (here simplified).
                      Padding(
                        padding: EdgeInsets.all(8.r),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: form.status,
                            dropdownColor: AppColors.cardSurface,
                            style: TextStyle(color: Colors.white, fontSize: 14.h),
                            icon: Icon(Icons.arrow_drop_down, color: Colors.white, size: 16.h),
                            isExpanded: true,
                            items: ["Enable", "Disable"].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                            onChanged: (v) {
                              // Note: In a cleaner architecture, this would use a proper provider.
                              // For now, we rely on the fact that the object reference is mutable or trigger rebuild.
                            },
                          ),
                        ),
                      ),
                      _buildTableInput(form.lowLoad),
                      _buildTableInput(form.nearOver),
                      _buildTableInput(form.overLoad),
                    ]
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableInput(TextEditingController ctrl) {
    return Padding(
      padding: EdgeInsets.all(8.r),
      child: TextField(
        controller: ctrl,
        style: TextStyle(color: Colors.white, fontSize: 16.h),
        decoration: InputDecoration(
            isDense: true, filled: true,
            fillColor: AppColors.backgroundDeep,
            hoverColor: AppColors.backgroundDeep.withOpacity(0.8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4.r), borderSide: BorderSide.none)
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      alignment: Alignment.center,
      child: AppText(text, size: TextSize.small, color: Colors.grey, fontWeight: FontWeight.bold, textAlign: TextAlign.center),
    );
  }
}