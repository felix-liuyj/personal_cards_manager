import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';

final backupServiceProvider = Provider((ref) {
  return BackupService(ref.watch(localDbProvider.future));
});

class BackupService {
  final Future<Isar> _isarFuture;

  BackupService(this._isarFuture);

  encrypt.Key _deriveKey(String password) {
    final padded = (password + "pcm_backup_salt_key_84vN2xQpL9A!").substring(0, 32);
    return encrypt.Key.fromUtf8(padded);
  }

  Future<String> exportData(String password) async {
    final isar = await _isarFuture;
    
    final banks = await isar.bankCards.where().findAll();
    final members = await isar.memberCards.where().findAll();
    final docs = await isar.iDCards.where().findAll();
    final tags = await isar.customTags.where().findAll();
    final groups = await isar.customGroups.where().findAll();

    final payload = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'tags': tags.map((t) => {
        'id': t.id,
        'name': t.name,
        'colorHex': t.colorHex,
        'iconName': t.iconName,
      }).toList(),
      'groups': groups.map((g) => {
        'id': g.id,
        'name': g.name,
        'sortOrder': g.sortOrder,
      }).toList(),
      'bankCards': banks.map((c) => {
        'issuerName': c.issuerName,
        'network': c.network,
        'cardName': c.cardName,
        'aliasName': c.aliasName,
        'holderName': c.holderName,
        'fullNumber': c.fullNumber,
        'expMonth': c.expMonth,
        'expYear': c.expYear,
        'cvv': c.cvv,
        'addressLine1': c.addressLine1,
        'addressLine2': c.addressLine2,
        'city': c.city,
        'stateProvince': c.stateProvince,
        'zipCode': c.zipCode,
        'country': c.country,
        'currency': c.currency,
        'note': c.note,
        'colorTheme': c.colorTheme,
        'templateName': c.templateName,
        'customSort': c.customSort,
        'isFavorite': c.isFavorite,
        'isArchived': c.isArchived,
        'createdAt': c.createdAt?.toIso8601String(),
        'updatedAt': c.updatedAt?.toIso8601String(),
      }).toList(),
      'memberCards': members.map((c) => {
        'brand': c.brand,
        'cardName': c.cardName,
        'aliasName': c.aliasName,
        'memberNumber': c.memberNumber,
        'tierCode': c.tierCode,
        'points': c.points,
        'phoneNumber': c.phoneNumber,
        'barcodeData': c.barcodeData,
        'qrcodeData': c.qrcodeData,
        'validUntil': c.validUntil?.toIso8601String(),
        'note': c.note,
        'templateName': c.templateName,
        'isFavorite': c.isFavorite,
        'isArchived': c.isArchived,
        'createdAt': c.createdAt?.toIso8601String(),
        'updatedAt': c.updatedAt?.toIso8601String(),
      }).toList(),
      'idCards': docs.map((c) => {
        'countryCode': c.countryCode,
        'documentType': c.documentType,
        'cardName': c.cardName,
        'fullName': c.fullName,
        'englishName': c.englishName,
        'documentNumber': c.documentNumber,
        'gender': c.gender,
        'birthDate': c.birthDate?.toIso8601String(),
        'fullAddress': c.fullAddress,
        'issueAuthority': c.issueAuthority,
        'issueDate': c.issueDate?.toIso8601String(),
        'expireDate': c.expireDate?.toIso8601String(),
        'extras': c.extras,
        'note': c.note,
        'displayMode': c.displayMode.name,
        'aspectRatio': c.aspectRatio,
        'supportsExpand': c.supportsExpand,
        'expandedMode': c.expandedMode.name,
        'expandedAspectRatio': c.expandedAspectRatio,
        'supportsFullscreen': c.supportsFullscreen,
        'templateName': c.templateName,
        'isFavorite': c.isFavorite,
        'isArchived': c.isArchived,
        'createdAt': c.createdAt?.toIso8601String(),
        'updatedAt': c.updatedAt?.toIso8601String(),
      }).toList(),
    };

    final jsonStr = jsonEncode(payload);

    final key = _deriveKey(password);
    final iv = encrypt.IV.fromLength(16); 
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    
    final encrypted = encrypter.encrypt(jsonStr, iv: iv);
    
    final finalStr = '${iv.base64}:${encrypted.base64}';

    final dir = await getTemporaryDirectory();
    final formatter = "${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}";
    final file = File('${dir.path}/cards_backup_$formatter.pcmbak');
    await file.writeAsString(finalStr);

    return file.path;
  }

  Future<void> importData(String filePath, String password) async {
    final file = File(filePath);
    final finalStr = await file.readAsString();

    final parts = finalStr.split(':');
    if (parts.length != 2) throw Exception("Invalid backup file format");

    final iv = encrypt.IV.fromBase64(parts[0]);
    final cipher = encrypt.Encrypted.fromBase64(parts[1]);
    
    final key = _deriveKey(password);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    String jsonStr;
    try {
      jsonStr = encrypter.decrypt(cipher, iv: iv);
    } catch (_) {
      throw Exception("Invalid password");
    }

    final payload = jsonDecode(jsonStr) as Map<String, dynamic>;
    
    final isar = await _isarFuture;

    await isar.writeTxn(() async {
      await isar.bankCards.clear();
      await isar.memberCards.clear();
      await isar.iDCards.clear();
      await isar.customTags.clear();
      await isar.customGroups.clear();

      Map<int, CustomTag> newTags = {};
      final rawTags = payload['tags'] as List? ?? [];
      for (final rt in rawTags) {
        final t = CustomTag()
          ..name = rt['name']
          ..colorHex = rt['colorHex']
          ..iconName = rt['iconName'];
        await isar.customTags.put(t);
        newTags[rt['id']] = t;
      }

      Map<int, CustomGroup> newGroups = {};
      final rawGroups = payload['groups'] as List? ?? [];
      for (final rg in rawGroups) {
        final g = CustomGroup()
          ..name = rg['name']
          ..sortOrder = rg['sortOrder'];
        await isar.customGroups.put(g);
        newGroups[rg['id']] = g;
      }

      final rawBanks = payload['bankCards'] as List? ?? [];
      for (final rb in rawBanks) {
        final c = BankCard()
          ..issuerName = rb['issuerName']
          ..network = rb['network']
          ..cardName = rb['cardName']
          ..aliasName = rb['aliasName']
          ..holderName = rb['holderName']
          ..fullNumber = rb['fullNumber']
          ..expMonth = rb['expMonth']
          ..expYear = rb['expYear']
          ..cvv = rb['cvv']
          ..addressLine1 = rb['addressLine1']
          ..addressLine2 = rb['addressLine2']
          ..city = rb['city']
          ..stateProvince = rb['stateProvince']
          ..zipCode = rb['zipCode']
          ..country = rb['country']
          ..currency = rb['currency']
          ..note = rb['note']
          ..colorTheme = rb['colorTheme']
          ..templateName = rb['templateName']
          ..customSort = rb['customSort'] ?? 0
          ..isFavorite = rb['isFavorite'] ?? false
          ..isArchived = rb['isArchived'] ?? false
          ..createdAt = rb['createdAt'] != null ? DateTime.parse(rb['createdAt']) : null
          ..updatedAt = rb['updatedAt'] != null ? DateTime.parse(rb['updatedAt']) : null;
        await isar.bankCards.put(c);
      }

      final rawMembers = payload['memberCards'] as List? ?? [];
      for (final rm in rawMembers) {
        final c = MemberCard()
          ..brand = rm['brand']
          ..cardName = rm['cardName']
          ..aliasName = rm['aliasName']
          ..memberNumber = rm['memberNumber']
          ..tierCode = rm['tierCode']
          ..points = rm['points']?.toDouble()
          ..phoneNumber = rm['phoneNumber']
          ..barcodeData = rm['barcodeData']
          ..qrcodeData = rm['qrcodeData']
          ..validUntil = rm['validUntil'] != null ? DateTime.parse(rm['validUntil']) : null
          ..note = rm['note']
          ..templateName = rm['templateName']
          ..isFavorite = rm['isFavorite'] ?? false
          ..isArchived = rm['isArchived'] ?? false
          ..createdAt = rm['createdAt'] != null ? DateTime.parse(rm['createdAt']) : null
          ..updatedAt = rm['updatedAt'] != null ? DateTime.parse(rm['updatedAt']) : null;
        await isar.memberCards.put(c);
      }

      final rawDocs = payload['idCards'] as List? ?? [];
      for (final rd in rawDocs) {
        DisplayMode dm = DisplayMode.cardHorizontal;
        try {
           dm = DisplayMode.values.byName(rd['displayMode'] ?? 'cardHorizontal');
        } catch (_) {}

        DisplayMode em = DisplayMode.passportSpread;
        try {
           em = DisplayMode.values.byName(rd['expandedMode'] ?? 'passportSpread');
        } catch (_) {}

        final c = IDCard()
          ..countryCode = rd['countryCode']
          ..documentType = rd['documentType']
          ..cardName = rd['cardName']
          ..fullName = rd['fullName']
          ..englishName = rd['englishName']
          ..documentNumber = rd['documentNumber']
          ..gender = rd['gender']
          ..birthDate = rd['birthDate'] != null ? DateTime.parse(rd['birthDate']) : null
          ..fullAddress = rd['fullAddress']
          ..issueAuthority = rd['issueAuthority']
          ..issueDate = rd['issueDate'] != null ? DateTime.parse(rd['issueDate']) : null
          ..expireDate = rd['expireDate'] != null ? DateTime.parse(rd['expireDate']) : null
          ..extras = rd['extras']
          ..note = rd['note']
          ..displayMode = dm
          ..aspectRatio = rd['aspectRatio']?.toDouble() ?? 1.58
          ..supportsExpand = rd['supportsExpand'] ?? false
          ..expandedMode = em
          ..expandedAspectRatio = rd['expandedAspectRatio']?.toDouble() ?? 2.0
          ..supportsFullscreen = rd['supportsFullscreen'] ?? false
          ..templateName = rd['templateName']
          ..isFavorite = rd['isFavorite'] ?? false
          ..isArchived = rd['isArchived'] ?? false
          ..createdAt = rd['createdAt'] != null ? DateTime.parse(rd['createdAt']) : null
          ..updatedAt = rd['updatedAt'] != null ? DateTime.parse(rd['updatedAt']) : null;
        await isar.iDCards.put(c);
      }
    });
  }
}
