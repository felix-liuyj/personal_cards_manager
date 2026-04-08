import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';
import 'package:personal_cards_manager/screens/bank_cards/bank_cards_list_screen.dart';
import 'package:personal_cards_manager/screens/member_cards/member_cards_list_screen.dart';
import 'package:personal_cards_manager/screens/documents/documents_list_screen.dart';
import 'package:personal_cards_manager/screens/bank_cards/bank_card_form_screen.dart';
import 'package:personal_cards_manager/screens/member_cards/member_card_form_screen.dart';
import 'package:personal_cards_manager/screens/documents/id_card_form_screen.dart';

final bankCardCountProvider = FutureProvider<int>((ref) async {
  final isar = await ref.watch(localDbProvider.future);
  return await isar.bankCards.count();
});

final memberCardCountProvider = FutureProvider<int>((ref) async {
  final isar = await ref.watch(localDbProvider.future);
  return await isar.memberCards.count();
});

final idCardCountProvider = FutureProvider<int>((ref) async {
  final isar = await ref.watch(localDbProvider.future);
  return await isar.iDCards.count();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bankCardCount = ref.watch(bankCardCountProvider);
    final memberCardCount = ref.watch(memberCardCountProvider);
    final idCardCount = ref.watch(idCardCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('卡片管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to search
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bankCardCountProvider);
          ref.invalidate(memberCardCountProvider);
          ref.invalidate(idCardCountProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewSection(
                context,
                ref,
                bankCardCount,
                memberCardCount,
                idCardCount,
              ),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildRecentSection(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOverviewSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<int> bankCardCount,
    AsyncValue<int> memberCardCount,
    AsyncValue<int> idCardCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('概览', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                '银行卡',
                bankCardCount,
                Icons.credit_card,
                Colors.blue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BankCardsListScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                '会员卡',
                memberCardCount,
                Icons.card_membership,
                Colors.orange,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MemberCardsListScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                '证件',
                idCardCount,
                Icons.badge,
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DocumentsListScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                '收藏',
                const AsyncValue.data(0),
                Icons.star,
                Colors.amber,
                null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    AsyncValue<int> count,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              count.when(
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => const Text('-'),
                data: (value) => Text(
                  value.toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('快捷操作', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionButton(
              context,
              '添加银行卡',
              Icons.add_card,
              Colors.blue,
              () => _addBankCard(context),
            ),
            _buildActionButton(
              context,
              '添加会员卡',
              Icons.card_membership,
              Colors.orange,
              () => _addMemberCard(context),
            ),
            _buildActionButton(
              context,
              '添加证件',
              Icons.badge,
              Colors.green,
              () => _addDocument(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('最近使用', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        const Center(
          child: Padding(padding: EdgeInsets.all(24), child: Text('暂无最近使用记录')),
        ),
      ],
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_card),
              title: const Text('添加银行卡'),
              onTap: () {
                Navigator.pop(context);
                _addBankCard(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_membership),
              title: const Text('添加会员卡'),
              onTap: () {
                Navigator.pop(context);
                _addMemberCard(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text('添加证件'),
              onTap: () {
                Navigator.pop(context);
                _addDocument(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addBankCard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BankCardFormScreen()),
    );
  }

  void _addMemberCard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MemberCardFormScreen()),
    );
  }

  void _addDocument(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IDCardFormScreen()),
    );
  }
}
