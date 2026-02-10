import 'package:flutter/material.dart';
import 'package:pdu_control_system/Core/constant/appTextWidget.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../Controller/provider/locationControllerProvider.dart';
import '../Core/utils/showToastMsg.dart';
import '../View/rackListScreen.dart';
import '../Core/constant/appColors_constant.dart';
import '../Core/utils/navCard.dart';
import '../Model/locationModel.dart';

class LocationListScreen extends StatelessWidget {
  const LocationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: AppColors.backgroundDeep,
          appBar: AppBar(
            title: AppText(
              "Select Location", size: TextSize.huge,
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
                // Pass Controller to Dialog
                onLongPress: () => _showEditDeleteDialog(context, controller, location),
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
    return const Center(
      child: Text(
        "No locations added yet.\nTap + to add one.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

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
          decoration: const InputDecoration(
            hintText: "Enter location name",
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
              if (nameController.text.trim().isNotEmpty) {
                Provider.of<LocationController>(context, listen: false)
                    .addLocation(nameController.text.trim());
                showToast("Location Added");
                Navigator.pop(ctx);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showEditDeleteDialog(BuildContext context, LocationController controller, Location location) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blueAccent),
            title: const Text("Edit Location Name", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(ctx);
              _showEditLocationDialog(context, controller, location);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.redAccent),
            title: const Text("Delete Location", style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDelete(context, () {
                controller.deleteLocation(location);
                showToast("Location Deleted");
              });
            },
          ),
        ],
      ),
    );
  }

  void _showEditLocationDialog(BuildContext context, LocationController controller, Location location) {
    final nameCtrl = TextEditingController(text: location.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text("Edit Location", style: TextStyle(color: Colors.white)),
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
                controller.updateLocationName(location, nameCtrl.text.trim());
                showToast("Location Updated");
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