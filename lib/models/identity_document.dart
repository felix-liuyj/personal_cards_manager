import 'package:isar/isar.dart';

part 'identity_document.g.dart';

@collection
class IdentityDocument {
  Id id = Isar.autoIncrement;

  @Index()
  String uuid;

  @enumerated
  DocumentType documentType;

  String documentName;
  String name;
  String englishName;

  @Index()
  String documentNumber;

  @enumerated
  Gender gender;

  String nationality;
  DateTime? dateOfBirth;
  String address;
  String issuingAuthority;
  DateTime? issueDate;
  DateTime? expiryDate;
  String additionalInfo;
  String notes;

  @enumerated
  DisplayMode displayMode;

  String templateId;
  int sortOrder;

  @Index()
  bool isFavorite;

  @Index()
  bool isArchived;

  @enumerated
  DocumentStatus status;

  DateTime createdAt;
  DateTime updatedAt;
  DateTime? lastViewedAt;
  DateTime? lastCopiedAt;

  List<String> labelIds;
  String? groupId;

  IdentityDocument({
    required this.uuid,
    required this.documentType,
    required this.documentName,
    required this.name,
    this.englishName = '',
    required this.documentNumber,
    this.gender = Gender.other,
    this.nationality = '',
    this.dateOfBirth,
    this.address = '',
    this.issuingAuthority = '',
    this.issueDate,
    this.expiryDate,
    this.additionalInfo = '',
    this.notes = '',
    this.displayMode = DisplayMode.cardHorizontal,
    this.templateId = 'default',
    this.sortOrder = 0,
    this.isFavorite = false,
    this.isArchived = false,
    this.status = DocumentStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.lastViewedAt,
    this.lastCopiedAt,
    this.labelIds = const [],
    this.groupId,
  });

  String get maskedNumber {
    if (documentNumber.length < 4) return documentNumber;
    final last4 = documentNumber.substring(documentNumber.length - 4);
    return '**** **** **** $last4';
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  bool get isExpiring {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }

  double get aspectRatio {
    switch (displayMode) {
      case DisplayMode.cardHorizontal:
        return 1.58;
      case DisplayMode.cardVertical:
        return 0.63;
      case DisplayMode.passportCover:
        return 1.38;
      case DisplayMode.passportSpread:
        return 2.0;
      case DisplayMode.documentLong:
        return 2.4;
      case DisplayMode.fullScreenDocument:
        return 1.0;
    }
  }
}

enum DocumentType {
  idCard,
  passport,
  driverLicense,
  hkMacauPass,
  taiwanPass,
  residencePermit,
  socialSecurityCard,
  studentId,
  workPermit,
  other,
}

enum Gender { male, female, other }

enum DisplayMode {
  cardHorizontal,
  cardVertical,
  passportCover,
  passportSpread,
  documentLong,
  fullScreenDocument,
}

enum DocumentStatus { active, expired, expiring }
