import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_cards_manager/core/database/database_service.dart';
import 'package:personal_cards_manager/models/member_card.dart';

class MemberCardsListScreen extends ConsumerStatefulWidget {
  const MemberCardsListScreen({super.key});

  @override
  ConsumerState<MemberCardsListScreen> createState() =>
      _MemberCardsListScreenState();
}

class _MemberCardsListScreenState extends ConsumerState<MemberCardsListScreen> {
  List<MemberCard> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    final cards = await DatabaseService.instance.getAllMemberCards();
    setState(() {
      _cards = cards;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('会员卡'),
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
        ],
      ),
    );
  }

  Widget _buildCardItem(MemberCard card) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange,
          child: Text(
            card.brandName.isNotEmpty ? card.brandName[0] : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(card.cardName.isNotEmpty ? card.cardName : card.brandName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('会员号: ${card.memberNumber}'),
            if (card.memberLevel.isNotEmpty) Text('等级: ${card.memberLevel}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (card.hasBarcode) const Icon(Icons.qr_code, size: 20),
            if (card.isFavorite)
              const Icon(Icons.star, color: Colors.amber, size: 20),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => _viewCard(card),
      ),
    );
  }

  void _addCard() {
    // TODO: Navigate to add card screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('添加会员卡功能开发中')));
  }

  void _viewCard(MemberCard card) {
    // TODO: Navigate to card detail screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('查看卡片: ${card.cardName}')));
  }
}
