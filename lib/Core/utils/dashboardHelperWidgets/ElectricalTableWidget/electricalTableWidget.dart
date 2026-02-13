import 'package:flutter/material.dart';
import '../../../../Controller/provider/pdu_provider.dart';
import '../../../constant/appColors_constant.dart';
import '../../../constant/appTextWidget.dart';


class ElectricalTableWidget extends StatelessWidget {
  final PduController controller;
  final bool isDeltaIMIS;

  const ElectricalTableWidget({super.key, required this.controller, required this.isDeltaIMIS});

  @override
  Widget build(BuildContext context) {
    bool isWeb = MediaQuery.of(context).size.width > 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

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
              constraints: BoxConstraints(
                  minWidth: (isWeb && !isDeltaIMIS) ? 1500 : MediaQuery.of(context).size.width - 60
              ),
              child: DataTable(
                headingTextStyle: const TextStyle(color: Colors.grey, fontSize: 11),
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
      ],
    );
  }
}