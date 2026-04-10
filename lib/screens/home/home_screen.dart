import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';
import 'package:personal_cards_manager/screens/bank_cards/bank_cards_list_screen.dart';
import 'package:personal_cards_manager/screens/member_cards/member_cards_list_screen.dart';
import 'package:personal_cards_manager/screens/documents/documents_list_screen.dart';
import 'package:personal_cards_manager/screens/bank_cards/bank_card_form_screen.dart';
import 'package:personal_cards_manager/screens/member_cards/member_card_form_screen.dart';
import 'package:personal_cards_manager/screens/documents/id_card_form_screen.dart';
import 'package:personal_cards_manager/screens/search/search_screen.dart';
import 'package:personal_cards_manager/screens/settings/settings_screen.dart';
import 'package:personal_cards_manager/screens/bank_cards/bank_card_detail_screen.dart';
import 'package:personal_cards_manager/screens/member_cards/member_card_detail_screen.dart';
import 'package:personal_cards_manager/screens/documents/document_detail_screen.dart';
import 'package:personal_cards_manager/screens/home/archived_cards_screen.dart';
import 'package:personal_cards_manager/screens/home/favorites_screen.dart';
import 'package:personal_cards_manager/features/home/recent_usage_service.dart';
import 'package:personal_cards_manager/core/notifications/notification_service.dart';

final recentViewedProvider = FutureProvider<List<RecentEntry>>((ref) async {
  return await ref.read(recentUsageServiceProvider).getRecentViewed();
});

// ───── Providers ─────
final bankCardCountProvider = FutureProvider<int>((ref) async {
  final isar = await ref.watch(localDbProvider.future);
  final all = await isar.bankCards.where().findAll();
  return all.where((c) => !c.isArchived).length;
});

final memberCardCountProvider = FutureProvider<int>((ref) async {
  final isar = await ref.watch(localDbProvider.future);
  final all = await isar.memberCards.where().findAll();
  return all.where((c) => !c.isArchived).length;
});

final idCardCountProvider = FutureProvider<int>((ref) async {
  final isar = await ref.watch(localDbProvider.future);
  final all = await isar.iDCards.where().findAll();
  return all.where((c) => !c.isArchived).length;
});

final favoriteCountProvider = FutureProvider<int>((ref) async {
  final isar = await ref.watch(localDbProvider.future);
  final banks = await isar.bankCards.where().findAll();
  final members = await isar.memberCards.where().findAll();
  final docs = await isar.iDCards.where().findAll();
  return banks.where((c) => c.isFavorite).length +
      members.where((c) => c.isFavorite).length +
      docs.where((c) => c.isFavorite).length;
});

final expiringCardsProvider = FutureProvider<List<dynamic>>((ref) async {
  final isar = await ref.watch(localDbProvider.future);
  final now = DateTime.now();
  final threshold = now.add(const Duration(days: 30));

  final banks = await isar.bankCards.where().findAll();
  final members = await isar.memberCards.where().findAll();
  final docs = await isar.iDCards.where().findAll();

  final expiring = <dynamic>[];

  for (final c in banks.where((c) => !c.isArchived)) {
    if (c.expMonth != null && c.expYear != null) {
      final expiry = DateTime(c.expYear!, c.expMonth! + 1, 0);
      if (expiry.isBefore(threshold)) expiring.add(c);
    }
  }

  for (final c in members.where((c) => !c.isArchived)) {
    if (c.validUntil != null && c.validUntil!.isBefore(threshold)) {
      expiring.add(c);
    }
  }

  for (final d in docs.where((d) => !d.isArchived)) {
    if (d.expireDate != null && d.expireDate!.isBefore(threshold)) {
      expiring.add(d);
    }
  }

  return expiring;
});

// ───── Screen ─────
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _notificationsScheduled = false;

  @override
  void initState() {
    super.initState();
    // Schedule expiry notifications once after DB is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleExpiryNotifications());
  }

  Future<void> _scheduleExpiryNotifications() async {
    if (_notificationsScheduled) return;
    _notificationsScheduled = true;
    try {
      final isar = await ref.read(localDbProvider.future);
      final ns = ref.read(notificationServiceProvider);
      await ns.requestPermission();

      final now = DateTime.now();
      final threshold = now.add(const Duration(days: 30));
      final banks = await isar.bankCards.where().findAll();
      final members = await isar.memberCards.where().findAll();
      final docs = await isar.iDCards.where().findAll();

      int notifId = 100;
      for (final c in banks.where((c) => !c.isArchived)) {
        if (c.expMonth != null && c.expYear != null) {
          final expiry = DateTime(c.expYear!, c.expMonth! + 1, 0);
          if (expiry.isBefore(threshold)) {
            final label = c.cardName?.isNotEmpty == true ? c.cardName! : c.issuerName ?? '银行卡';
            final daysLeft = expiry.difference(now).inDays;
            await ns.scheduleExpiry(
              id: notifId++,
              title: '银行卡即将到期',
              body: '$label 将在 ${daysLeft < 0 ? '已过期' : '$daysLeft 天后'} 到期',
            );
          }
        }
      }
      for (final c in members.where((c) => !c.isArchived)) {
        if (c.validUntil != null && c.validUntil!.isBefore(threshold)) {
          final label = c.cardName?.isNotEmpty == true ? c.cardName! : c.brand ?? '会员卡';
          final daysLeft = c.validUntil!.difference(now).inDays;
          await ns.scheduleExpiry(
            id: notifId++,
            title: '会员卡即将到期',
            body: '$label 将在 ${daysLeft < 0 ? '已过期' : '$daysLeft 天后'} 到期',
          );
        }
      }
      for (final d in docs.where((d) => !d.isArchived)) {
        if (d.expireDate != null && d.expireDate!.isBefore(threshold)) {
          final label = d.cardName?.isNotEmpty == true ? d.cardName! : d.fullName ?? '证件';
          final daysLeft = d.expireDate!.difference(now).inDays;
          await ns.scheduleExpiry(
            id: notifId++,
            title: '证件即将到期',
            body: '$label 将在 ${daysLeft < 0 ? '已过期' : '$daysLeft 天后'} 到期',
          );
        }
      }
    } catch (_) {
      // Notification failures should never crash the app
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankCardCount = ref.watch(bankCardCountProvider);
    final memberCardCount = ref.watch(memberCardCountProvider);
    final idCardCount = ref.watch(idCardCountProvider);
    final favoriteCount = ref.watch(favoriteCountProvider);
    final expiringCards = ref.watch(expiringCardsProvider);
    final recentViewed = ref.watch(recentViewedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('卡片管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bankCardCountProvider);
          ref.invalidate(memberCardCountProvider);
          ref.invalidate(idCardCountProvider);
          ref.invalidate(favoriteCountProvider);
          ref.invalidate(expiringCardsProvider);
          ref.invalidate(recentViewedProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewGrid(context, ref, bankCardCount, memberCardCount, idCardCount, favoriteCount),
              const SizedBox(height: 24),
              _buildQuickActions(context, ref),
              const SizedBox(height: 24),
              _buildRecentSection(context, ref, recentViewed),
              _buildExpiringSection(context, ref, expiringCards),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        icon: const Icon(Icons.add),
        label: const Text('添加'),
      ),
    );
  }

  Widget _buildOverviewGrid(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<int> bankCardCount,
    AsyncValue<int> memberCardCount,
    AsyncValue<int> idCardCount,
    AsyncValue<int> favoriteCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('概览', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                '银行卡',
                bankCardCount,
                Icons.credit_card,
                Colors.blue,
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BankCardsListScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                '会员卡',
                memberCardCount,
                Icons.card_membership,
                Colors.orange,
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MemberCardsListScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                '证件',
                idCardCount,
                Icons.badge,
                Colors.green,
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DocumentsListScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                '收藏',
                favoriteCount,
                Icons.star,
                Colors.amber,
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const FavoritesScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    AsyncValue<int> count,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 24),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_ios, size: 12, color: color.withOpacity(0.6)),
                ],
              ),
              const SizedBox(height: 12),
              count.when(
                loading: () => const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const Text('-'),
                data: (v) => Text(
                  '$v',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    final actions = [
      _ActionItem('添加银行卡', Icons.add_card, Colors.blue, () => _addBankCard(context)),
      _ActionItem('添加会员卡', Icons.card_membership, Colors.orange, () => _addMemberCard(context)),
      _ActionItem('添加证件', Icons.badge, Colors.green, () => _addDocument(context)),
      _ActionItem('归档', Icons.archive_outlined, Colors.blueGrey, () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchivedCardsScreen()))),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('快捷操作', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: actions.map((a) => _buildActionButton(context, a)).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<RecentEntry>> recentViewed,
  ) {
    return recentViewed.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('最近查看',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {},
                  child: const Text('查看全部'),
                ),
              ],
            ),
            SizedBox(
              height: 88,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: items.take(8).length,
                itemBuilder: (_, i) {
                  final entry = items[i];
                  final icon = entry.type == 'bank'
                      ? Icons.credit_card
                      : entry.type == 'member'
                          ? Icons.card_membership
                          : Icons.badge;
                  final color = entry.type == 'bank'
                      ? Colors.blue
                      : entry.type == 'member'
                          ? Colors.orange
                          : Colors.green;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openRecentEntry(context, ref, entry),
                      child: Container(
                        width: 76,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(0.2)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, color: color, size: 26),
                            const SizedBox(height: 6),
                            Text(
                              entry.title,
                              style: const TextStyle(fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, _ActionItem item) {
    return Expanded(
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpiringSection(BuildContext context, WidgetRef ref, AsyncValue<List<dynamic>> expiringCards) {
    return expiringCards.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 6),
                Text(
                  '即将过期 (${items.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.take(3).map((item) => _buildExpiringItem(context, item)),
            if (items.length > 3)
              TextButton(
                onPressed: () {},
                child: Text('查看全部 ${items.length} 条即将过期'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildExpiringItem(BuildContext context, dynamic item) {
    String title = '';
    String expiry = '';
    IconData icon = Icons.credit_card;
    Color color = Colors.orange;
    bool isExpired = false;

    if (item is BankCard) {
      title = item.cardName?.isNotEmpty == true ? item.cardName! : item.issuerName ?? '银行卡';
      expiry = '${item.expMonth?.toString().padLeft(2, '0')}/${item.expYear}';
      icon = Icons.credit_card;
      color = Colors.blue;
      final expDate = item.expYear != null && item.expMonth != null
          ? DateTime(item.expYear!, item.expMonth! + 1, 0)
          : null;
      isExpired = expDate?.isBefore(DateTime.now()) ?? false;
    } else if (item is MemberCard) {
      title = item.cardName?.isNotEmpty == true ? item.cardName! : item.brand ?? '会员卡';
      expiry = item.validUntil != null
          ? '${item.validUntil!.year}-${item.validUntil!.month.toString().padLeft(2, '0')}-${item.validUntil!.day.toString().padLeft(2, '0')}'
          : '未知';
      icon = Icons.card_membership;
      color = Colors.orange;
      isExpired = item.validUntil?.isBefore(DateTime.now()) ?? false;
    } else if (item is IDCard) {
      title = item.cardName?.isNotEmpty == true ? item.cardName! : item.fullName ?? '证件';
      expiry = item.expireDate != null
          ? '${item.expireDate!.year}-${item.expireDate!.month.toString().padLeft(2, '0')}-${item.expireDate!.day.toString().padLeft(2, '0')}'
          : '未知';
      icon = Icons.badge;
      color = Colors.green;
      isExpired = item.expireDate?.isBefore(DateTime.now()) ?? false;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isExpired
          ? Colors.red.withOpacity(0.06)
          : Colors.orange.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isExpired ? Colors.red.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('${isExpired ? '已过期' : '到期'}: $expiry'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isExpired ? Colors.red : Colors.orange,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isExpired ? '已过期' : '即将到期',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
        onTap: () {
          if (item is BankCard) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => BankCardDetailScreen(card: item)));
          } else if (item is MemberCard) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => MemberCardDetailScreen(card: item)));
          } else if (item is IDCard) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => DocumentDetailScreen(card: item)));
          }
        },
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x1A2196F3),
                  child: Icon(Icons.add_card, color: Colors.blue),
                ),
                title: const Text('添加银行卡'),
                onTap: () {
                  Navigator.pop(ctx);
                  _addBankCard(context);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x1AFF9800),
                  child: Icon(Icons.card_membership, color: Colors.orange),
                ),
                title: const Text('添加会员卡'),
                onTap: () {
                  Navigator.pop(ctx);
                  _addMemberCard(context);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x1A4CAF50),
                  child: Icon(Icons.badge, color: Colors.green),
                ),
                title: const Text('添加证件'),
                onTap: () {
                  Navigator.pop(ctx);
                  _addDocument(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addBankCard(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BankCardFormScreen()));
  }

  void _addMemberCard(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberCardFormScreen()));
  }

  void _addDocument(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const IDCardFormScreen()));
  }

  Future<void> _openRecentEntry(BuildContext context, WidgetRef ref, RecentEntry entry) async {
    final isar = await ref.read(localDbProvider.future);
    bool shouldRefresh = false;

    if (entry.type == 'bank') {
      final card = await isar.bankCards.get(entry.id);
      if (card != null && mounted) {
        shouldRefresh = await Navigator.push(context, 
          MaterialPageRoute(builder: (_) => BankCardDetailScreen(card: card))) == true;
      }
    } else if (entry.type == 'member') {
      final card = await isar.memberCards.get(entry.id);
      if (card != null && mounted) {
        shouldRefresh = await Navigator.push(context, 
          MaterialPageRoute(builder: (_) => MemberCardDetailScreen(card: card))) == true;
      }
    } else if (entry.type == 'id') {
      final card = await isar.iDCards.get(entry.id);
      if (card != null && mounted) {
        shouldRefresh = await Navigator.push(context, 
          MaterialPageRoute(builder: (_) => DocumentDetailScreen(card: card))) == true;
      }
    }

    if (shouldRefresh && mounted) {
      ref.invalidate(bankCardCountProvider);
      ref.invalidate(memberCardCountProvider);
      ref.invalidate(idCardCountProvider);
      ref.invalidate(favoriteCountProvider);
      ref.invalidate(recentViewedProvider);
    }
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionItem(this.label, this.icon, this.color, this.onTap);
}
