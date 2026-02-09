import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../Model/locationModel.dart';
import '../../Model/rackModel.dart';
import '../../Model/pdu_model.dart';
// import '../../Model/static_data.dart'; // Uncomment if you use initial seed data

class LocationController extends ChangeNotifier {
  // Reference the opened box
  final Box<Location> _box = Hive.box<Location>('locationsBox');

  List<Location> get locations => _box.values.toList();

  // --- 1. LOCATION MANAGEMENT ---

  void addLocation(String name) {
    final newLocation = Location(name, []);
    _box.add(newLocation);
    notifyListeners();
  }

  void updateLocationName(Location location, String newName) {
    // Create a new object with the updated name but keep existing racks
    final updatedLocation = Location(newName, location.racks);

    // Overwrite the existing entry in the database using its unique key
    _box.put(location.key, updatedLocation);

    notifyListeners(); // Updates UI immediately
  }

  void deleteLocation(Location location) {
    location.delete();
    notifyListeners();
  }

  // --- 2. RACK MANAGEMENT ---

  void addRackToLocation(Location location, String rackName) {
    final newRack = Rack(rackName, []);
    location.racks.add(newRack);
    location.save(); // Persist changes to the Location object
    notifyListeners();
  }

  void updateRackName(Location location, Rack oldRack, String newName) {
    // Find the index of the rack we want to edit
    int index = location.racks.indexOf(oldRack);

    // Safety check: if object reference changed, try finding by ID/Name
    if (index == -1) {
      index = location.racks.indexWhere((r) => r.id == oldRack.id);
    }

    if (index != -1) {
      // Replace with new Rack object (since fields are likely final)
      final newRack = Rack(newName, oldRack.pdus);
      location.racks[index] = newRack;

      location.save(); // Save Location to persist Rack change
      notifyListeners();
    }
  }

  void deleteRack(Location location, Rack rack) {
    location.racks.remove(rack);
    location.save();
    notifyListeners();
  }

  // --- 3. PDU MANAGEMENT ---

  void addPduToRack(Location location, Rack rack, PduDevice pdu) {
    // Ensure we are adding to the correct rack instance in the list
    int index = location.racks.indexWhere((r) => r.id == rack.id);
    if (index != -1) {
      location.racks[index].pdus.add(pdu);
      location.save();
      notifyListeners();
    }
  }


  void updatePduDetails(Location location, Rack rack, PduDevice oldPdu, PduDevice newPdu) {
    // 1. Find the rack
    int rackIndex = location.racks.indexOf(rack);
    if (rackIndex == -1) return;

    // 2. Find the PDU inside the rack
    int pduIndex = location.racks[rackIndex].pdus.indexOf(oldPdu);

    if (pduIndex != -1) {
      // 3. Update the PDU
      location.racks[rackIndex].pdus[pduIndex] = newPdu;

      // 4. Save Location (Persists everything)
      location.save();
      notifyListeners();
    }
  }

  void deletePdu(Location location, Rack rack, PduDevice pdu) {
    int rackIndex = location.racks.indexOf(rack);
    if (rackIndex != -1) {
      location.racks[rackIndex].pdus.remove(pdu);
      location.save();
      notifyListeners();
    }
  }
}