
import 'package:flutter/material.dart';

import '../../Model/locationModel.dart';
import '../../Model/pdu_model.dart';
import '../../Model/rackModel.dart';

class LocationController extends ChangeNotifier {
  // Initialize with your Static Data
  List<Location> _locations = [];

  List<Location> get locations => _locations;

  LocationController() {
    // Load the initial static data so the list isn't empty on startup
    _locations = List.from(StaticData.getLocations());
  }

  void addLocation(String name) {
    // Create a new Location with an empty list of Racks
    final newLocation = Location(name, []);
    _locations.add(newLocation);

    // This tells Flutter to rebuild the UI
    notifyListeners();
  }

  // --- NEW METHOD ---
  void addRackToLocation(Location location, String rackName) {
    // 1. Find the specific location object in our list
    final targetLocation = _locations.firstWhere((loc) => loc.name == location.name);

    // 2. Add the new Rack (Assuming empty list of PDUs for now)
    targetLocation.racks.add(Rack(rackName, []));

    // 3. Refresh UI
    notifyListeners();
  }
}