import 'package:flutter/material.dart';
import '../../../../Controller/provider/pdu_provider.dart';
import '../../../constant/appColors_constant.dart';
import '../../../constant/appTextWidget.dart';
import '../../widgets/customButton.dart';

class OutletEditScreen extends StatefulWidget {
  final PduController controller;
  const OutletEditScreen({super.key, required this.controller});

  @override
  State<OutletEditScreen> createState() => _OutletEditScreenState();
}

class _OutletEditScreenState extends State<OutletEditScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- LOCAL STATE FOR EDITING ---
  // Key = Outlet ID (e.g., "Outlet 1")
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

      // 1. Label Data (Mocking existing label as ID for now)
      _labelControllers[id] = TextEditingController(text: "Server $id");

      // 2. Switching Data
      _switchStates[id] = outlet.isOn;

      // 3. Threshold Data (Mocking defaults)
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
    for (var c in _labelControllers.values) c.dispose();
    for (var data in _thresholdData.values) {
      (data['lowLoad'] as TextEditingController).dispose();
      (data['nearOver'] as TextEditingController).dispose();
      (data['overLoad'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AppText("Edit Outlets", size: TextSize.title, fontWeight: FontWeight.bold),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryBlue,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Outlet Label"),
            Tab(text: "Outlet Switching"),
            Tab(text: "Outlet Threshold"),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLabelTab(),
                _buildSwitchingTab(),
                _buildThresholdTab(),
              ],
            ),
          ),

          // --- BOTTOM ACTIONS ---
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.cardSurface,
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: "Cancel",
                    isOutlined: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: "Apply",
                    onPressed: () {
                      // TODO: Save Logic Here
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Outlet Settings Saved"), backgroundColor: Colors.green),
                      );
                    },
                  ),
                ),
              ],
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
      padding: const EdgeInsets.all(16),
      itemCount: widget.controller.outlets.length,
      itemBuilder: (ctx, i) {
        String id = widget.controller.outlets[i].id;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.panelBorder),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: AppText(id, size: TextSize.body, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: _buildTextField(_labelControllers[id]!),
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: "Turn ON All",
                  color: AppColors.accentGreen,
                  onPressed: () => setState(() {
                    for (var k in _switchStates.keys) _switchStates[k] = true;
                  }),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: "Turn OFF All",
                  color: AppColors.accentRed,
                  onPressed: () => setState(() {
                    for (var k in _switchStates.keys) _switchStates[k] = false;
                  }),
                ),
              ),
            ],
          ),
        ),

        // List of Switches
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.controller.outlets.length,
            itemBuilder: (ctx, i) {
              String id = widget.controller.outlets[i].id;
              bool isOn = _switchStates[id] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isOn ? AppColors.accentGreen.withOpacity(0.5) : AppColors.panelBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.power_settings_new, color: isOn ? AppColors.accentGreen : Colors.grey),
                        const SizedBox(width: 12),
                        AppText(id, size: TextSize.subtitle, fontWeight: FontWeight.bold),
                      ],
                    ),
                    Switch(
                      value: isOn,
                      activeColor: Colors.white,
                      activeTrackColor: AppColors.accentGreen,
                      inactiveTrackColor: Colors.grey,
                      onChanged: (val) => setState(() => _switchStates[id] = val),
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
  Widget _buildThresholdTab() {
    bool isWeb = MediaQuery.of(context).size.width > 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.panelBorder),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: isWeb ? 1500 : 800),
            child: Table(
              border: TableBorder.all(color: Colors.white12),
              columnWidths: const {
                0: FixedColumnWidth(100), // Name
                1: FixedColumnWidth(120), // Status
                2: FlexColumnWidth(1),    // Low
                3: FlexColumnWidth(1),    // Near
                4: FlexColumnWidth(1),    // Over
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1)),
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
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: AppText(id, size: TextSize.body, fontWeight: FontWeight.bold, textAlign: TextAlign.center),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
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
        ),
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildTextField(TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.backgroundDeep,
        hoverColor: AppColors.backgroundDeep.withOpacity(0.8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildTableInput(TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: _buildTextField(ctrl),
    );
  }

  Widget _buildDropdown(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundDeep,
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: data['status'],
          dropdownColor: AppColors.cardSurface,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
          isExpanded: true,
          items: ["Enable", "Disable"].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      alignment: Alignment.center,
      child: AppText(text, size: TextSize.small, color: Colors.grey, fontWeight: FontWeight.bold, textAlign: TextAlign.center),
    );
  }
}