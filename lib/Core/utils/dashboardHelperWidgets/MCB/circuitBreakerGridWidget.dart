import 'package:flutter/material.dart';

import '../../../constant/appTextWidget.dart';
import '../subDashboardWidget/mcbCardWidget.dart';


class CircuitBreakerGridWidget extends StatelessWidget {
  final List<Map<String, dynamic>> mcbStatus;
  const CircuitBreakerGridWidget({super.key, required this.mcbStatus});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int gridCount = screenWidth > 1100 ? 4 : screenWidth > 700 ? 3 : 2;
    double gridRatio = screenWidth > 1100 ? 2.5 : 2.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: AppText("CIRCUIT BREAKERS", size: TextSize.small, color: Colors.grey, fontWeight: FontWeight.bold)
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridCount,
            childAspectRatio: gridRatio,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: mcbStatus.length,
          itemBuilder: (ctx, index) => buildMcbCard(mcbStatus[index]),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}