import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';
import 'package:personal_cards_manager/screens/bank_cards/bank_card_detail_screen.dart';
import 'package:personal_cards_manager/screens/member_cards/member_card_detail_screen.dart';
import 'package:personal_cards_manager/screens/documents/document_detail_screen.dart';

class ArchivedCardsScreen extends ConsumerStatefulWidget {
  const ArchivedCardsScreen({super.key});

  @override
  ConsumerState<ArchivedCardsScreen> createState() => _ArchivedCardsScreenState();
}

class _ArchivedCardsScreenState extends ConsumerState<ArchivedCardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isarAsync = ref.watch(localDbProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('归档'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.credit_card), text: '银行卡'),
            Tab(icon: Icon(Icons.card_membership), text: '会员卡'),
            Tab(icon: Icon(Icons.badge), text: '证件'),
          ],
        ),
      ),
      body: isarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (isar) => TabBarView(
          controller: _tabController,
          children: [
            _ArchivedBankCards(isar: isar),
            _ArchivedMemberCards(isar: isar),
            _ArchivedDocuments(isar: isar),
          ],
        ),
      ),
    );
  }
}

// ───── Bank Cards Tab ─────
class _ArchivedBankCards extends ConsumerStatefulWidget {
  final dynamic isar;
  const _ArchivedBankCards({required this.isar});

  @override
  ConsumerState<_ArchivedBankCards> createState() => _ArchivedBankCardsState();
}

class _ArchivedBankCardsState extends ConsumerState<_ArchivedBankCards> {
  List<BankCard> _cards = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await widget.isar.bankCards.where().findAll();
    setState(() => _cards = all.where((c) => c.isArchived).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) return _buildEmpty('暂无归档银行卡');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cards.length,
        itemBuilder: (_, i) => _buildItem(_cards[i]),
      ),
    );
  }

  Widget _buildItem(BankCard card) {
    final masked = card.fullNumber != null && card.fullNumber!.length >= 4
        ? '**** ${card.fullNumber!.substring(card.fullNumber!.length - 4)}'
        : '****';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.credit_card)),
        title: Text(card.cardName?.isNotEmpty == true ? card.cardName! : card.issuerName ?? '银行卡'),
        subtitle: Text(masked),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final result = await Navigator.push<bool>(context,
              MaterialPageRoute(builder: (_) => BankCardDetailScreen(card: card)));
          if (result == true) _load();
        },
      ),
    );
  }
}

// ───── Member Cards Tab ─────
class _ArchivedMemberCards extends ConsumerStatefulWidget {
  final dynamic isar;
  const _ArchivedMemberCards({required this.isar});

  @override
  ConsumerState<_ArchivedMemberCards> createState() => _ArchivedMemberCardsState();
}

class _ArchivedMemberCardsState extends ConsumerState<_ArchivedMemberCards> {
  List<MemberCard> _cards = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await widget.isar.memberCards.where().findAll();
    setState(() => _cards = all.where((c) => c.isArchived).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) return _buildEmpty('暂无归档会员卡');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cards.length,
        itemBuilder: (_, i) => _buildItem(_cards[i]),
      ),
    );
  }

  Widget _buildItem(MemberCard card) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.card_membership)),
      title: Text(card.cardName?.isNotEmpty == true ? card.cardName! : card.brand ?? '会员卡'),
      subtitle: Text('会员号: ${card.memberNumber ?? '未设置'}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final result = await Navigator.push<bool>(context,
            MaterialPageRoute(builder: (_) => MemberCardDetailScreen(card: card)));
        if (result == true) _load();
      },
    ),
  );
}

// ───── Documents Tab ─────
class _ArchivedDocuments extends ConsumerStatefulWidget {
  final dynamic isar;
  const _ArchivedDocuments({required this.isar});

  @override
  ConsumerState<_ArchivedDocuments> createState() => _ArchivedDocumentsState();
}

class _ArchivedDocumentsState extends ConsumerState<_ArchivedDocuments> {
  List<IDCard> _docs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await widget.isar.iDCards.where().findAll();
    setState(() => _docs = all.where((d) => d.isArchived).toList());
  }

  @override
  Widget build(BuildContext context) {
    if (_docs.isEmpty) return _buildEmpty('暂无归档证件');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _docs.length,
        itemBuilder: (_, i) => _buildItem(_docs[i]),
      ),
    );
  }

  Widget _buildItem(IDCard doc) {
    final masked = doc.documentNumber != null && doc.documentNumber!.length >= 4
        ? '**** ${doc.documentNumber!.substring(doc.documentNumber!.length - 4)}'
        : '****';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.badge)),
        title: Text(doc.cardName?.isNotEmpty == true ? doc.cardName! : doc.fullName ?? '证件'),
        subtitle: Text(masked),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final result = await Navigator.push<bool>(context,
              MaterialPageRoute(builder: (_) => DocumentDetailScreen(card: doc)));
          if (result == true) _load();
        },
      ),
    );
  }
}

// ───── Shared ─────
Widget _buildEmpty(String message) => Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.archive_outlined, size: 72, color: Colors.grey[300]),
      const SizedBox(height: 16),
      Text(message, style: const TextStyle(color: Colors.grey)),
    ],
  ),
);
