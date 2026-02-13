import 'package:flutter/material.dart';

import '../../constant/appColors_constant.dart';

Widget tableInputBox(TextEditingController ctrl) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.backgroundDeep, // Darker background for input
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(bottom: 10), // Center vertically
        ),
      ),
    ),
  );


}
