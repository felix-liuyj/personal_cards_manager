import 'package:isar/isar.dart';

part 'label.g.dart';

@collection
class Label {
  Id id = Isar.autoIncrement;

  @Index()
  String uuid;

  @Index()
  String name;

  String color;
  String iconName;
  int sortOrder;

  DateTime createdAt;
  DateTime updatedAt;

  Label({
    required this.uuid,
    required this.name,
    this.color = '#2196F3',
    this.iconName = 'label',
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });
}

@collection
class Group {
  Id id = Isar.autoIncrement;

  @Index()
  String uuid;

  @Index()
  String name;

  String description;
  int sortOrder;

  DateTime createdAt;
  DateTime updatedAt;

  Group({
    required this.uuid,
    required this.name,
    this.description = '',
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });
}
