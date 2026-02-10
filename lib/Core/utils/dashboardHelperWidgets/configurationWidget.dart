import 'package:flutter/material.dart';
import '../../../Controller/provider/pdu_provider.dart';
import '../../constant/appColors_constant.dart';
import '../../constant/appTextWidget.dart';


class ConfigurationWidget extends StatelessWidget {
  final PduController controller;
  const ConfigurationWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: AppText("DEVICE CONFIGURATION", size: TextSize.small, color: Colors.grey, fontWeight: FontWeight.bold)
        ),
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
              _row("PDU Rating", "${controller.kva} KVA", "Processor", controller.processorType),
              const Divider(color: Colors.white10),
              _row("Location", controller.location, "Outlets", controller.outletsCount),
              const Divider(color: Colors.white10),
              _row("Type", controller.type, "Config", controller.voltageType),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String l1, String v1, String l2, String v2) {
    return Row(
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppText(l1, size: TextSize.small, color: Colors.grey),
          AppText(v1, size: TextSize.subtitle)
        ])),
        Container(width: 1, height: 30, color: Colors.white10),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AppText(l2, size: TextSize.small, color: Colors.grey),
          AppText(v2, size: TextSize.subtitle)
        ])),
      ],
    );
  }
}