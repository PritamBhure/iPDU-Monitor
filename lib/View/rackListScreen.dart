// View/rackListScreen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Controller/provider/locationControllerProvider.dart';
import '../View/pduListScreen.dart';
import '../Core/constant/appColors_constant.dart';
import '../Core/utils/navCard.dart';
import '../Model/locationModel.dart';

class RackListScreen extends StatelessWidget {
  final Location location; // We keep this just to know WHICH location we are in
  const RackListScreen({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationController>(
      builder: (context, controller, child) {
        // 1. Get the latest version of this location from the controller
        // (This ensures we see the new rack immediately after adding it)
        final liveLocation = controller.locations.firstWhere(
                (loc) => loc.name == location.name,
            orElse: () => location // Fallback
        );

        return Scaffold(
          backgroundColor: AppColors.backgroundDeep,
          appBar: AppBar(
            title: Text(liveLocation.name, style: GoogleFonts.jetBrainsMono()),
            backgroundColor: AppColors.cardSurface,
          ),
          body: liveLocation.racks.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: liveLocation.racks.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => NavCard(
              title: liveLocation.racks[i].id,
              subtitle: "${liveLocation.racks[i].pdus.length} PDUs",
              icon: Icons.dns,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PduListScreen(rack: liveLocation.racks[i]))
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primaryBlue,
            onPressed: () => _showAddRackDialog(context, controller, liveLocation),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "No racks found.\nTap + to add one.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  // --- ADD RACK DIALOG ---
  void _showAddRackDialog(BuildContext context, LocationController controller, Location liveLocation) {
    final TextEditingController nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text("Add New Rack", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter Rack Name (e.g. Rack-04)",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryBlue)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                // Call the controller method
                controller.addRackToLocation(liveLocation, nameCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}