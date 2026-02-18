import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Ensure this is imported
import '../../../../Controller/provider/pdu_provider.dart';
import '../../../constant/appColors_constant.dart';
import '../../../constant/appTextWidget.dart';
import '../../widgets/commonAppBar.dart';
import '../../widgets/customButton.dart';

class ConfigurationEditScreen extends StatefulWidget {
  final PduController controller;

  const ConfigurationEditScreen({super.key, required this.controller});

  @override
  State<ConfigurationEditScreen> createState() =>
      _ConfigurationEditScreenState();
}

class _ConfigurationEditScreenState extends State<ConfigurationEditScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.controller.pduName);
    _locationCtrl = TextEditingController(text: widget.controller.location);
    _emailCtrl = TextEditingController(text: widget.controller.email);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Initializing Media Query values for responsive calculations
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: CommonAppBar(
        title: 'Edit Configuration',
      ),
      body: Center(
        // Added Center and ConstrainedBox for Laptop screens
        // so the form doesn't stretch infinitely on a 17-inch wide screen.
        child: Padding(
          // 2. Using MediaQuery for outer padding to breathe based on window size
          padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.1, // 4% of width
              vertical: screenHeight * 0.03   // 3% of height
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- EDIT FORM CONTAINER ---
              Container(
                // Using ScreenUtil for internal padding to maintain element density
                padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 20.h
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.panelBorder),
                ),
                child: Column(
                  children: [
                    _buildTextField("iPDU Name", _nameCtrl, screenHeight),
                    // 3. Using MediaQuery for spacing between fields
                    SizedBox(height: screenHeight * 0.02),

                    _buildTextField("Location", _locationCtrl, screenHeight),
                    SizedBox(height: screenHeight * 0.02),

                    _buildTextField("iPDU Contact Email", _emailCtrl, screenHeight )
                  ],
                ),
              ),
              const Spacer(),

              // --- ACTION BUTTONS ---
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
                  // inside ConfigurationEditScreen.dart -> onPressed

                  Expanded(
                    child: CustomButton(
                      text: "Apply",
                      onPressed: () async {
                        // Assuming you have access to username/password here
                        // Or you can hardcode 'admin'/'Admin' if that is the requirement

                        bool success = await widget.controller.updatePduConfig(
                          newName: _nameCtrl.text,
                          newLocation: _locationCtrl.text,
                          newContact: _emailCtrl.text,
                          username: "admin",
                          password: "Admin@123",
                        );

                        if (!mounted) return;

                        if (success) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Configuration Saved!"), backgroundColor: Colors.green),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Update Failed"), backgroundColor: Colors.red),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              // Bottom safety padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, size: TextSize.small, color: Colors.grey),
        SizedBox(height: 8.h), // ScreenUtil for small consistent gaps
        TextField(
          controller: controller,
          style: TextStyle(color: Colors.white, fontSize: 16.h), // ScreenUtil for font
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.backgroundDeep,
            hoverColor: AppColors.backgroundDeep.withOpacity(0.8),

            // Responsive Content Padding
            contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h // Vertical padding scales with height preference
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.primaryBlue),
            ),
          ),
        ),
      ],
    );
  }
}