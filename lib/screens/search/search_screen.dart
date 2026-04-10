import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';
import 'package:personal_cards_manager/screens/bank_cards/bank_card_detail_screen.dart';
import 'package:personal_cards_manager/screens/member_cards/member_card_detail_screen.dart';
import 'package:personal_cards_manager/screens/documents/document_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  List<BankCard> _bankCardResults = [];
  List<MemberCard> _memberCardResults = [];
  List<IDCard> _documentResults = [];
  bool _isSearching = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _bankCardResults = [];
        _memberCardResults = [];
        _documentResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    final isar = await ref.read(localDbProvider.future);
    final lq = query.toLowerCase().trim();

    final allBankCards = await isar.bankCards.where().findAll();
    final allMemberCards = await isar.memberCards.where().findAll();
    final allDocuments = await isar.iDCards.where().findAll();

    final bankCards = allBankCards.where((card) {
      return (card.issuerName?.toLowerCase().contains(lq) ?? false) ||
          (card.cardName?.toLowerCase().contains(lq) ?? false) ||
          (card.aliasName?.toLowerCase().contains(lq) ?? false) ||
          (card.holderName?.toLowerCase().contains(lq) ?? false) ||
          (card.fullNumber?.contains(query) ?? false) ||
          (card.note?.toLowerCase().contains(lq) ?? false) ||
          (card.country?.toLowerCase().contains(lq) ?? false) ||
          (card.currency?.toLowerCase().contains(lq) ?? false);
    }).toList();

    final memberCards = allMemberCards.where((card) {
      return (card.brand?.toLowerCase().contains(lq) ?? false) ||
          (card.cardName?.toLowerCase().contains(lq) ?? false) ||
          (card.memberNumber?.contains(query) ?? false) ||
          (card.aliasName?.toLowerCase().contains(lq) ?? false) ||
          (card.tierCode?.toLowerCase().contains(lq) ?? false) ||
          (card.note?.toLowerCase().contains(lq) ?? false);
    }).toList();

    final documents = allDocuments.where((doc) {
      return (doc.cardName?.toLowerCase().contains(lq) ?? false) ||
          (doc.fullName?.toLowerCase().contains(lq) ?? false) ||
          (doc.englishName?.toLowerCase().contains(lq) ?? false) ||
          (doc.documentNumber?.contains(query) ?? false) ||
          (doc.issueAuthority?.toLowerCase().contains(lq) ?? false) ||
          (doc.note?.toLowerCase().contains(lq) ?? false);
    }).toList();

    setState(() {
      _bankCardResults = bankCards;
      _memberCardResults = memberCards;
      _documentResults = documents;
      _isSearching = false;
    });
  }

  int get _totalCount =>
      _bankCardResults.length + _memberCardResults.length + _documentResults.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '搜索卡片、会员卡、证件...',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _search('');
                    },
                  )
                : null,
          ),
          onChanged: _search,
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _searchController.text.isEmpty
          ? _buildInitialState()
          : _totalCount == 0
          ? _buildNoResults()
          : _buildResults(),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '搜索银行卡、会员卡、证件',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '支持按名称、编号、备注等关键字搜索',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '未找到「${_searchController.text}」相关结果',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_bankCardResults.isNotEmpty) ..._buildBankCardSection(),
        if (_memberCardResults.isNotEmpty) ..._buildMemberCardSection(),
        if (_documentResults.isNotEmpty) ..._buildDocumentSection(),
      ],
    );
  }

  List<Widget> _buildBankCardSection() {
    return [
      _buildSectionHeader('银行卡', Icons.credit_card, Colors.blue, _bankCardResults.length),
      ..._bankCardResults.map((card) {
        final maskedNumber = card.fullNumber != null && card.fullNumber!.length >= 4
            ? '**** ${card.fullNumber!.substring(card.fullNumber!.length - 4)}'
            : '****';
        return _buildResultTile(
          icon: Icons.credit_card,
          iconColor: Colors.blue,
          title: card.cardName?.isNotEmpty == true
              ? card.cardName!
              : card.issuerName ?? '银行卡',
          subtitle: '${card.network ?? ''} · $maskedNumber',
          tag: card.isFavorite ? '收藏' : null,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BankCardDetailScreen(card: card),
            ),
          ),
        );
      }),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildMemberCardSection() {
    return [
      _buildSectionHeader('会员卡', Icons.card_membership, Colors.orange, _memberCardResults.length),
      ..._memberCardResults.map((card) {
        return _buildResultTile(
          icon: Icons.card_membership,
          iconColor: Colors.orange,
          title: card.cardName?.isNotEmpty == true
              ? card.cardName!
              : card.brand ?? '会员卡',
          subtitle: '会员号: ${card.memberNumber ?? '未设置'}',
          tag: card.tierCode?.isNotEmpty == true ? card.tierCode : null,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MemberCardDetailScreen(card: card),
            ),
          ),
        );
      }),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildDocumentSection() {
    return [
      _buildSectionHeader('证件', Icons.badge, Colors.green, _documentResults.length),
      ..._documentResults.map((doc) {
        final maskedNumber = doc.documentNumber != null && doc.documentNumber!.length >= 4
            ? '**** ${doc.documentNumber!.substring(doc.documentNumber!.length - 4)}'
            : '****';
        return _buildResultTile(
          icon: Icons.badge,
          iconColor: Colors.green,
          title: doc.cardName?.isNotEmpty == true
              ? doc.cardName!
              : doc.fullName ?? '证件',
          subtitle: maskedNumber,
          tag: doc.isFavorite ? '收藏' : null,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DocumentDetailScreen(card: doc),
            ),
          ),
        );
      }),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? tag,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.85),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.15),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: tag != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag, style: const TextStyle(fontSize: 11, color: Colors.amber)),
              )
            : const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

