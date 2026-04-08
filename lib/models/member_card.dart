import 'package:isar/isar.dart';

part 'member_card.g.dart';

@collection
class MemberCard {
  Id id = Isar.autoIncrement;

  @Index()
  String uuid;

  String brandName;
  String cardName;
  String cardAlias;

  @Index()
  String memberNumber;

  String memberLevel;
  int points;
  String phoneNumber;
  String barcodeContent;
  String qrCodeContent;
  DateTime? expiryDate;
  String notes;

  String templateId;
  int sortOrder;

  @Index()
  bool isFavorite;

  @Index()
  bool isArchived;

  @enumerated
  MemberCardStatus status;

  DateTime createdAt;
  DateTime updatedAt;
  DateTime? lastViewedAt;

  List<String> labelIds;
  String? groupId;

  MemberCard({
    required this.uuid,
    required this.brandName,
    required this.cardName,
    this.cardAlias = '',
    required this.memberNumber,
    this.memberLevel = '',
    this.points = 0,
    this.phoneNumber = '',
    this.barcodeContent = '',
    this.qrCodeContent = '',
    this.expiryDate,
    this.notes = '',
    this.templateId = 'default',
    this.sortOrder = 0,
    this.isFavorite = false,
    this.isArchived = false,
    this.status = MemberCardStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.lastViewedAt,
    this.labelIds = const [],
    this.groupId,
  });

  bool get hasBarcode => barcodeContent.isNotEmpty;
  bool get hasQrCode => qrCodeContent.isNotEmpty;
}

enum MemberCardStatus { active, suspended, expired }
