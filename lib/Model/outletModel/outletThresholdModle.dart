// --- HELPER MODEL FOR THRESHOLD FORM DATA ---
import 'package:flutter/material.dart';

class OutletThresholdForm {
  final String status;
  final TextEditingController lowLoad;
  final TextEditingController nearOver;
  final TextEditingController overLoad;

  OutletThresholdForm({
    required this.status,
    required this.lowLoad,
    required this.nearOver,
    required this.overLoad,
  });

  void dispose() {
    lowLoad.dispose();
    nearOver.dispose();
    overLoad.dispose();
  }
}