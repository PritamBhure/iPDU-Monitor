import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constant/appColors_constant.dart';
import '../../constant/appTextWidget.dart';


class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom; // For TabBars
  final List<Widget>? actions;       // For extra buttons

  const CommonAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.bottom,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    var screenheight = MediaQuery.of(context).size.height;

    return AppBar(
      backgroundColor: AppColors.cardSurface,
      centerTitle: false, // Aligns left like your designs
      elevation: 0,

      title: AppText(
        title,
        size: TextSize.title,
        fontWeight: FontWeight.bold,
      ),

      leading: IconButton(
        // Responsive Icon Size
        icon: Icon(Icons.arrow_back, color: Colors.white, size:screenheight * 0.03 ),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
      ),

      bottom: bottom,
      actions: actions,
    );
  }

  @override
  // Automatically calculates height based on whether a TabBar (bottom) is present
  Size get preferredSize => Size.fromHeight(
      kToolbarHeight + (bottom?.preferredSize.height ?? 0.0)
  );
}