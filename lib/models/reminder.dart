import 'package:isar/isar.dart';

part 'reminder.g.dart';

@collection
class Reminder {
  Id id = Isar.autoIncrement;

  @Index()
  String uuid;

  @Index()
  String cardUuid;

  @enumerated
  CardType cardType;

  String cardName;
  DateTime expiryDate;

  @enumerated
  List<int> reminderDays;

  bool isEnabled;
  bool isRepeatable;

  DateTime createdAt;
  DateTime updatedAt;

  Reminder({
    required this.uuid,
    required this.cardUuid,
    required this.cardType,
    required this.cardName,
    required this.expiryDate,
    this.reminderDays = const [30, 14, 7, 3, 0],
    this.isEnabled = true,
    this.isRepeatable = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isExpiring {
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }

  bool get isExpired {
    return expiryDate.isBefore(DateTime.now());
  }

  int get daysUntilExpiry {
    return expiryDate.difference(DateTime.now()).inDays;
  }
}

enum CardType { bankCard, memberCard, identityDocument }
