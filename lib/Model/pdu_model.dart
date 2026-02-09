// --- ENUMS ---


import 'locationModel.dart';
import 'rackModel.dart';

enum PduType { AM, AMIS, IM, IMIS }
enum PhaseType { Single, ThreePhaseStar, ThreePhaseDelta }

// --- ENTITIES ---
class PduDevice {
  final String id;
  final String name;
  String ip;
  final PduType type;
  final PhaseType phase;

  PduDevice({
    required this.id, required this.name, required this.ip,
    required this.type, required this.phase
  });
}

// --- STATIC REPOSITORY (The Dummy Data) ---
class StaticData {
  static List<Location> getLocations() {
    return [
      Location("Pune HQ", [
        Rack("RACK-01 (Server)", [
          PduDevice(id: "PDU-01", name: "Main Server A", ip: "103.93.99.1", type: PduType.IMIS, phase: PhaseType.ThreePhaseStar),
          PduDevice(id: "PDU-02", name: "Main Server B", ip: "192.168.8.31", type: PduType.IMIS, phase: PhaseType.ThreePhaseStar),
        ]),
        Rack("RACK-02 (Storage)", [
          PduDevice(id: "PDU-03", name: "Storage Array Primary", ip: "192.168.1.15", type: PduType.IM, phase: PhaseType.ThreePhaseDelta),
          PduDevice(id: "PDU-04", name: "Storage Array Backup", ip: "192.168.1.16", type: PduType.AM, phase: PhaseType.Single),
        ]),
        Rack("RACK-03 (Network)", [
          PduDevice(id: "PDU-05", name: "Core Switch A", ip: "192.168.1.20", type: PduType.AMIS, phase: PhaseType.Single),
        ]),
      ]),
      Location("Mumbai DC", [
        Rack("RACK-M1", [
          PduDevice(id: "PDU-M1", name: "Blade Chassis A", ip: "10.0.0.5", type: PduType.IMIS, phase: PhaseType.ThreePhaseDelta),
          PduDevice(id: "PDU-M2", name: "Blade Chassis B", ip: "10.0.0.6", type: PduType.IMIS, phase: PhaseType.ThreePhaseDelta),
        ]),
        Rack("RACK-M2", [
          PduDevice(id: "PDU-M3", name: "GPU Cluster", ip: "10.0.0.8", type: PduType.IM, phase: PhaseType.ThreePhaseStar),
        ])
      ]),
      Location("Nagpur Unit", [
        Rack("RACK-N1", [
          PduDevice(id: "PDU-N1", name: "Gateway PDU", ip: "172.16.0.5", type: PduType.AM, phase: PhaseType.Single),
        ])
      ]),
      Location("Nashik Branch", []),
    ];
  }
}

