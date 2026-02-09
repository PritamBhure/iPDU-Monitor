import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../Controller/provider/locationControllerProvider.dart';
import '../Core/utils/showToastMsg.dart';
import '../View/pduListScreen.dart';
import '../Core/constant/appColors_constant.dart';
import '../Core/utils/navCard.dart';
import '../Model/locationModel.dart';
import '../Model/rackModel.dart';

class RackListScreen extends StatelessWidget {
  final Location location;
  const RackListScreen({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationController>(
      builder: (context, controller, child) {
        // Find live data to ensure updates show immediately
        // Uses "orElse" to return the passed location if not found (prevents crashes during deletion)
        final liveLocation = controller.locations.firstWhere(
              (loc) => loc.name == location.name,
          orElse: () => location,
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
            itemBuilder: (ctx, i) {
              final rack = liveLocation.racks[i];
              return NavCard(
                title: rack.id,
                subtitle: "${rack.pdus.length} PDUs",
                icon: Icons.dns,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PduListScreen(
                      rack: rack,
                      location: liveLocation,
                    ),
                  ),
                ),
                // Long Press to trigger Edit/Delete Rack
                onLongPress: () => _showEditDeleteDialog(context, controller, liveLocation, rack),
              );
            },
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

  // --- ADD RACK ---
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                controller.addRackToLocation(liveLocation, nameCtrl.text.trim());
                showToast("Rack Added");
                Navigator.pop(ctx);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // --- MENU ---
  void _showEditDeleteDialog(BuildContext context, LocationController controller, Location location, Rack rack) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blueAccent),
            title: const Text("Edit Rack Name", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(ctx);
              _showEditRackDialog(context, controller, location, rack);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.redAccent),
            title: const Text("Delete Rack", style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDelete(context, () {
                // CALL CONTROLLER
                controller.deleteRack(location, rack);
                showToast("Rack Deleted");
              });
            },
          ),
        ],
      ),
    );
  }

  // --- EDIT DIALOG ---
  void _showEditRackDialog(BuildContext context, LocationController controller, Location location, Rack rack) {
    final nameCtrl = TextEditingController(text: rack.id);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text("Edit Rack", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "New Name", hintStyle: TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                // CALL CONTROLLER METHOD
                controller.updateRackName(location, rack, nameCtrl.text.trim());
                showToast("Rack Updated");
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text("Confirm Delete", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure? This action cannot be undone.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

}