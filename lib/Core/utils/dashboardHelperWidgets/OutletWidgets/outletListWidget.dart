import 'package:flutter/material.dart';
import 'package:pdu_control_system/Core/utils/dashboardHelperWidgets/subDashboardWidget/PhaseMetersWidget.dart';
import '../../../../Controller/provider/pdu_provider.dart';
import '../../../constant/appColors_constant.dart';
import '../../../constant/appTextWidget.dart';
import 'outletListEditWidget.dart';

class OutletListWidget extends StatefulWidget {
  final PduController controller;
  final double maxAmps;
  final bool isLoggedIn;

  const OutletListWidget({super.key, required this.controller, required this.maxAmps,required this.isLoggedIn});

  @override
  State<OutletListWidget> createState() => _OutletListWidgetState();
}

class _OutletListWidgetState extends State<OutletListWidget> {
  bool _isSearchVisible = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool _isLoggedIn = widget.isLoggedIn;

    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        // --- Header + Search Icon ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AppText("OUTLET LOAD METERS", size: TextSize.small, color: Colors.grey, fontWeight: FontWeight.bold),
            Spacer(),
            IconButton(
              icon: Icon(_isSearchVisible ? Icons.close : Icons.search, color: AppColors.textSecondary),
              onPressed: () {
                setState(() {
                  _isSearchVisible = !_isSearchVisible;
                  if (!_isSearchVisible) {
                    _searchQuery = "";
                    _searchController.clear();
                  }
                });
              },
            ),
            // Inside OutletListWidget.dart
            if (_isLoggedIn)
              InkWell(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OutletEditScreen(controller: widget.controller),
                    ),
                  );
                },
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

        // --- Search Bar ---
        if (_isSearchVisible)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search Outlet (e.g. 1, 24)",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
                filled: true,
                fillColor: AppColors.cardSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

        // --- Filtered Grid/List ---
        Builder(
          builder: (context) {
            final filteredOutlets = widget.controller.outlets.where((outlet) {
              return outlet.id.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();

            if (filteredOutlets.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: AppText("No outlets found", size: TextSize.body, color: Colors.grey)),
              );
            }

            return isWeb
                ? GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, childAspectRatio: 2.5, crossAxisSpacing: 16, mainAxisSpacing: 16),
              itemCount: filteredOutlets.length,
              itemBuilder: (ctx, i) => _buildOutletCard(filteredOutlets[i]),
            )
                : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredOutlets.length,
              separatorBuilder: (c, i) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _buildOutletCard(filteredOutlets[i]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOutletCard(dynamic outlet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.panelBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.power_settings_new, color: outlet.isOn ? AppColors.accentGreen : AppColors.accentRed, size: 24),
                const SizedBox(width: 8),
                AppText(outlet.id, size: TextSize.subtitle, fontWeight: FontWeight.bold)
              ]),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppText(
                    outlet.isOn ? "${outlet.current.toStringAsFixed(2)} A" : "---",
                    size: TextSize.title,
                    fontWeight: FontWeight.bold,
                    color: outlet.isOn ? _getLoadColor(outlet.current, widget.maxAmps / 8) : AppColors.accentRed,
                  ),
                  AppText(
                    outlet.isOn ? "ON" : "OFF",
                    size: TextSize.small,
                    color: outlet.isOn ? AppColors.accentGreen : AppColors.accentRed,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
          Row(children: [
            Expanded(child: progressMetric("VOLTAGE", "${outlet.voltage.toStringAsFixed(1)} V", outlet.voltage, 260.0, Colors.blueAccent)),
            const SizedBox(width: 16),
            Expanded(child: progressMetric("POWER", "${outlet.activePower.toStringAsFixed(2)} kW", outlet.activePower, 4.0, Colors.orangeAccent)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: progressMetric("ENERGY", "${outlet.energy.toStringAsFixed(2)} kWh", outlet.energy, 1000.0, Colors.greenAccent)),
            const SizedBox(width: 16),
            Expanded(child: progressMetric("P.F.", outlet.powerFactor.toStringAsFixed(2), outlet.powerFactor, 1.0, Colors.purpleAccent)),
          ]),
        ],
      ),
    );
  }

  Color _getLoadColor(double val, double max) {
    if (max == 0) return AppColors.accentGreen;
    double pct = val / max;
    if (pct < 0.5) return AppColors.accentGreen;
    if (pct < 0.8) return AppColors.accentOrange;
    return AppColors.accentRed;
  }
}