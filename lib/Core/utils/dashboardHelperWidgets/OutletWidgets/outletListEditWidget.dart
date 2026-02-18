import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../Controller/provider/pdu_provider.dart';
import '../../../../Model/outletModel/outletThresholdModle.dart';
import '../../../constant/appColors_constant.dart';
import '../../widgets/commonAppBar.dart';
import '../../widgets/customButton.dart';
import 'outletSubWidgets/outletLabelTabScreen.dart';
import 'outletSubWidgets/outletSwitchingTabScreen.dart';
import 'outletSubWidgets/outletThresholdTabScreen.dart';



class OutletEditScreen extends StatefulWidget {
  final PduController controller;
  const OutletEditScreen({super.key, required this.controller});

  @override
  State<OutletEditScreen> createState() => _OutletEditScreenState();
}

class _OutletEditScreenState extends State<OutletEditScreen>
    with SingleTickerProviderStateMixin {
  // Add this variable to your state
  bool _isApplying = false;
  late TabController _tabController;
  final PageController _pageController = PageController();

  // --- FORM STATE ---
  final Map<String, TextEditingController> _labelControllers = {};
  final Map<String, String> _initialCleanNames = {};
  final Map<String, bool> _switchStates = {};
  final Map<String, OutletThresholdForm> _thresholdForms = {};


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Sync TabBar and PageView for smooth animation
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    _initializeData();
  }

  void _initializeData() {
    for (var outlet in widget.controller.outlets) {
      String fullId = outlet.id; // e.g. "Outlet 1"
      String numericId = fullId.replaceAll(RegExp(r'[^0-9]'), '');

      // 1. LABELS
      String rawName = widget.controller.outletNamesConfig[numericId] ?? fullId;
      String cleanName = rawName.replaceAll(RegExp(r'\s*\(\d+\)$'), '');
      if (cleanName.toLowerCase().startsWith("outlet ")) {
        cleanName = cleanName.replaceAll(" ", "");
      }
      _labelControllers[fullId] = TextEditingController(text: cleanName);
      _initialCleanNames[fullId] = cleanName;

      // 2. SWITCHING
      _switchStates[fullId] = outlet.isOn;

      // 3. THRESHOLDS
      Map<String, dynamic> tConfig = widget.controller.outletThresholdConfig[numericId] ?? {};
      _thresholdForms[fullId] = OutletThresholdForm(
        status: tConfig['status'] ?? "Disable",
        lowLoad: TextEditingController(text: tConfig['lowLoad']?.toString() ?? "0.00"),
        nearOver: TextEditingController(text: tConfig['nearOverLoad']?.toString() ?? "0.00"),
        overLoad: TextEditingController(text: tConfig['overLoad']?.toString() ?? "0.00"),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    for (var c in _labelControllers.values) {
      c.dispose();
    }
    for (var f in _thresholdForms.values) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: CommonAppBar(
        title: 'Edit Outlets',
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.h),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryBlue,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.h),
            // Custom physics to prevent click-lag
            onTap: (index) {
              _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut
              );
            },
            tabs: const [
              Tab(text: "Label"),
              Tab(text: "Switching"),
              Tab(text: "Threshold"),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1200.w),
                // Using PageView allows for smoother transitions than TabBarView
                // and keeps state alive better
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) => _tabController.animateTo(index),
                  children: [
                    outletLabelTab(
                        outlets: widget.controller.outlets,
                        controllers: _labelControllers
                    ),
                    outletSwitchingTab(
                      outlets: widget.controller.outlets,
                      outletNames: widget.controller.outletNamesConfig,
                      switchStates: _switchStates,
                      onToggleAll: (val) => setState(() {
                        for (var k in _switchStates.keys) {
                          _switchStates[k] = val;
                        }
                      }),
                      onToggleOne: (id, val) => setState(() => _switchStates[id] = val),
                    ),
                    outletThresholdTab(
                      outlets: widget.controller.outlets,
                      forms: _thresholdForms,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomActionButtons(),
        ],
      ),
    );

  }
  Widget _buildBottomActionButtons() {
    return Container(
      padding: EdgeInsets.all(16.r),
      color: AppColors.cardSurface,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1200.w),
          child: Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: "Cancel",
                  isOutlined: true,
                  // FIX 1: Explicitly check state and pass null or function
                  onPressed: _isApplying
                      ? () {} // Pass empty function or modify CustomButton to accept null
                      : () => Navigator.pop(context),
                  // If your CustomButton disables itself when onPressed is null, use this instead:
                  // onPressed: _isApplying ? null : () => Navigator.pop(context),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: CustomButton(
                  text: _isApplying ? "Applying..." : "Apply",
                  // FIX 2: Wrap async function in a sync void callback
                  onPressed: _isApplying
                      ? () {}
                      : () {
                    _handleApply();
                  },
                  // Note: If you want the button to look disabled, you usually pass 'null'.
                  // If your CustomButton supports 'null' for disabling:
                  // onPressed: _isApplying ? null : () { _handleApply(); },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
// ===========================================================================
  //  LOGIC: APPLY CHANGES
  // ===========================================================================

  Future<void> _handleApply() async {
    // Dismiss keyboard if open
    FocusScope.of(context).unfocus();

    int currentTab = _tabController.index;
    if (currentTab == 0) {
      await _applyLabels();
    } else if (currentTab == 1) {
      await _applySwitching();
    } else if (currentTab == 2) {
      await _applyThresholds();
    }
  }

  // ... [Keep _applyLabels and _applyThresholds logic exactly as they were] ...

  Future<void> _callUpdateApi(Future<bool> Function() apiCall) async {
    // 1. START LOADING
    setState(() => _isApplying = true);

    try {
      // 2. EXECUTE API
      bool success = await apiCall();

      if (!mounted) return;

      // 3. HANDLE RESULT
      if (success) {
        Navigator.pop(context);
        _showSnack("Settings Updated Successfully!", isError: false);
      } else {
        _showSnack("Update Failed. Check connection.", isError: true);
      }
    } catch (e) {
      _showSnack("An error occurred: $e", isError: true);
    } finally {
      // 4. STOP LOADING (Always runs, even if error occurs)
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  Future<void> _applyLabels() async {
    final validNameRegExp = RegExp(r'^[a-zA-Z0-9]+$');

    // 1. Validate
    for (var entry in _labelControllers.entries) {
      if (!validNameRegExp.hasMatch(entry.value.text)) {
        _showSnack("Error: Names must be alphanumeric (No spaces).", isError: true);
        return;
      }
    }

    // 2. Build Payload
    Map<String, dynamic> body = {"nameChange": true};
    bool hasChanges = false;

    _labelControllers.forEach((fullId, controller) {
      String currentText = controller.text.trim();
      String initialText = _initialCleanNames[fullId] ?? "";

      if (currentText != initialText) {
        String numericId = fullId.replaceAll(RegExp(r'[^0-9]'), '');
        body[numericId] = {"name": currentText};
        hasChanges = true;
      }
    });

    if (!hasChanges) {
      _showSnack("No changes detected.", isError: false);
      return;
    }

    // 3. API Call
    await _callUpdateApi(() => widget.controller.updateOutletNames(
        username: "admin",
        password: "Admin@123",
        data: body
    ));
  }

  Future<void> _applySwitching() async {
    _showSnack("Switching Update not implemented in backend yet.");
  }

  Future<void> _applyThresholds() async {
    List<Map<String, dynamic>> payload = [];

    _thresholdForms.forEach((fullId, form) {
      String numericId = fullId.replaceAll(RegExp(r'[^0-9]'), '');
      payload.add({
        "outlet": numericId,
        "status": form.status,
        "overLoad": form.overLoad.text,
        "nearOverLoad": form.nearOver.text,
        "lowLoad": form.lowLoad.text,
        "offOnOverLoad": "0"
      });
    });

    await _callUpdateApi(() => widget.controller.updateOutletThresholds(
        username: "admin",
        password: "Admin@123",
        data: payload
    ));
  }


  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}


