import 'package:isar/isar.dart';

part 'models.g.dart';

@collection
class CustomTag {
  Id id = Isar.autoIncrement;
  String? name;
  String? colorHex;
  String? iconName;
}

@collection
class CustomGroup {
  Id id = Isar.autoIncrement;
  String? name;
  int? sortOrder;
}

@collection
class BankCard {
  Id id = Isar.autoIncrement;
  
  // 核心发卡要素
  String? issuerName;
  String? network;
  String? cardName;
  String? aliasName;
  String? holderName;
  
  // 敏感支付要素
  String? fullNumber; 
  int? expMonth;
  int? expYear;
  String? cvv; 
  
  // 账单地址要素 (扁平化拆解)
  String? addressLine1;
  String? addressLine2;
  String? city;
  String? stateProvince;
  String? zipCode;
  String? country;
  
  // 扩展参数
  String? currency;
  String? note;
  String? colorTheme; 
  String? templateName;
  
  // 系统路由域
  int customSort = 0; 
  bool isFavorite = false;
  bool isArchived = false;

  final tags = IsarLinks<CustomTag>();
  final groups = IsarLinks<CustomGroup>();
  
  DateTime? createdAt;
  DateTime? updatedAt;
}

@collection
class MemberCard {
  Id id = Isar.autoIncrement;
  
  // 凭证业务属性
  String? brand; 
  String? cardName; 
  String? aliasName; 
  String? memberNumber; 
  String? tierCode; 
  double? points; 

  String? phoneNumber; 
  
  // 制式代码体系分流
  String? barcodeData; 
  String? qrcodeData; 
  
  DateTime? validUntil;
  String? note;
  String? templateName;

  bool isFavorite = false;
  bool isArchived = false;

  final tags = IsarLinks<CustomTag>();
  final groups = IsarLinks<CustomGroup>();
  
  DateTime? createdAt;
  DateTime? updatedAt;
}

@collection
class IDCard {
  Id id = Isar.autoIncrement;
  
  // 身份分类学
  String? countryCode; 
  String? documentType; 
  
  // 人格特质记录
  String? cardName; 
  String? fullName; 
  String? englishName; 
  String? documentNumber; 
  String? gender; 
  DateTime? birthDate; 
  String? fullAddress; 
  
  // 行政背书机构记录
  String? issueAuthority; 
  DateTime? issueDate; 
  DateTime? expireDate; 
  
  String? extras; 
  String? note; 

  // ===================================
  // 以下为受控的强制视觉约束引擎层元数据区
  // ===================================
  @Enumerated(EnumType.name)
  DisplayMode displayMode = DisplayMode.cardHorizontal;
  double aspectRatio = 1.58;
  
  bool supportsExpand = false;
  
  @Enumerated(EnumType.name)
  DisplayMode expandedMode = DisplayMode.passportSpread;
  double expandedAspectRatio = 2.0; // 护照折页的2.0宽频支持
  bool supportsFullscreen = false;

  String? templateName;

  bool isFavorite = false;
  bool isArchived = false;

  final tags = IsarLinks<CustomTag>();
  final groups = IsarLinks<CustomGroup>();
  
  DateTime? createdAt;
  DateTime? updatedAt;
}

/// 支持的全局定距映射枚举
enum DisplayMode {
  cardHorizontal,
  cardVertical,
  passportCover,
  passportSpread,
  documentLong,
  fullScreenDocument
}
