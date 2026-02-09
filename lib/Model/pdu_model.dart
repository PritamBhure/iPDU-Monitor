import 'package:hive/hive.dart';

// This file must be generated. 
// If your file is named pdu_model.dart, the part must be pdu_model.g.dart
part 'pdu_model.g.dart';

@HiveType(typeId: 0)
enum PduType {
  @HiveField(0) AM,
  @HiveField(1) AMIS,
  @HiveField(2) IM,
  @HiveField(3) IMIS
}

@HiveType(typeId: 1)
enum PhaseType {
  @HiveField(0) Single,
  @HiveField(1) ThreePhaseStar,
  @HiveField(2) ThreePhaseDelta
}

@HiveType(typeId: 2)
class PduDevice {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  String ip;

  @HiveField(3)
  final PduType type;

  @HiveField(4)
  final PhaseType phase;

  PduDevice({
    required this.id,
    required this.name,
    required this.ip,
    required this.type,
    required this.phase
  });
}