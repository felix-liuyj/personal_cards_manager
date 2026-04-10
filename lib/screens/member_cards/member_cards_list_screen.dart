import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';
import 'package:personal_cards_manager/screens/member_cards/member_card_form_screen.dart';
import 'package:personal_cards_manager/screens/member_cards/member_card_detail_screen.dart';

enum _FilterMode { all, favorites, expiring }
enum _SortMode { addedDesc, nameAsc, expiryAsc }

class MemberCardsListScreen extends ConsumerStatefulWidget {
  const MemberCardsListScreen({super.key});

  @override
  ConsumerState<MemberCardsListScreen> createState() => _MemberCardsListScreenState();
}

class _MemberCardsListScreenState extends ConsumerState<MemberCardsListScreen> {
  _FilterMode _filterMode = _FilterMode.all;
  _SortMode _sortMode = _SortMode.addedDesc;

  Future<List<MemberCard>> _loadCards(Isar isar) async {
    List<MemberCard> cards = await isar.memberCards.where().findAll();
    cards = cards.where((c) => !c.isArchived).toList();

    // 过滤
    if (_filterMode == _FilterMode.favorites) {
      cards = cards.where((c) => c.isFavorite).toList();
    } else if (_filterMode == _FilterMode.expiring) {
      final now = DateTime.now();
      final threshold = now.add(const Duration(days: 30));
      cards = cards.where((c) {
        if (c.validUntil != null) {
          return c.validUntil!.isBefore(threshold);
        }
        return false;
      }).toList();
    }

    // 排序
    if (_sortMode == _SortMode.addedDesc) {
      cards.sort((a, b) => b.id.compareTo(a.id));
    } else if (_sortMode == _SortMode.nameAsc) {
      cards.sort((a, b) => (a.cardName ?? a.brand ?? '').compareTo(b.cardName ?? b.brand ?? ''));
    } else if (_sortMode == _SortMode.expiryAsc) {
      cards.sort((a, b) {
        final dateA = a.validUntil ?? DateTime(2100);
        final dateB = b.validUntil ?? DateTime(2100);
        return dateA.compareTo(dateB);
      });
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    final isarAsync = ref.watch(localDbProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('会员卡'),
        actions: [
          PopupMenuButton<_SortMode>(
            icon: const Icon(Icons.sort),
            onSelected: (mode) => setState(() => _sortMode = mode),
            itemBuilder: (_) => [
              PopupMenuItem(value: _SortMode.addedDesc, child: _buildSortItem('按添加时间 (最新)', _SortMode.addedDesc)),
              PopupMenuItem(value: _SortMode.nameAsc, child: _buildSortItem('按名称 (A-Z)', _SortMode.nameAsc)),
              PopupMenuItem(value: _SortMode.expiryAsc, child: _buildSortItem('按到期时间 (最近)', _SortMode.expiryAsc)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberCardFormScreen()));
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<_FilterMode>(
              segments: const [
                ButtonSegment(value: _FilterMode.all, label: Text('全部')),
                ButtonSegment(value: _FilterMode.favorites, label: Text('收藏'), icon: Icon(Icons.star, size: 16)),
                ButtonSegment(value: _FilterMode.expiring, label: Text('将到期'), icon: Icon(Icons.warning, size: 16)),
              ],
              selected: {_filterMode},
              onSelectionChanged: (s) => setState(() => _filterMode = s.first),
              style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          ),
          Expanded(
            child: isarAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('错误: $err')),
              data: (isar) => FutureBuilder<List<MemberCard>>(
                future: _loadCards(isar),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final cards = snapshot.data ?? [];
                  if (cards.isEmpty) return _buildEmptyState();

                  return RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: cards.length,
                      itemBuilder: (_, i) => _buildCardItem(cards[i]),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortItem(String title, _SortMode mode) {
    return Row(
      children: [
        Icon(_sortMode == mode ? Icons.check : null, size: 18),
        const SizedBox(width: 8),
        Text(title),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_membership, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _filterMode == _FilterMode.all ? '暂无会员卡' : '没有符合的会员卡',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(MemberCard card) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => MemberCardDetailScreen(card: card)));
          setState(() {});
        },
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8F00), Color(0xFFE65100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      card.brand ?? '未知品牌',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (card.isFavorite) const Icon(Icons.star, color: Colors.amber, size: 20),
                ],
              ),
              if (card.cardName?.isNotEmpty == true)
                Text(card.cardName!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const Spacer(),
              Text(card.memberNumber ?? 'NO NUMBER', style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 1.5, fontFamily: 'monospace')),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (card.tierCode?.isNotEmpty == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                      child: Text(card.tierCode!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    )
                  else
                    const SizedBox.shrink(),
                  if (card.validUntil != null)
                    Text('至 ${card.validUntil!.year}-${card.validUntil!.month.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
