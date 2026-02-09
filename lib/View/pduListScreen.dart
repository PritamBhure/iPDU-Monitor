import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Controller/provider/pdu_provider.dart';
import '../Controller/provider/locationControllerProvider.dart';
import '../Core/constant/appColors_constant.dart';
import '../Core/constant/appTextWidget.dart';
import '../Core/utils/navCard.dart';
import '../Core/utils/showToastMsg.dart';
import '../Model/pdu_model.dart';
import '../Model/rackModel.dart';
import '../Model/locationModel.dart';
import 'dashboard_screen.dart';

class PduListScreen extends StatelessWidget {
  final Rack rack;
  final Location location;

  const PduListScreen({super.key, required this.rack, required this.location});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationController>(
      builder: (context, locController, child) {
        // Get Live Data
        final liveLoc = locController.locations.firstWhere(
          (l) => l.name == location.name,
          orElse: () => location,
        );
        final liveRack = liveLoc.racks.firstWhere(
          (r) => r.id == rack.id,
          orElse: () => rack,
        );

        return Scaffold(
          backgroundColor: AppColors.backgroundDeep,
          appBar: AppBar(
            title: Text(liveRack.id, style: GoogleFonts.jetBrainsMono()),
            backgroundColor: AppColors.cardSurface,
          ),
          body:
              liveRack.pdus.isEmpty
                  ? const Center(
                    child: Text(
                      "No PDUs found. Tap + to add.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                  : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: liveRack.pdus.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final pdu = liveRack.pdus[i];
                      return NavCard(
                        title: pdu.name,
                        subtitle:
                            "${pdu.type.name.split('.').last} | ${pdu.phase.name.split('.').last}",
                        icon: Icons.power,
                        trailing: const Text(
                          "CONNECT",
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => _showConnectionDialog(context, pdu),
                        // Long Press to Edit/Delete
                        onLongPress:
                            () => _showEditDeleteDialog(
                              context,
                              locController,
                              liveLoc,
                              liveRack,
                              pdu,
                            ),
                      );
                    },
                  ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primaryBlue,
            onPressed:
                () => _showAddPduDialog(
                  context,
                  locController,
                  liveLoc,
                  liveRack,
                ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  // --- ACTIONS: EDIT / DELETE MENU ---
  void _showEditDeleteDialog(
    BuildContext context,
    LocationController controller,
    Location location,
    Rack rack,
    PduDevice pdu,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      builder:
          (ctx) => Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blueAccent),
                title: const Text(
                  "Edit PDU Details",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditPduDialog(context, controller, location, rack, pdu);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text(
                  "Delete PDU",
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, () {
                    controller.deletePdu(location, rack, pdu);
                    showToast("PDU Deleted");
                  });
                },
              ),
            ],
          ),
    );
  }

  // --- EDIT PDU DIALOG WITH VALIDATION ---
  void _showEditPduDialog(
      BuildContext context,
      LocationController controller,
      Location loc,
      Rack rack,
      PduDevice pdu,
      ) {
    final nameCtrl = TextEditingController(text: pdu.name);
    final ipCtrl = TextEditingController(text: pdu.ip);
    final idCtrl = TextEditingController(text: pdu.id);

    PduType selectedType = pdu.type;
    PhaseType selectedPhase = pdu.phase;

    // Error state variables
    String? nameError;
    String? ipError;

    // Helper function to validate IP Address
    bool isValidIp(String ip) {
      final RegExp ipRegex = RegExp(
        r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
      );
      return ipRegex.hasMatch(ip);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.cardSurface,
            title: const AppText("Edit PDU", size: TextSize.title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(idCtrl, "PDU ID"),
                  const SizedBox(height: 10),

                  // Name Field with Error
                  _buildTextField(
                      nameCtrl,
                      "Name",
                      errorText: nameError
                  ),
                  const SizedBox(height: 10),

                  // IP Field with Error
                  _buildTextField(
                      ipCtrl,
                      "IP Address",
                      errorText: ipError
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown<PduType>(
                    "PDU Type",
                    selectedType,
                    PduType.values,
                        (val) => setState(() => selectedType = val!),
                  ),
                  const SizedBox(height: 10),
                  _buildDropdown<PhaseType>(
                    "Phase Config",
                    selectedPhase,
                    PhaseType.values,
                        (val) => setState(() => selectedPhase = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                onPressed: () {
                  // --- VALIDATION LOGIC ---
                  setState(() {
                    // Reset errors
                    nameError = null;
                    ipError = null;
                    bool isValid = true;

                    // Validate Name
                    if (nameCtrl.text.trim().isEmpty) {
                      nameError = "Name cannot be empty";
                      isValid = false;
                    }

                    // Validate IP
                    if (ipCtrl.text.trim().isEmpty) {
                      ipError = "IP Address cannot be empty";
                      isValid = false;
                    } else if (!isValidIp(ipCtrl.text.trim())) {
                      ipError = "Invalid IP Format";
                      isValid = false;
                    }

                    // Proceed if Valid
                    if (isValid) {
                      final newPdu = PduDevice(
                        id: idCtrl.text,
                        name: nameCtrl.text.trim(),
                        ip: ipCtrl.text.trim(),
                        type: selectedType,
                        phase: selectedPhase,
                      );

                      controller.updatePduDetails(loc, rack, pdu, newPdu);
                      showToast("PDU Updated"); // Ensure showToast is defined or use Fluttertoast directly
                      Navigator.pop(ctx);
                    }
                  });
                },
                child: const Text("Save", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

// --- ADD PDU DIALOG WITH VALIDATION ---
  void _showAddPduDialog(
      BuildContext context,
      LocationController controller,
      Location loc,
      Rack rack,
      ) {
    final nameCtrl = TextEditingController();
    final ipCtrl = TextEditingController();
    final idCtrl = TextEditingController(text: "PDU-${rack.pdus.length + 1}");

    PduType selectedType = PduType.IMIS;
    PhaseType selectedPhase = PhaseType.ThreePhaseStar;

    // Error state variables
    String? nameError;
    String? ipError;

    // Helper function to validate IP Address
    bool isValidIp(String ip) {
      final RegExp ipRegex = RegExp(
        r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
      );
      return ipRegex.hasMatch(ip);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.cardSurface,
            title: const AppText("Add New PDU", size: TextSize.title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(idCtrl, "PDU ID (e.g. PDU-01)"),
                  const SizedBox(height: 10),

                  // Name Field with Error
                  _buildTextField(
                      nameCtrl,
                      "Name (e.g. Main Server)",
                      errorText: nameError
                  ),
                  const SizedBox(height: 10),

                  // IP Field with Error
                  _buildTextField(
                      ipCtrl,
                      "IP Address",
                      errorText: ipError
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown<PduType>(
                    "PDU Type",
                    selectedType,
                    PduType.values,
                        (val) => setState(() => selectedType = val!),
                  ),
                  const SizedBox(height: 10),

                  _buildDropdown<PhaseType>(
                    "Phase Config",
                    selectedPhase,
                    PhaseType.values,
                        (val) => setState(() => selectedPhase = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                onPressed: () {
                  // --- VALIDATION LOGIC ---
                  setState(() {
                    // Reset errors
                    nameError = null;
                    ipError = null;

                    bool isValid = true;

                    // Validate Name
                    if (nameCtrl.text.trim().isEmpty) {
                      nameError = "Name cannot be empty";
                      isValid = false;
                    }

                    // Validate IP
                    if (ipCtrl.text.trim().isEmpty) {
                      ipError = "IP Address cannot be empty";
                      isValid = false;
                    } else if (!isValidIp(ipCtrl.text.trim())) {
                      ipError = "Invalid IP Format (e.g. 192.168.1.1)";
                      isValid = false;
                    }

                    // Proceed if Valid
                    if (isValid) {
                      final newPdu = PduDevice(
                        id: idCtrl.text,
                        name: nameCtrl.text.trim(),
                        ip: ipCtrl.text.trim(),
                        type: selectedType,
                        phase: selectedPhase,
                      );
                      controller.addPduToRack(loc, rack, newPdu);
                      Navigator.pop(ctx);
                    }
                  });
                },
                child: const Text("Save", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- UPDATED TEXT FIELD HELPER ---
  Widget _buildTextField(TextEditingController c, String label, {String? errorText}) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.backgroundDeep,
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        errorText: errorText, // Pass the error text here
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryBlue),
        ),
        // Change border color on error
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  // --- CONNECTION DIALOG ---
  void _showConnectionDialog(BuildContext context, PduDevice pdu) {
    final ipCtrl = TextEditingController(text: pdu.ip);
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.cardSurface,
            title: const AppText("Connect to iPDU", size: TextSize.title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [_buildTextField(ipCtrl, "iPDU IP Address")],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                ),
                onPressed: () {
                  pdu.ip = ipCtrl.text;
                  final controller = PduController(pdu);
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChangeNotifierProvider.value(
                            value: controller,
                            child: const DashboardView(),
                          ),
                    ),
                  );
                  controller.connectToBroker(
                    ipCtrl.text,
                    "elcom@2021",
                    "elcomMQ@2022",
                  );
                },
                child: const Text("Connect"),
              ),
            ],
          ),
    );
  }

  Widget _buildDropdown<T>(
    String label,
    T value,
    List<T> items,
    ValueChanged<T?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundDeep,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.cardSurface,
              style: const TextStyle(color: Colors.white),
              items:
                  items
                      .map(
                        (T item) => DropdownMenuItem<T>(
                          value: item,
                          child: Text(item.toString().split('.').last),
                        ),
                      )
                      .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.cardSurface,
            title: const Text(
              "Confirm Delete",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Are you sure? This action cannot be undone.",
              style: TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  onConfirm();
                  Navigator.pop(ctx);
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

}
