import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';
import 'package:personal_cards_manager/screens/bank_cards/bank_card_detail_screen.dart';
import 'package:personal_cards_manager/screens/member_cards/member_card_detail_screen.dart';
import 'package:personal_cards_manager/screens/documents/document_detail_screen.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<BankCard> _bankCards = [];
  List<MemberCard> _memberCards = [];
  List<IDCard> _docs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final isar = await ref.read(localDbProvider.future);
    final banks = await isar.bankCards.where().findAll();
    final members = await isar.memberCards.where().findAll();
    final docs = await isar.iDCards.where().findAll();
    setState(() {
      _bankCards = banks.where((c) => c.isFavorite && !c.isArchived).toList();
      _memberCards = members.where((c) => c.isFavorite && !c.isArchived).toList();
      _docs = docs.where((c) => c.isFavorite && !c.isArchived).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _bankCards.length + _memberCards.length + _docs.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('收藏'),
            if (total > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$total',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ]
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.credit_card), text: '银行卡 ${_bankCards.length}'),
            Tab(icon: const Icon(Icons.card_membership), text: '会员卡 ${_memberCards.length}'),
            Tab(icon: const Icon(Icons.badge), text: '证件 ${_docs.length}'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBankList(),
          _buildMemberList(),
          _buildDocList(),
        ],
      ),
    );
  }

  Widget _buildBankList() {
    if (_bankCards.isEmpty) return _empty('暂无收藏的银行卡');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _bankCards.length,
        itemBuilder: (_, i) {
          final card = _bankCards[i];
          final masked = card.fullNumber != null && card.fullNumber!.length >= 4
              ? '**** ${card.fullNumber!.substring(card.fullNumber!.length - 4)}'
              : '****';
          return _tile(
            icon: Icons.credit_card,
            color: Colors.blue,
            title: card.cardName?.isNotEmpty == true ? card.cardName! : card.issuerName ?? '银行卡',
            subtitle: '${card.network ?? ''} · $masked',
            extra: card.holderName,
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => BankCardDetailScreen(card: card)));
              _load();
            },
          );
        },
      ),
    );
  }

  Widget _buildMemberList() {
    if (_memberCards.isEmpty) return _empty('暂无收藏的会员卡');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _memberCards.length,
        itemBuilder: (_, i) {
          final card = _memberCards[i];
          return _tile(
            icon: Icons.card_membership,
            color: Colors.orange,
            title: card.cardName?.isNotEmpty == true ? card.cardName! : card.brand ?? '会员卡',
            subtitle: '会员号: ${card.memberNumber ?? '未设置'}',
            extra: card.tierCode?.isNotEmpty == true ? card.tierCode : null,
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => MemberCardDetailScreen(card: card)));
              _load();
            },
          );
        },
      ),
    );
  }

  Widget _buildDocList() {
    if (_docs.isEmpty) return _empty('暂无收藏的证件');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _docs.length,
        itemBuilder: (_, i) {
          final doc = _docs[i];
          final masked = doc.documentNumber != null && doc.documentNumber!.length >= 4
              ? '**** ${doc.documentNumber!.substring(doc.documentNumber!.length - 4)}'
              : '****';
          return _tile(
            icon: Icons.badge,
            color: Colors.green,
            title: doc.cardName?.isNotEmpty == true ? doc.cardName! : doc.fullName ?? '证件',
            subtitle: masked,
            extra: doc.documentType,
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => DocumentDetailScreen(card: doc)));
              _load();
            },
          );
        },
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    String? extra,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.15)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (extra != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(extra, style: const TextStyle(fontSize: 11, color: Colors.amber)),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.star, color: Colors.amber, size: 16),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _empty(String msg) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.star_border, size: 72, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(msg, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        Text(
          '在卡片详情页点击 ⭐ 即可添加收藏',
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
      ],
    ),
  );
}
