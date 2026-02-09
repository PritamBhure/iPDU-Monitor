// lib/Model/static_data.dart
import 'locationModel.dart';
import 'rackModel.dart';
import 'pdu_model.dart';

class StaticData {
  static List<Location> getLocations() {
    return [
      Location("Pune HQ", [
        Rack("RACK-01 (Server)", [
          PduDevice(id: "PDU-01", name: "Main Server A", ip: "103.93.99.1", type: PduType.IMIS, phase: PhaseType.ThreePhaseDelta),
          PduDevice(id: "PDU-02", name: "Main Server B", ip: "192.168.1.11", type: PduType.IMIS, phase: PhaseType.ThreePhaseStar),


        ]),
      ]),
      // Add other locations here...
    ];
  }
}