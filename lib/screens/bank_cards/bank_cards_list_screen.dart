import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';
import 'package:personal_cards_manager/screens/bank_cards/bank_card_form_screen.dart';
import 'package:personal_cards_manager/screens/bank_cards/bank_card_detail_screen.dart';

enum _FilterMode { all, favorites, expiring }
enum _SortMode { addedDesc, nameAsc, expiryAsc }

class BankCardsListScreen extends ConsumerStatefulWidget {
  const BankCardsListScreen({super.key});

  @override
  ConsumerState<BankCardsListScreen> createState() => _BankCardsListScreenState();
}

class _BankCardsListScreenState extends ConsumerState<BankCardsListScreen> {
  _FilterMode _filterMode = _FilterMode.all;
  _SortMode _sortMode = _SortMode.addedDesc;

  Future<List<BankCard>> _loadCards(Isar isar) async {
    List<BankCard> cards = await isar.bankCards.where().findAll();
    cards = cards.where((c) => !c.isArchived).toList();

    // 过滤
    if (_filterMode == _FilterMode.favorites) {
      cards = cards.where((c) => c.isFavorite).toList();
    } else if (_filterMode == _FilterMode.expiring) {
      final now = DateTime.now();
      final threshold = now.add(const Duration(days: 30));
      cards = cards.where((c) {
        if (c.expMonth != null && c.expYear != null) {
          final expiry = DateTime(c.expYear!, c.expMonth! + 1, 0);
          return expiry.isBefore(threshold);
        }
        return false;
      }).toList();
    }

    // 排序
    if (_sortMode == _SortMode.addedDesc) {
      cards.sort((a, b) => b.id.compareTo(a.id));
    } else if (_sortMode == _SortMode.nameAsc) {
      cards.sort((a, b) => (a.cardName ?? a.issuerName ?? '').compareTo(b.cardName ?? b.issuerName ?? ''));
    } else if (_sortMode == _SortMode.expiryAsc) {
      cards.sort((a, b) {
        final dateA = (a.expMonth != null && a.expYear != null) ? DateTime(a.expYear!, a.expMonth! + 1, 0) : DateTime(2100);
        final dateB = (b.expMonth != null && b.expYear != null) ? DateTime(b.expYear!, b.expMonth! + 1, 0) : DateTime(2100);
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
        title: const Text('银行卡'),
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
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const BankCardFormScreen()));
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
              data: (isar) => FutureBuilder<List<BankCard>>(
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
          Icon(Icons.credit_card_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _filterMode == _FilterMode.all ? '暂无银行卡' : '没有符合的银行卡',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(BankCard card) {
    Color getNetworkColor(String? network) {
      switch (network?.toLowerCase()) {
        case 'visa': return Colors.blue;
        case 'mastercard': return Colors.orange;
        case 'unionpay': return Colors.red;
        case 'amex': return Colors.green;
        default: return Colors.blueGrey;
      }
    }

    final maskedNumber = card.fullNumber != null && card.fullNumber!.length >= 4
        ? '**** **** **** ${card.fullNumber!.substring(card.fullNumber!.length - 4)}'
        : '****';
    final cardColor = getNetworkColor(card.network);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => BankCardDetailScreen(card: card)));
          setState(() {});
        },
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [cardColor.withValues(alpha: 0.8), cardColor],
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
                      card.cardName?.isNotEmpty == true ? card.cardName! : card.issuerName ?? '银行卡',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (card.isFavorite) const Icon(Icons.star, color: Colors.amber, size: 20),
                ],
              ),
              const Spacer(),
              Text(maskedNumber, style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2, fontFamily: 'monospace')),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(card.holderName ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  if (card.expMonth != null && card.expYear != null)
                    Text('${card.expMonth.toString().padLeft(2, '0')}/${card.expYear.toString().substring(2)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
