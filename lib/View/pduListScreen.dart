import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Controller/provider/pdu_provider.dart';
import '../Core/constant/appColors_constant.dart';
import '../Core/constant/appTextWidget.dart';
import '../Core/utils/navCard.dart';
import '../Model/pdu_model.dart';
import '../Model/rackModel.dart';


import 'dashboard_screen.dart';

// --- SCREEN 3: PDU LIST + CONNECT ---
class PduListScreen extends StatelessWidget {
  final Rack rack;
  const PduListScreen({super.key, required this.rack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      appBar: AppBar(title: Text(rack.id, style: GoogleFonts.jetBrainsMono()), backgroundColor: AppColors.cardSurface),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rack.pdus.length,
        separatorBuilder: (c, i) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => NavCard(
          title: rack.pdus[i].name, subtitle: "${rack.pdus[i].type.name} | ${rack.pdus[i].phase.name}", icon: Icons.power,
          trailing: const Text("CONNECT", style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
          onTap: () => _showConnectionDialog(context, rack.pdus[i]),
        ),
      ),
    );
  }

  void _showConnectionDialog(BuildContext context, PduDevice pdu) {
    final ipCtrl = TextEditingController(text: pdu.ip);
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const AppText("Connect to Elcom iPDU", size: TextSize.title,),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(ipCtrl, "iPDU :IP"), const SizedBox(height: 10),
            // _buildTextField(userCtrl, "Username"), const SizedBox(height: 10),
            // _buildTextField(passCtrl, "Password", obscure: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () {
              pdu.ip = ipCtrl.text;
              final controller = PduController(pdu);
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: controller, child: const DashboardView())));
              controller.connectToBroker(ipCtrl.text, "elcom@2021", "elcomMQ@2022");
            },
            child: const Text("Connect"),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController c, String label, {bool obscure = false}) {
    return TextField(controller: c, obscureText: obscure, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: AppColors.backgroundDeep, labelText: label, labelStyle: const TextStyle(color: Colors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))));
  }
}
