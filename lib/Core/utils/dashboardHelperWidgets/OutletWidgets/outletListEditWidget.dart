import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import ScreenUtil
import '../../../../Controller/provider/pdu_provider.dart';
import '../../../constant/appColors_constant.dart';
import '../../../constant/appTextWidget.dart';
import '../../widgets/commonAppBar.dart';
import '../../widgets/customButton.dart';

class OutletEditScreen extends StatefulWidget {
  final PduController controller;
  const OutletEditScreen({super.key, required this.controller});

  @override
  State<OutletEditScreen> createState() => _OutletEditScreenState();
}

class _OutletEditScreenState extends State<OutletEditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- LOCAL STATE FOR EDITING ---
  final Map<String, TextEditingController> _labelControllers = {};
  final Map<String, bool> _switchStates = {};
  final Map<String, Map<String, dynamic>> _thresholdData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  void _initializeData() {
    for (var outlet in widget.controller.outlets) {
      String id = outlet.id;

      // 1. Label Data
      _labelControllers[id] = TextEditingController(text: "Server $id");

      // 2. Switching Data
      _switchStates[id] = outlet.isOn;

      // 3. Threshold Data
      _thresholdData[id] = {
        "status": "Enable",
        "lowLoad": TextEditingController(text: "0.5"),
        "nearOver": TextEditingController(text: "8.0"),
        "overLoad": TextEditingController(text: "10.0"),
      };
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var c in _labelControllers.values) {
      c.dispose();
    }
    for (var data in _thresholdData.values) {
      (data['lowLoad'] as TextEditingController).dispose();
      (data['nearOver'] as TextEditingController).dispose();
      (data['overLoad'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get Screen Dimensions
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: CommonAppBar(
        title: 'Edit Configuration',
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.h),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryBlue,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.h,overflow: TextOverflow.ellipsis),
            tabs: const [
              Tab(text: "Label"),
              Tab(text: "Switching"),
              Tab(text: "Threshold"),
            ],
          ),
        ),
      ),      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Center(
              // 2. Constrain the body width for large laptops (17")
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1200.w),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLabelTab(),
                    _buildSwitchingTab(),
                    _buildThresholdTab(screenWidth),
                  ],
                ),
              ),
            ),
          ),

          // --- BOTTOM ACTIONS ---
          Container(
            padding: EdgeInsets.all(16.r),
            color: AppColors.cardSurface,
            child: Center(
              // Center actions on large screens too
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1200.w),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: "Cancel",
                        isOutlined: true,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: CustomButton(
                        text: "Apply",
                        onPressed: () {
                          // TODO: Save Logic Here
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Outlet Settings Saved"),
                                backgroundColor: Colors.green),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // ==========================================
  // 1. OUTLET LABEL TAB
  // ==========================================
  Widget _buildLabelTab() {
    return ListView.builder(
      // Responsive Padding
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: widget.controller.outlets.length,
      itemBuilder: (ctx, i) {
        String id = widget.controller.outlets[i].id;
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
              AppText(id,
                  size: TextSize.body,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,

              ),
              SizedBox(width: 16.w),
              Expanded(
                child: buildTextField(_labelControllers[id]!),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // 2. OUTLET SWITCHING TAB
  // ==========================================
  Widget _buildSwitchingTab() {
    return Column(
      children: [
        // Global Controls
        Padding(
          padding: EdgeInsets.all(16.r),
          child: Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: "Turn ON All",
                  color: AppColors.accentGreen,
                  onPressed: () => setState(() {
                    for (var k in _switchStates.keys) {
                      _switchStates[k] = true;
                    }
                  }),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: CustomButton(
                  text: "Turn OFF All",
                  color: AppColors.accentRed,
                  onPressed: () => setState(() {
                    for (var k in _switchStates.keys) {
                      _switchStates[k] = false;
                    }
                  }),
                ),
              ),
            ],
          ),
        ),

        // List of Switches
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: widget.controller.outlets.length,
            itemBuilder: (ctx, i) {
              String id = widget.controller.outlets[i].id;
              bool isOn = _switchStates[id] ?? false;

              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                      color: isOn
                          ? AppColors.accentGreen.withOpacity(0.5)
                          : AppColors.panelBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.power_settings_new,
                            color: isOn ? AppColors.accentGreen : Colors.grey,
                            size: 24.sp),
                        SizedBox(width: 12.w),
                        AppText(id,
                            size: TextSize.subtitle, fontWeight: FontWeight.bold),
                      ],
                    ),
                    Switch(
                      value: isOn,
                      activeColor: Colors.white,
                      activeTrackColor: AppColors.accentGreen,
                      inactiveTrackColor: Colors.grey,
                      onChanged: (val) =>
                          setState(() => _switchStates[id] = val),
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

  // ==========================================
  // 3. OUTLET THRESHOLD TAB
  // ==========================================
  Widget _buildThresholdTab(double screenWidth) {
    // Determine a minimum width for the table so it scrolls on small screens
    // but expands on large ones.
    double minTableWidth = screenWidth > 1400 ? 1100.w : 800.w;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Container(
        width: minTableWidth,
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.panelBorder),
        ),
        child: Table(
          border: TableBorder.all(color: Colors.white12),
          columnWidths: {
            0: FixedColumnWidth(140.h), // Name
            1: FixedColumnWidth(120.h), // Status
            2: const FlexColumnWidth(1),      // Low
            3: const FlexColumnWidth(1),      // Near
            4: const FlexColumnWidth(1),      // Over
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // Header
            TableRow(
              decoration:
              BoxDecoration(color: Colors.white.withOpacity(0.1)),
              children: const [
                _HeaderCell("Outlet"),
                _HeaderCell("Status"),
                _HeaderCell("Low Load (A)"),
                _HeaderCell("Near Over (A)"),
                _HeaderCell("Over Load (A)"),
              ],
            ),
            // Rows
            ...widget.controller.outlets.map((outlet) {
              String id = outlet.id;
              var data = _thresholdData[id]!;

              return TableRow(
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white12))),
                children: [
                  Padding(
                    padding: EdgeInsets.all(12.r),
                    child: AppText(id,
                        size: TextSize.body,
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.center),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.r),
                    child: _buildDropdown(data),
                  ),
                  _buildTableInput(data['lowLoad']),
                  _buildTableInput(data['nearOver']),
                  _buildTableInput(data['overLoad']),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget buildTextField(TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: TextStyle(color: Colors.white, fontSize: 16.h),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.backgroundDeep,
        hoverColor: AppColors.backgroundDeep.withOpacity(0.8),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4.r),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildTableInput(TextEditingController ctrl) {
    return buildTextField(ctrl);
  }

  Widget _buildDropdown(Map<String, dynamic> data) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundDeep,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: data['status'],
          dropdownColor: AppColors.cardSurface,
          style: TextStyle(color: Colors.white, fontSize: 14.h),
          icon: Icon(Icons.arrow_drop_down, color: Colors.white, size: 16.h),
          isExpanded: true,
          items: ["Enable", "Disable"]
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) => setState(() => data['status'] = v!),
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
      child: AppText(text,
          size: TextSize.small,
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          textAlign: TextAlign.center),
    );
  }
}