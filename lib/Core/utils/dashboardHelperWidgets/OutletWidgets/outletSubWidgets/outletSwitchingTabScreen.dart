
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../constant/appColors_constant.dart';
import '../../../../constant/appTextWidget.dart';
import '../../../widgets/customButton.dart';


// ===========================================================================
//  TAB 2: SWITCHING
// ===========================================================================

class outletSwitchingTab extends StatelessWidget {
  final List<dynamic> outlets;
  final Map<String, String> outletNames;
  final Map<String, bool> switchStates;
  final Function(bool) onToggleAll;
  final Function(String, bool) onToggleOne;

  const outletSwitchingTab({
    required this.outlets,
    required this.outletNames,
    required this.switchStates,
    required this.onToggleAll,
    required this.onToggleOne,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.r),
          child: Row(
            children: [
              Expanded(child: CustomButton(text: "Turn ON All", color: AppColors.accentGreen, onPressed: () => onToggleAll(true))),
              SizedBox(width: 16.w),
              Expanded(child: CustomButton(text: "Turn OFF All", color: AppColors.accentRed, onPressed: () => onToggleAll(false))),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: outlets.length,
            itemBuilder: (ctx, i) {
              String id = outlets[i].id;
              bool isOn = switchStates[id] ?? false;
              String numericId = id.replaceAll(RegExp(r'[^0-9]'), '');
              String rawName = outletNames[numericId] ?? id;
              String displayName = rawName.replaceAll(RegExp(r'\s*\(\d+\)$'), '');

              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: isOn ? AppColors.accentGreen.withOpacity(0.5) : AppColors.panelBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Row(children: [
                      Icon(Icons.power_settings_new, color: isOn ? AppColors.accentGreen : Colors.grey, size: 24.sp),
                      SizedBox(width: 12.w),
                      Expanded(child: AppText(displayName, size: TextSize.subtitle, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis)),
                    ])),
                    Switch(
                      value: isOn,
                      activeColor: Colors.white,
                      activeTrackColor: AppColors.accentGreen,
                      inactiveTrackColor: Colors.grey,
                      onChanged: (val) => onToggleOne(id, val),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}