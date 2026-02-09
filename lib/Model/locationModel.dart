import 'package:hive/hive.dart';
import 'rackModel.dart';

part 'locationModel.g.dart';

@HiveType(typeId: 4)
class Location extends HiveObject { // Extending HiveObject allows .save() and .delete() easily
  @HiveField(0)
  final String name;

  @HiveField(1)
  final List<Rack> racks;

  Location(this.name, this.racks);
}