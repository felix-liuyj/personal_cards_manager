import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';
import 'package:personal_cards_manager/screens/member_cards/member_card_form_screen.dart';

class MemberCardsListScreen extends ConsumerStatefulWidget {
  const MemberCardsListScreen({super.key});

  @override
  ConsumerState<MemberCardsListScreen> createState() =>
      _MemberCardsListScreenState();
}

class _MemberCardsListScreenState extends ConsumerState<MemberCardsListScreen> {
  Future<List<MemberCard>> _loadCards(Isar isar) async {
    return await isar.memberCards.where().findAll();
  }

  @override
  Widget build(BuildContext context) {
    final isarAsync = ref.watch(localDbProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('会员卡'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _addCard()),
        ],
      ),
      body: isarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('错误: $err')),
        data: (isar) => FutureBuilder<List<MemberCard>>(
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
          Icon(Icons.card_membership, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '暂无会员卡',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角 + 添加会员卡',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addCard,
            icon: const Icon(Icons.add),
            label: const Text('添加会员卡'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(MemberCard card) {
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
                    backgroundColor: Colors.orange,
                    child: Text(
                      (card.brand?.isNotEmpty == true) ? card.brand![0] : '?',
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
                              : card.brand ?? '未命名',
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
                    '会员号: ${card.memberNumber ?? '未设置'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  if (card.tierCode?.isNotEmpty == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        card.tierCode!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              if (card.barcodeData?.isNotEmpty == true ||
                  card.qrcodeData?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      if (card.barcodeData?.isNotEmpty == true)
                        const Icon(
                          Icons.qr_code_2,
                          size: 16,
                          color: Colors.grey,
                        ),
                      if (card.qrcodeData?.isNotEmpty == true) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.qr_code, size: 16, color: Colors.grey),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _addCard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MemberCardFormScreen()),
    );
    if (result == true) {
      setState(() {});
    }
  }

  void _viewCard(MemberCard card) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MemberCardFormScreen(card: card)),
    );
    if (result == true) {
      setState(() {});
    }
  }
}
