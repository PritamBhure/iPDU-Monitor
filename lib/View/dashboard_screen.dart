import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart'; // 1. Import Hive

import '../Controller/provider/pdu_provider.dart';
import '../Core/constant/appColors_constant.dart';
import '../Core/constant/appTextWidget.dart';
import '../Core/utils/dashboardHelperWidgets/ConfigurationWidget/configurationEditWidget.dart';
import '../Core/utils/dashboardHelperWidgets/ElectricalTableWidget/electricalThresholdEditScreen.dart';
import '../Core/utils/dashboardHelperWidgets/SensorConfigWidgetScreen/sensorConfigEditScreen.dart';
import '../Core/utils/dashboardHelperWidgets/alertBannerWidget.dart';
import '../Core/utils/dashboardHelperWidgets/circuitBreakerGridWidget.dart';
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
  // --- STATE: TRACK LOGIN STATUS ---
  bool _isLoggedIn = false;

  // 2. Reference to the Hive Box
  final Box _settingsBox = Hive.box('settings');

  @override
  void initState() {
    super.initState();
    // 3. Load Saved Login Status on Startup
    _isLoggedIn = _settingsBox.get('isLoggedIn', defaultValue: false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<PduController>(context);

    // Global Logic: Check for Alerts
    bool anyMcbTripped = controller.mcbStatus.any((m) {
      var entry = m.entries.firstWhere(
            (e) => e.key.contains("Status"),
        orElse: () => const MapEntry("", "1"),
      );
      return entry.value.toString() == "0";
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: _buildAppBar(controller),
      body:
      controller.isLoading
          ? buildLoading()
          : !controller.isConnected
          ? buildOffline(context, controller)
          : _buildBody(context, controller, anyMcbTripped),
    );
  }

  PreferredSizeWidget _buildAppBar(PduController controller) {
    return AppBar(
      backgroundColor: AppColors.cardSurface,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            controller.pduName != "-"
                ? controller.pduName
                : controller.device.name,
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
        buildStatusBadge(controller),

        // --- UPDATED POPUP MENU (Login/Logout) ---
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: AppColors.cardSurface,
          onSelected: (value) {
            if (value == 'login') {
              _showLoginDialog();
            } else if (value == 'logout') {
              setState(() {
                _isLoggedIn = false;
              });
              // 4. Save Logout State
              _settingsBox.put('isLoggedIn', false);

              showToast("Logged Out");
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              if (!_isLoggedIn)
                const PopupMenuItem<String>(
                  value: 'login',
                  child: Row(
                    children: [
                      Icon(Icons.login, color: Colors.white70),
                      SizedBox(width: 10),
                      AppText(
                        "Login",
                        size: TextSize.body,
                        color: Colors.white,
                      ),
                    ],
                  ),
                )
              else
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.redAccent),
                      SizedBox(width: 10),
                      AppText(
                        "Logout",
                        size: TextSize.body,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
            ];
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showLoginDialog() {
    final TextEditingController userCtrl = TextEditingController();
    final TextEditingController passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const AppText(
          "Admin Login",
          size: TextSize.title,
          fontWeight: FontWeight.bold,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Username",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Password",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            onPressed: () {
              if (userCtrl.text == "a" && passCtrl.text == "a") {
                Navigator.pop(ctx);

                // --- UPDATE STATE ON SUCCESS ---
                setState(() {
                  _isLoggedIn = true;
                });

                // 5. Save Login State
                _settingsBox.put('isLoggedIn', true);

                showToast("Successfully Logged In!");

              } else {
                showToast("Invalid Username or Password");

              }
            },
            child: const Text(
              "Login",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context,
      PduController controller,
      bool anyMcbTripped,
      ) {
    double maxAmps = double.tryParse(controller.rating) ?? 32.0;
    bool isDeltaIMIS =
        (controller.type == "IMIS" || controller.type == "IMIS_DELTA") &&
            (controller.voltageType.toUpperCase().contains("DELTA"));

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (anyMcbTripped)
                AlertBannerWidget(message: "CRITICAL: MCB TRIPPED!"),

              if (controller.mcbStatus.isNotEmpty)
                CircuitBreakerGridWidget(mcbStatus: controller.mcbStatus),

              // --- 1. Config Header with Edit ---
              SectionHeader(
                title: "DEVICE CONFIGURATION",
                isLoggedIn: _isLoggedIn,
                onEditTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                          ConfigurationEditScreen(controller: controller),
                    ),
                  );
                },
              ),
              ConfigurationWidget(controller: controller),
              const SizedBox(height: 24),

              // --- 2. Phase Meters Header with Edit ---
              SectionHeader(title: "REAL-TIME PHASE METERS", isLoggedIn: false),
              buildPhaseMeters(controller, maxAmps, context, isDeltaIMIS),
              const SizedBox(height: 24),

              // --- 3. Electrical Table Header ---
              SectionHeader(
                title: "ELECTRICAL PARAMETERS",
                isLoggedIn: _isLoggedIn,
                onEditTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ElectricalThresholdEditScreen(
                        controller: controller,
                      ),
                    ),
                  );
                },
              ),
              ElectricalTableWidget(
                controller: controller,
                isDeltaIMIS: isDeltaIMIS,
              ),
              const SizedBox(height: 24),

              // --- 4. Sensors Header with Edit ---
              if (controller.sensorData.isNotEmpty) ...[
                SectionHeader(
                  title: "ENVIRONMENTAL SENSORS",
                  isLoggedIn: _isLoggedIn,
                  onEditTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                            SensorConfigEditScreen(controller: controller),
                      ),
                    );
                  },
                ),
                SensorGridWidget(controller: controller),
              ],

              // --- 5. Outlet Header with Edit ---
              if (controller.outlets.isNotEmpty) ...[
                // Note: Ensure your OutletListWidget accepts the 'isLoggedIn' parameter
                OutletListWidget(
                  controller: controller,
                  maxAmps: maxAmps,
                  isLoggedIn: _isLoggedIn,
                  // isLoggedIn: _isLoggedIn // Uncomment if you updated OutletListWidget
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// --- HELPER FOR HEADERS ---
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            title,
            size: TextSize.small,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
          if (isLoggedIn)
            InkWell(
              onTap: onEditTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit,
                  color: AppColors.primaryBlue,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}