import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';
import 'package:personal_cards_manager/screens/documents/id_card_form_screen.dart';
import 'package:personal_cards_manager/screens/documents/document_detail_screen.dart';

enum _FilterMode { all, favorites, expiring }
enum _SortMode { addedDesc, nameAsc, expiryAsc }

class DocumentsListScreen extends ConsumerStatefulWidget {
  const DocumentsListScreen({super.key});

  @override
  ConsumerState<DocumentsListScreen> createState() => _DocumentsListScreenState();
}

class _DocumentsListScreenState extends ConsumerState<DocumentsListScreen> {
  _FilterMode _filterMode = _FilterMode.all;
  _SortMode _sortMode = _SortMode.addedDesc;

  Future<List<IDCard>> _loadCards(Isar isar) async {
    List<IDCard> cards = await isar.iDCards.where().findAll();
    cards = cards.where((c) => !c.isArchived).toList();

    // 过滤
    if (_filterMode == _FilterMode.favorites) {
      cards = cards.where((c) => c.isFavorite).toList();
    } else if (_filterMode == _FilterMode.expiring) {
      final now = DateTime.now();
      final threshold = now.add(const Duration(days: 30));
      cards = cards.where((c) {
        if (c.expireDate != null) {
          return c.expireDate!.isBefore(threshold);
        }
        return false;
      }).toList();
    }

    // 排序
    if (_sortMode == _SortMode.addedDesc) {
      cards.sort((a, b) => b.id.compareTo(a.id));
    } else if (_sortMode == _SortMode.nameAsc) {
      cards.sort((a, b) => (a.cardName ?? a.fullName ?? '').compareTo(b.cardName ?? b.fullName ?? ''));
    } else if (_sortMode == _SortMode.expiryAsc) {
      cards.sort((a, b) {
        final dateA = a.expireDate ?? DateTime(2100);
        final dateB = b.expireDate ?? DateTime(2100);
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
        title: const Text('证件'),
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
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const IDCardFormScreen()));
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
              data: (isar) => FutureBuilder<List<IDCard>>(
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
          Icon(Icons.badge, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _filterMode == _FilterMode.all ? '暂无证件' : '没有符合的证件',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(IDCard card) {
    Color getColor(String? type) {
      switch (type) {
        case 'ID': return Colors.blue;
        case 'PASSPORT': return Colors.indigo;
        case 'DRIVER_LICENSE': return Colors.green;
        case 'HK_MACAU_PASS': return Colors.purple;
        case 'TAIWAN_PASS': return Colors.teal;
        case 'RESIDENCE_PERMIT': return Colors.lightBlue;
        case 'SOCIAL_SECURITY': return Colors.cyan;
        case 'STUDENT_ID': return Colors.amber;
        case 'WORK_PERMIT': return Colors.brown;
        default: return Colors.blueGrey;
      }
    }

    String getTypeName(String? type) {
      switch (type) {
        case 'ID': return '居民身份证';
        case 'PASSPORT': return '护照';
        case 'DRIVER_LICENSE': return '驾驶证';
        case 'HK_MACAU_PASS': return '港澳通行证';
        case 'TAIWAN_PASS': return '台湾通行证';
        case 'RESIDENCE_PERMIT': return '居住证';
        case 'SOCIAL_SECURITY': return '社保卡';
        case 'STUDENT_ID': return '学生证';
        case 'WORK_PERMIT': return '工作证';
        default: return '其他证件';
      }
    }

    final maskedNumber = card.documentNumber != null && card.documentNumber!.length >= 4
        ? '**** **** **** ${card.documentNumber!.substring(card.documentNumber!.length - 4)}'
        : '****';
    final cardColor = getColor(card.documentType);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentDetailScreen(card: card)));
          setState(() {});
        },
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [cardColor.withOpacity(0.8), cardColor],
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
                      getTypeName(card.documentType),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (card.isFavorite) const Icon(Icons.star, color: Colors.amber, size: 20),
                ],
              ),
              const Spacer(),
              Text(card.fullName ?? '未填写姓名', style: const TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(maskedNumber, style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'monospace')),
                  if (card.expireDate != null)
                    Text('至 ${card.expireDate!.year}-${card.expireDate!.month.toString().padLeft(2, '0')}',
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
