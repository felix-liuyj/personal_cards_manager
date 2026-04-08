import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_cards_manager/core/database/database_service.dart';
import 'package:personal_cards_manager/models/bank_card.dart';

class BankCardsListScreen extends ConsumerStatefulWidget {
  const BankCardsListScreen({super.key});

  @override
  ConsumerState<BankCardsListScreen> createState() =>
      _BankCardsListScreenState();
}

class _BankCardsListScreenState extends ConsumerState<BankCardsListScreen> {
  List<BankCard> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    final cards = await DatabaseService.instance.getAllBankCards();
    setState(() {
      _cards = cards;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('银行卡'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _addCard)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadCards,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  return _buildCardItem(_cards[index]);
                },
              ),
            ),
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
            '暂无银行卡',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角 + 添加银行卡',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(BankCard card) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCardColor(card.cardOrganization),
          child: Text(
            card.issuerName.isNotEmpty ? card.issuerName[0] : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(card.cardName.isNotEmpty ? card.cardName : card.issuerName),
        subtitle: Text(card.maskedNumber),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (card.isFavorite)
              const Icon(Icons.star, color: Colors.amber, size: 20),
            if (card.isArchived)
              const Icon(Icons.archive, color: Colors.grey, size: 20),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => _viewCard(card),
      ),
    );
  }

  Color _getCardColor(String organization) {
    switch (organization.toLowerCase()) {
      case 'visa':
        return Colors.blue;
      case 'mastercard':
        return Colors.orange;
      case 'unionpay':
        return Colors.red;
      case 'amex':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _addCard() {
    // TODO: Navigate to add card screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('添加银行卡功能开发中')));
  }

  void _viewCard(BankCard card) {
    // TODO: Navigate to card detail screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('查看卡片: ${card.cardName}')));
  }
}
