


// ===========================================================================
//  TAB 1: LABELS (Extracted for Performance)
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../constant/appColors_constant.dart';
import '../../../../constant/appTextWidget.dart';

class outletLabelTab extends StatelessWidget {
  final List<dynamic> outlets;
  final Map<String, TextEditingController> controllers;

  const outletLabelTab({required this.outlets, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: outlets.length,
      itemBuilder: (ctx, i) {
        String id = outlets[i].id;
        if (!controllers.containsKey(id)) return const SizedBox();

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.panelBorder),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80.w,
                child: AppText(id, size: TextSize.body, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: TextField(
                  controller: controllers[id],
                  style: TextStyle(color: Colors.white, fontSize: 16.h),
                  decoration: InputDecoration(
                    hintText: "Alphanumeric only",
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 12.sp),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.backgroundDeep,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4.r), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}