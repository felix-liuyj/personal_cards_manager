import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';
import 'package:personal_cards_manager/screens/bank_cards/bank_card_form_screen.dart';
import 'package:personal_cards_manager/widgets/secure_text.dart';

class BankCardsListScreen extends ConsumerStatefulWidget {
  const BankCardsListScreen({super.key});

  @override
  ConsumerState<BankCardsListScreen> createState() =>
      _BankCardsListScreenState();
}

class _BankCardsListScreenState extends ConsumerState<BankCardsListScreen> {
  Future<List<BankCard>> _loadCards(Isar isar) async {
    return await isar.bankCards.where().findAll();
  }

  @override
  Widget build(BuildContext context) {
    final isarAsync = ref.watch(localDbProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('银行卡'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _addCard()),
        ],
      ),
      body: isarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('错误: $err')),
        data: (isar) => FutureBuilder<List<BankCard>>(
          future: _loadCards(isar),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final cards = snapshot.data ?? [];
            if (cards.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  return _buildCardItem(cards[index]);
                },
              ),
            );
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addCard,
            icon: const Icon(Icons.add),
            label: const Text('添加银行卡'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(BankCard card) {
    final maskedNumber = card.fullNumber != null && card.fullNumber!.length >= 4
        ? '**** **** **** ${card.fullNumber!.substring(card.fullNumber!.length - 4)}'
        : '****';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewCard(card),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getCardColor(card.network),
                    child: Text(
                      (card.issuerName?.isNotEmpty == true)
                          ? card.issuerName![0]
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.cardName?.isNotEmpty == true
                              ? card.cardName!
                              : card.issuerName ?? '未命名',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (card.aliasName?.isNotEmpty == true)
                          Text(
                            card.aliasName!,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  if (card.isFavorite)
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    maskedNumber,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  if (card.expMonth != null && card.expYear != null)
                    Text(
                      '${card.expMonth.toString().padLeft(2, '0')}/${card.expYear.toString().substring(2)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCardColor(String? network) {
    switch (network?.toLowerCase()) {
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

  void _addCard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BankCardFormScreen()),
    );
    if (result == true) {
      setState(() {});
    }
  }

  void _viewCard(BankCard card) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BankCardFormScreen(card: card)),
    );
    if (result == true) {
      setState(() {});
    }
  }
}
