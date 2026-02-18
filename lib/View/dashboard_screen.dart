import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../Controller/provider/pdu_provider.dart';
import '../Core/constant/appColors_constant.dart';
import '../Core/constant/appTextWidget.dart';
import '../Core/utils/dashboardHelperWidgets/ConfigurationWidget/configurationEditWidget.dart';
import '../Core/utils/dashboardHelperWidgets/ElectricalTableWidget/electricalThresholdEditScreen.dart';
import '../Core/utils/dashboardHelperWidgets/MCB/alertBannerWidget.dart';
import '../Core/utils/dashboardHelperWidgets/SensorConfigWidgetScreen/sensorConfigEditScreen.dart';
import '../Core/utils/dashboardHelperWidgets/MCB/circuitBreakerGridWidget.dart';
import '../Core/utils/dashboardHelperWidgets/ConfigurationWidget/configurationWidget.dart';
import '../Core/utils/dashboardHelperWidgets/SensorConfigWidgetScreen/sensorGridWidget.dart';
import '../Core/utils/dashboardHelperWidgets/ElectricalTableWidget/electricalTableWidget.dart';
import '../Core/utils/dashboardHelperWidgets/subDashboardWidget/PhaseMetersWidget.dart';
import '../Core/utils/dashboardHelperWidgets/subDashboardWidget/networkStatus.dart';
import '../Core/utils/dashboardHelperWidgets/OutletWidgets/outletListWidget.dart';
import '../Core/utils/showToastMsg.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  // --- STATE ---
  bool _isLoggedIn = false;
  final Box _settingsBox = Hive.box('settings');

  @override
  void initState() {
    super.initState();
    _isLoggedIn = _settingsBox.get('isLoggedIn', defaultValue: false);
  }

  // --- LOGOUT LOGIC ---
  void _handleLogout() {
    setState(() => _isLoggedIn = false);
    _settingsBox.put('isLoggedIn', false);
    showToast("Logged Out");
  }

  // --- LOGIN LOGIC ---
  void _handleLoginSuccess() {
    setState(() => _isLoggedIn = true);
    _settingsBox.put('isLoggedIn', true);
    showToast("Successfully Logged In!");
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider for changes
    final controller = Provider.of<PduController>(context);

    // Calculate derived state once per build
    bool anyMcbTripped = _checkMcbStatus(controller.mcbStatus);
    double maxAmps = double.tryParse(controller.rating) ?? 32.0;
    bool isDeltaIMIS = (controller.type == "IMIS" || controller.type == "IMIS_DELTA") &&
        (controller.voltageType.toUpperCase().contains("DELTA"));

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: _buildAppBar(controller),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !controller.isConnected
          ? buildOffline(context, controller) // Ensure this widget exists or replace with Text
          : _buildSmoothBody(context, controller, anyMcbTripped, maxAmps, isDeltaIMIS),
    );
  }

  /// Optimized Check for MCB Status
  bool _checkMcbStatus(List<Map<String, dynamic>> mcbList) {
    if (mcbList.isEmpty) return false;
    for (var m in mcbList) {
      // Find the entry that looks like "Status" (case insensitive search not needed if keys are consistent)
      for (var entry in m.entries) {
        if (entry.key.contains("Status") && entry.value.toString() == "0") {
          return true;
        }
      }
    }
    return false;
  }

  // ===========================================================================
  //  SMOOTH SCROLL BODY (Using Slivers)
  // ===========================================================================

  Widget _buildSmoothBody(
      BuildContext context,
      PduController controller,
      bool anyMcbTripped,
      double maxAmps,
      bool isDeltaIMIS,
      ) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(), // Adds iOS-style elastic bounce
          slivers: [
            // 1. TOP ALERTS & MCB
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  if (anyMcbTripped) ...[
                    const AlertBannerWidget(message: "CRITICAL: MCB TRIPPED!"),
                    const SizedBox(height: 16),
                  ],
                  if (controller.mcbStatus.isNotEmpty) ...[
                    CircuitBreakerGridWidget(mcbStatus: controller.mcbStatus),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),

            // 2. DEVICE CONFIGURATION
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SectionHeader(
                      title: "DEVICE CONFIGURATION",
                      isLoggedIn: _isLoggedIn,
                      onEditTap: () => _navTo(context, ConfigurationEditScreen(controller: controller)),
                    ),
                    ConfigurationWidget(controller: controller),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // 3. PHASE METERS
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SectionHeader(title: "REAL-TIME PHASE METERS", isLoggedIn: false),
                    // Assuming buildPhaseMeters returns a widget
                    buildPhaseMeters(controller, maxAmps, context, isDeltaIMIS),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // 4. ELECTRICAL TABLE
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SectionHeader(
                      title: "ELECTRICAL PARAMETERS",
                      isLoggedIn: _isLoggedIn,
                      onEditTap: () => _navTo(context, ElectricalThresholdEditScreen(controller: controller)),
                    ),
                    ElectricalTableWidget(controller: controller, isDeltaIMIS: isDeltaIMIS),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // 5. SENSORS (If present)
            if (controller.sensorData.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeader(
                    title: "ENVIRONMENTAL SENSORS",
                    isLoggedIn: _isLoggedIn,
                    onEditTap: () => _navTo(context, SensorConfigEditScreen(controller: controller)),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  // Keeping SensorGrid as a block since it's usually small (4-8 items).
                  // If you have 50+ sensors, convert SensorGridWidget to return a SliverGrid.
                  child: SensorGridWidget(controller: controller),
                ),
              ),
            ],

            // 6. OUTLETS (Heavy List - Handled Seamlessly)
            if (controller.outlets.isNotEmpty) ...[

              // Note: OutletListWidget needs to support "shrinkWrap: true" or be refactored 
              // to be a SliverList for best performance. 
              // For now, wrapping it in SliverToBoxAdapter works if OutletListWidget isn't huge.
              // IF LAG PERSISTS: Refactor OutletListWidget to use SliverList instead of ListView.
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: OutletListWidget(
                    controller: controller,
                    maxAmps: maxAmps,
                    isLoggedIn: _isLoggedIn,
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  void _navTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  // ===========================================================================
  //  APP BAR & LOGIN
  // ===========================================================================

  PreferredSizeWidget _buildAppBar(PduController controller) {
    return AppBar(
      backgroundColor: AppColors.cardSurface,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            controller.pduName != "-" ? controller.pduName : controller.device.name,
            size: TextSize.title,
            fontWeight: FontWeight.bold,
          ),
          AppText(
            "IP: ${controller.device.ip}",
            size: TextSize.small,
            color: Colors.grey,
          ),
        ],
      ),
      actions: [
        // Ensure buildStatusBadge exists or import it
        // buildStatusBadge(controller), 
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: controller.isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4)
            ),
            child: AppText(
              controller.isConnected ? "ONLINE" : "OFFLINE",
              color: controller.isConnected ? Colors.green : Colors.red,
              size: TextSize.small,
            )
        ),

        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: AppColors.cardSurface,
          onSelected: (value) {
            if (value == 'login') _showLoginDialog();
            else if (value == 'logout') _handleLogout();
          },
          itemBuilder: (context) => [
            if (!_isLoggedIn)
              const PopupMenuItem(
                value: 'login',
                child: Row(children: [Icon(Icons.login, color: Colors.white70), SizedBox(width: 10), Text("Login", style: TextStyle(color: Colors.white))]),
              )
            else
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [Icon(Icons.logout, color: Colors.redAccent), SizedBox(width: 10), Text("Logout", style: TextStyle(color: Colors.white))]),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showLoginDialog() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const AppText("Admin Login", size: TextSize.title, fontWeight: FontWeight.bold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Username", labelStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Password", labelStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () {
              if (userCtrl.text == "a" && passCtrl.text == "a") { // Updated creds to match previous context
                Navigator.pop(ctx);
                _handleLoginSuccess();
              } else {
                showToast("Invalid Username or Password");
              }
            },
            child: const Text("Login", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
//  REUSABLE HEADER COMPONENT
// ===========================================================================

class SectionHeader extends StatelessWidget {
  final String title;
  final bool isLoggedIn;
  final VoidCallback? onEditTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.isLoggedIn = false,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(title, size: TextSize.small, color: Colors.grey, fontWeight: FontWeight.bold),
          if (isLoggedIn && onEditTap != null)
            InkWell(
              onTap: onEditTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.edit, color: AppColors.primaryBlue, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}