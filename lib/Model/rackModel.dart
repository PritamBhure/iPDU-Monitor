import 'package:hive/hive.dart';
import 'pdu_model.dart';

part 'rackModel.g.dart';

@HiveType(typeId: 3)
class Rack {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final List<PduDevice> pdus;

  Rack(this.id, this.pdus);
}