import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Controller/provider/locationControllerProvider.dart';
import '../View/rackListScreen.dart';
import '../Core/constant/appColors_constant.dart';
import '../Core/utils/navCard.dart';

class LocationListScreen extends StatelessWidget {
  const LocationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to changes in LocationController
    return Consumer<LocationController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: AppColors.backgroundDeep,
          appBar: AppBar(
            title: Text(
              "Select Location",
              style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.cardSurface,
          ),
          body: controller.locations.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.locations.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final location = controller.locations[i];
              return NavCard(
                title: location.name,
                subtitle: "${location.racks.length} Racks",
                icon: Icons.location_city,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RackListScreen(location: location),
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primaryBlue,
            onPressed: () => _showAddLocationDialog(context),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        "No locations added yet.\nTap + to add one.",
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  // --- DIALOG LOGIC ---
  void _showAddLocationDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text("Add New Location", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter location name (e.g. Server Room B)",
            hintStyle: TextStyle(color: Colors.grey.shade600),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryBlue)),
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
              if (nameController.text.trim().isNotEmpty) {
                // Access the controller and add the location
                Provider.of<LocationController>(context, listen: false)
                    .addLocation(nameController.text.trim());
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