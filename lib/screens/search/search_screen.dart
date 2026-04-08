import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _results = [];
  bool _isSearching = false;

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);

    final isar = await ref.read(localDbProvider.future);
    final lowerQuery = query.toLowerCase();

    final allBankCards = await isar.bankCards.where().findAll();
    final allMemberCards = await isar.memberCards.where().findAll();
    final allDocuments = await isar.iDCards.where().findAll();

    final bankCards = allBankCards.where((card) {
      return (card.issuerName?.toLowerCase().contains(lowerQuery) ?? false) ||
          (card.aliasName?.toLowerCase().contains(lowerQuery) ?? false) ||
          (card.holderName?.toLowerCase().contains(lowerQuery) ?? false) ||
          (card.fullNumber?.contains(query) ?? false);
    }).toList();

    final memberCards = allMemberCards.where((card) {
      return (card.brand?.toLowerCase().contains(lowerQuery) ?? false) ||
          (card.memberNumber?.contains(query) ?? false) ||
          (card.aliasName?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    final documents = allDocuments.where((doc) {
      return (doc.cardName?.toLowerCase().contains(lowerQuery) ?? false) ||
          (doc.fullName?.toLowerCase().contains(lowerQuery) ?? false) ||
          (doc.documentNumber?.contains(query) ?? false);
    }).toList();

    setState(() {
      _results = [...bankCards, ...memberCards, ...documents];
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '搜索卡片、证件...',
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _results = []);
              },
            ),
        ],
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
          ? _buildEmptyState()
          : _buildSearchResults(),
    );
  }

  Widget _buildEmptyState() {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '搜索银行卡、会员卡、证件',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '未找到相关结果',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        return _buildResultItem(item);
      },
    );
  }

  Widget _buildResultItem(dynamic item) {
    String title = '';
    String subtitle = '';
    IconData icon = Icons.credit_card;

    if (item is BankCard) {
      title = item.cardName?.isNotEmpty == true
          ? item.cardName!
          : item.issuerName ?? '';
      final maskedNumber =
          item.fullNumber != null && item.fullNumber!.length >= 4
          ? '**** **** **** ${item.fullNumber!.substring(item.fullNumber!.length - 4)}'
          : '****';
      subtitle = maskedNumber;
      icon = Icons.credit_card;
    } else if (item is MemberCard) {
      title = item.cardName?.isNotEmpty == true
          ? item.cardName!
          : item.brand ?? '';
      subtitle = '会员号: ${item.memberNumber ?? ''}';
      icon = Icons.card_membership;
    } else if (item is IDCard) {
      title = item.cardName?.isNotEmpty == true
          ? item.cardName!
          : item.fullName ?? '';
      final maskedNumber =
          item.documentNumber != null && item.documentNumber!.length >= 4
          ? '**** **** **** ${item.documentNumber!.substring(item.documentNumber!.length - 4)}'
          : '****';
      subtitle = maskedNumber;
      icon = Icons.badge;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon, size: 20)),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('查看: $title')));
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
