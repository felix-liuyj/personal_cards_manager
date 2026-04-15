import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';
import 'package:personal_cards_manager/features/clipboard/clipboard_service.dart';
import 'package:personal_cards_manager/features/home/recent_usage_service.dart';
import 'package:personal_cards_manager/screens/bank_cards/bank_card_form_screen.dart';

class BankCardDetailScreen extends ConsumerStatefulWidget {
  final BankCard card;

  const BankCardDetailScreen({super.key, required this.card});

  @override
  ConsumerState<BankCardDetailScreen> createState() => _BankCardDetailScreenState();
}

class _BankCardDetailScreenState extends ConsumerState<BankCardDetailScreen> {
  late BankCard _card;
  bool _showSensitiveInfo = false;

  @override
  void initState() {
    super.initState();
    _card = widget.card;
    _recordView();
  }

  Future<void> _recordView() async {
    await ref.read(recentUsageServiceProvider).recordViewed(
      type: 'bank',
      id: _card.id,
      title: _card.cardName?.isNotEmpty == true
          ? _card.cardName!
          : _card.issuerName ?? '银行卡',
    );
  }

  Future<void> _copy(String text, String label) async {
    if (text.isEmpty) return;
    await ref.read(clipboardServiceProvider).copy(text);
    await ref.read(recentUsageServiceProvider).recordCopied(
      type: 'bank', id: _card.id,
      title: _card.cardName?.isNotEmpty == true ? _card.cardName! : _card.issuerName ?? '银行卡',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已复制 $label')));
    }
  }

  void _editCard() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => BankCardFormScreen(card: _card)),
    );
    if (result == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _toggleFavorite() async {
    final isar = await ref.read(localDbProvider.future);
    _card.isFavorite = !_card.isFavorite;
    await isar.writeTxn(() async => isar.bankCards.put(_card));
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_card.isFavorite ? '已添加收藏' : '已取消收藏')),
      );
    }
  }

  Future<void> _toggleArchive() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_card.isArchived ? '取消归档' : '归档银行卡'),
        content: Text(_card.isArchived
            ? '将此卡片从归档列表恢复到主列表？'
            : '将此卡片移入归档，它将从主列表中隐藏。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_card.isArchived ? '取消归档' : '归档'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final isar = await ref.read(localDbProvider.future);
    _card.isArchived = !_card.isArchived;
    await isar.writeTxn(() async => isar.bankCards.put(_card));
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除银行卡'),
        content: const Text('此操作不可恢复，确定要永久删除这张银行卡吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final isar = await ref.read(localDbProvider.future);
    await isar.writeTxn(() async => isar.bankCards.delete(_card.id));
    if (mounted) Navigator.pop(context, true);
  }

  Color _getCardColor(String? network) {
    switch (network?.toLowerCase()) {
      case 'visa': return Colors.blue;
      case 'mastercard': return Colors.deepOrange;
      case 'unionpay': return Colors.red;
      case 'amex': return Colors.green;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('银行卡详情'),
        actions: [
          IconButton(
            icon: Icon(_card.isFavorite ? Icons.star : Icons.star_border,
                color: _card.isFavorite ? Colors.amber : null),
            onPressed: _toggleFavorite,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') _editCard();
              if (v == 'archive') _toggleArchive();
              if (v == 'delete') _delete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: ListTile(
                leading: Icon(Icons.edit), title: Text('编辑'), dense: true)),
              PopupMenuItem(
                value: 'archive',
                child: ListTile(
                  leading: Icon(_card.isArchived ? Icons.unarchive : Icons.archive),
                  title: Text(_card.isArchived ? '取消归档' : '归档'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(value: 'delete', child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('删除', style: TextStyle(color: Colors.red)),
                dense: true,
              )),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_card.isArchived)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.archive, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Text('此卡片已归档', style: TextStyle(color: Colors.orange)),
              ]),
            ),
          _buildCardVisual(),
          const SizedBox(height: 16),
          _buildControlRow(),
          const SizedBox(height: 16),
          _buildSectionTitle('支付信息'),
          _buildInfoRow('发卡行', _card.issuerName ?? '', '发卡行'),
          _buildInfoRow('卡组织', _card.network ?? '', '卡组织'),
          _buildInfoRow('持卡人', _card.holderName ?? '', '持卡人姓名'),
          _buildInfoRow('卡号', _card.fullNumber ?? '', '卡号', isSensitive: true),
          _buildInfoRow(
            '有效期',
            (_card.expMonth != null && _card.expYear != null)
                ? '${_card.expMonth.toString().padLeft(2, '0')}/${_card.expYear.toString().substring(2)}'
                : '',
            '有效期',
          ),
          _buildInfoRow('CVV', _card.cvv ?? '', 'CVV', isSensitive: true),
          if (_card.addressLine1?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('账单地址'),
            _buildInfoRow('地址第一行', _card.addressLine1 ?? '', '地址第一行'),
            if (_card.addressLine2?.isNotEmpty == true)
              _buildInfoRow('地址第二行', _card.addressLine2 ?? '', '地址第二行'),
            _buildInfoRow('城市', _card.city ?? '', '城市'),
            _buildInfoRow('州/省', _card.stateProvince ?? '', '州/省'),
            _buildInfoRow('邮编', _card.zipCode ?? '', '邮编'),
            _buildInfoRow('国家/地区', _card.country ?? '', '国家/地区'),
          ],
          const SizedBox(height: 16),
          _buildSectionTitle('其他信息'),
          _buildInfoRow('币种', _card.currency ?? '', '币种'),
          _buildInfoRow('备注', _card.note ?? '', '备注'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildControlRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: Icon(_showSensitiveInfo ? Icons.visibility_off : Icons.visibility, size: 18),
            label: Text(_showSensitiveInfo ? '隐藏敏感信息' : '显示敏感信息'),
            onPressed: () => setState(() => _showSensitiveInfo = !_showSensitiveInfo),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            icon: const Icon(Icons.copy_all, size: 18),
            label: const Text('复制支付信息'),
            onPressed: () {
              final expiry = (_card.expMonth != null && _card.expYear != null)
                  ? '${_card.expMonth.toString().padLeft(2, '0')}/${_card.expYear.toString().substring(2)}'
                  : '';
              final text = [
                _card.fullNumber ?? '',
                expiry,
                _card.cvv ?? '',
              ].where((s) => s.isNotEmpty).join('\n');
              _copy(text, '支付信息');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardVisual() {
    final color = _getCardColor(_card.network);
    final maskedNumber = _showSensitiveInfo
        ? (_card.fullNumber ?? '****')
        : (_card.fullNumber != null && _card.fullNumber!.length >= 4
            ? '**** **** **** ${_card.fullNumber!.substring(_card.fullNumber!.length - 4)}'
            : '****');

    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_card.issuerName ?? '未知发卡行',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(_card.network ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic)),
            ],
          ),
          const Spacer(),
          Text(
            maskedNumber,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, letterSpacing: 2, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_card.holderName?.toUpperCase() ?? 'YOUR NAME',
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
              Text(
                (_card.expMonth != null && _card.expYear != null)
                    ? '${_card.expMonth.toString().padLeft(2, '0')}/${_card.expYear.toString().substring(2)}'
                    : 'MM/YY',
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        )),
  );

  Widget _buildInfoRow(String label, String value, String copyLabel, {bool isSensitive = false}) {
    if (value.isEmpty) return const SizedBox.shrink();
    final display = (isSensitive && !_showSensitiveInfo) ? '•••' : value;

    return InkWell(
      onTap: () => _copy(value, copyLabel),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 96, child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]))),
            Expanded(child: Text(display, style: Theme.of(context).textTheme.bodyMedium)),
            Icon(Icons.copy, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
