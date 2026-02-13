import 'package:flutter/material.dart';
import '../../../../Controller/provider/pdu_provider.dart';
import '../../../constant/appColors_constant.dart';
import '../../../constant/appTextWidget.dart';
import '../../widgets/customButton.dart';


class ConfigurationEditScreen extends StatefulWidget {
  final PduController controller;

  const ConfigurationEditScreen({super.key, required this.controller});

  @override
  State<ConfigurationEditScreen> createState() => _ConfigurationEditScreenState();
}

class _ConfigurationEditScreenState extends State<ConfigurationEditScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    // Initialize with current values
    _nameCtrl = TextEditingController(text: widget.controller.pduName);
    _locationCtrl = TextEditingController(text: widget.controller.location);
    // Assuming email might not be in controller yet, defaulting to empty or existing
    _emailCtrl = TextEditingController(text: "");
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
    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        title: const AppText("Edit Configuration", size: TextSize.title, fontWeight: FontWeight.bold),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- EDIT FORM CONTAINER ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.panelBorder),
              ),
              child: Column(
                children: [
                  _buildTextField("iPDU Name", _nameCtrl),
                  const SizedBox(height: 16),
                  _buildTextField("Location", _locationCtrl),
                  const SizedBox(height: 16),
                  _buildTextField("iPDU Contact Email", _emailCtrl),
                ],
              ),
            ),
            const Spacer(),

            // --- ACTION BUTTONS ---
            // ... inside your Row or Column

            Row(
              children: [
                // CANCEL BUTTON (Outlined)
                Expanded(
                  child: CustomButton(
                    text: "Cancel",
                    isOutlined: true, // <--- Switches to Outlined Style
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(width: 16),

                // APPLY BUTTON (Filled/Default)
                Expanded(
                  child: CustomButton(
                    text: "Apply",
                    // isOutlined: false, (Default)
                    onPressed: () {
                      // Save Logic...
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, size: TextSize.small, color: Colors.grey),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.backgroundDeep,

            // --- FIX: Explicitly set hover color ---
            // Use a slightly lighter version of your background or a distinct color
            hoverColor: AppColors.backgroundDeep.withOpacity(0.8),

            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),

            // Ensure the border stays visible on hover if you want
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none, // Or const BorderSide(color: Colors.white12)
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryBlue),
            ),
          ),
        ),
      ],
    );
  }}