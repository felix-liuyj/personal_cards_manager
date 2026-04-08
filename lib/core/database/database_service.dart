import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:personal_cards_manager/models/models.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  late Isar _isar;
  Isar get isar => _isar;

  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [
        BankCardSchema,
        MemberCardSchema,
        IdentityDocumentSchema,
        LabelSchema,
        GroupSchema,
        ReminderSchema,
      ],
      directory: dir.path,
      name: 'pcm_database',
    );
  }

  Future<void> close() async {
    await _isar.close();
  }

  // Bank Card Operations
  Future<List<BankCard>> getAllBankCards() async {
    return await _isar.bankCards.where().findAll();
  }

  Future<BankCard?> getBankCardByUuid(String uuid) async {
    return await _isar.bankCards.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<int> saveBankCard(BankCard card) async {
    return await _isar.writeTxn(() async {
      return await _isar.bankCards.put(card);
    });
  }

  Future<bool> deleteBankCard(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.bankCards.delete(id);
    });
  }

  Future<List<BankCard>> getFavoriteBankCards() async {
    return await _isar.bankCards.filter().isFavoriteEqualTo(true).findAll();
  }

  Future<List<BankCard>> getArchivedBankCards() async {
    return await _isar.bankCards.filter().isArchivedEqualTo(true).findAll();
  }

  // Member Card Operations
  Future<List<MemberCard>> getAllMemberCards() async {
    return await _isar.memberCards.where().findAll();
  }

  Future<MemberCard?> getMemberCardByUuid(String uuid) async {
    return await _isar.memberCards.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<int> saveMemberCard(MemberCard card) async {
    return await _isar.writeTxn(() async {
      return await _isar.memberCards.put(card);
    });
  }

  Future<bool> deleteMemberCard(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.memberCards.delete(id);
    });
  }

  Future<List<MemberCard>> getFavoriteMemberCards() async {
    return await _isar.memberCards.filter().isFavoriteEqualTo(true).findAll();
  }

  Future<List<MemberCard>> getArchivedMemberCards() async {
    return await _isar.memberCards.filter().isArchivedEqualTo(true).findAll();
  }

  // Identity Document Operations
  Future<List<IdentityDocument>> getAllDocuments() async {
    return await _isar.identityDocuments.where().findAll();
  }

  Future<IdentityDocument?> getDocumentByUuid(String uuid) async {
    return await _isar.identityDocuments.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<int> saveDocument(IdentityDocument doc) async {
    return await _isar.writeTxn(() async {
      return await _isar.identityDocuments.put(doc);
    });
  }

  Future<bool> deleteDocument(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.identityDocuments.delete(id);
    });
  }

  Future<List<IdentityDocument>> getFavoriteDocuments() async {
    return await _isar.identityDocuments
        .filter()
        .isFavoriteEqualTo(true)
        .findAll();
  }

  Future<List<IdentityDocument>> getArchivedDocuments() async {
    return await _isar.identityDocuments
        .filter()
        .isArchivedEqualTo(true)
        .findAll();
  }

  // Label Operations
  Future<List<Label>> getAllLabels() async {
    return await _isar.labels.where().findAll();
  }

  Future<Label?> getLabelByUuid(String uuid) async {
    return await _isar.labels.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<int> saveLabel(Label label) async {
    return await _isar.writeTxn(() async {
      return await _isar.labels.put(label);
    });
  }

  Future<bool> deleteLabel(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.labels.delete(id);
    });
  }

  // Group Operations
  Future<List<Group>> getAllGroups() async {
    return await _isar.groups.where().findAll();
  }

  Future<Group?> getGroupByUuid(String uuid) async {
    return await _isar.groups.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<int> saveGroup(Group group) async {
    return await _isar.writeTxn(() async {
      return await _isar.groups.put(group);
    });
  }

  Future<bool> deleteGroup(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.groups.delete(id);
    });
  }

  // Reminder Operations
  Future<List<Reminder>> getAllReminders() async {
    return await _isar.reminders.where().findAll();
  }

  Future<List<Reminder>> getEnabledReminders() async {
    return await _isar.reminders.filter().isEnabledEqualTo(true).findAll();
  }

  Future<int> saveReminder(Reminder reminder) async {
    return await _isar.writeTxn(() async {
      return await _isar.reminders.put(reminder);
    });
  }

  Future<bool> deleteReminder(int id) async {
    return await _isar.writeTxn(() async {
      return await _isar.reminders.delete(id);
    });
  }

  // Statistics
  Future<Map<String, int>> getStatistics() async {
    final bankCards = await _isar.bankCards.count();
    final memberCards = await _isar.memberCards.count();
    final documents = await _isar.identityDocuments.count();
    final favorites =
        await _isar.bankCards.filter().isFavoriteEqualTo(true).count() +
        await _isar.memberCards.filter().isFavoriteEqualTo(true).count() +
        await _isar.identityDocuments.filter().isFavoriteEqualTo(true).count();
    final archived =
        await _isar.bankCards.filter().isArchivedEqualTo(true).count() +
        await _isar.memberCards.filter().isArchivedEqualTo(true).count() +
        await _isar.identityDocuments.filter().isArchivedEqualTo(true).count();

    return {
      'bankCards': bankCards,
      'memberCards': memberCards,
      'documents': documents,
      'favorites': favorites,
      'archived': archived,
    };
  }

  // Search
  Future<List<dynamic>> search(String query) async {
    final lowerQuery = query.toLowerCase();

    final bankCards = await _isar.bankCards
        .filter()
        .group(
          (q) => q
              .issuerNameContains(lowerQuery, caseSensitive: false)
              .or()
              .cardAliasContains(lowerQuery, caseSensitive: false)
              .or()
              .holderNameContains(lowerQuery, caseSensitive: false)
              .or()
              .fullCardNumberContains(lowerQuery),
        )
        .findAll();

    final memberCards = await _isar.memberCards
        .filter()
        .group(
          (q) => q
              .brandNameContains(lowerQuery, caseSensitive: false)
              .or()
              .memberNumberContains(lowerQuery, caseSensitive: false)
              .or()
              .cardAliasContains(lowerQuery, caseSensitive: false),
        )
        .findAll();

    final documents = await _isar.identityDocuments
        .filter()
        .group(
          (q) => q
              .documentNameContains(lowerQuery, caseSensitive: false)
              .or()
              .nameContains(lowerQuery, caseSensitive: false)
              .or()
              .documentNumberContains(lowerQuery),
        )
        .findAll();

    return [...bankCards, ...memberCards, ...documents];
  }

  // Recent items
  Future<List<dynamic>> getRecentItems({int limit = 10}) async {
    final bankCards = await _isar.bankCards
        .where()
        .sortByLastViewedAtDesc()
        .limit(limit)
        .findAll();

    final memberCards = await _isar.memberCards
        .where()
        .sortByLastViewedAtDesc()
        .limit(limit)
        .findAll();

    final documents = await _isar.identityDocuments
        .where()
        .sortByLastViewedAtDesc()
        .limit(limit)
        .findAll();

    final all = [...bankCards, ...memberCards, ...documents];
    all.sort((a, b) {
      final aDate = a.lastViewedAt ?? DateTime(1970);
      final bDate = b.lastViewedAt ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });

    return all.take(limit).toList();
  }

  // Expiring items
  Future<List<Reminder>> getExpiringItems() async {
    final reminders = await getEnabledReminders();
    return reminders.where((r) => r.isExpiring || r.isExpired).toList()
      ..sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
  }
}
