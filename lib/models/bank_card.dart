import 'package:isar/isar.dart';

part 'bank_card.g.dart';

@collection
class BankCard {
  Id id = Isar.autoIncrement;

  @Index()
  String uuid;

  String issuerName;
  String cardOrganization;
  String cardName;
  String cardAlias;
  String holderName;

  @Index()
  String fullCardNumber;

  @Index()
  String maskedCardNumber;

  int expiryMonth;
  int expiryYear;
  String cvv;

  String addressLine1;
  String addressLine2;
  String city;
  String state;
  String postalCode;
  String country;
  String currency;
  String notes;

  String templateId;
  String colorTheme;
  int sortOrder;

  @Index()
  bool isFavorite;

  @Index()
  bool isArchived;

  @enumerated
  CardStatus status;

  DateTime createdAt;
  DateTime updatedAt;
  DateTime? lastViewedAt;
  DateTime? lastCopiedAt;

  List<String> labelIds;
  String? groupId;

  BankCard({
    required this.uuid,
    required this.issuerName,
    this.cardOrganization = '',
    required this.cardName,
    this.cardAlias = '',
    required this.holderName,
    required this.fullCardNumber,
    this.maskedCardNumber = '',
    this.expiryMonth = 0,
    this.expiryYear = 0,
    this.cvv = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.country = '',
    this.currency = 'CNY',
    this.notes = '',
    this.templateId = 'default',
    this.colorTheme = 'blue',
    this.sortOrder = 0,
    this.isFavorite = false,
    this.isArchived = false,
    this.status = CardStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.lastViewedAt,
    this.lastCopiedAt,
    this.labelIds = const [],
    this.groupId,
  });

  String get maskedNumber {
    if (maskedCardNumber.isNotEmpty) return maskedCardNumber;
    if (fullCardNumber.length < 4) return fullCardNumber;
    final last4 = fullCardNumber.substring(fullCardNumber.length - 4);
    return '**** **** **** $last4';
  }

  String get formattedExpiry {
    if (expiryMonth == 0 || expiryYear == 0) return '';
    return '${expiryMonth.toString().padLeft(2, '0')}/${expiryYear.toString().substring(2)}';
  }
}

enum CardStatus { active, suspended, expired }
