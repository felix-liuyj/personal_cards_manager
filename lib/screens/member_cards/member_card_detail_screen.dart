import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';
import 'package:personal_cards_manager/features/clipboard/clipboard_service.dart';
import 'package:personal_cards_manager/features/home/recent_usage_service.dart';
import 'package:personal_cards_manager/screens/member_cards/member_card_form_screen.dart';

class MemberCardDetailScreen extends ConsumerStatefulWidget {
  final MemberCard card;

  const MemberCardDetailScreen({super.key, required this.card});

  @override
  ConsumerState<MemberCardDetailScreen> createState() => _MemberCardDetailScreenState();
}

class _MemberCardDetailScreenState extends ConsumerState<MemberCardDetailScreen> {
  late MemberCard _card;
  bool _showQr = false; // false = barcode, true = QR

  @override
  void initState() {
    super.initState();
    _card = widget.card;
    _recordView();
  }

  Future<void> _recordView() async {
    await ref.read(recentUsageServiceProvider).recordViewed(
      type: 'member',
      id: _card.id,
      title: _card.cardName?.isNotEmpty == true ? _card.cardName! : _card.brand ?? '会员卡',
    );
  }

  Future<void> _copy(String text, String label) async {
    if (text.isEmpty) return;
    await ref.read(clipboardServiceProvider).copy(text);
    await ref.read(recentUsageServiceProvider).recordCopied(
      type: 'member',
      id: _card.id,
      title: _card.cardName?.isNotEmpty == true ? _card.cardName! : _card.brand ?? '会员卡',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已复制 $label')));
    }
  }

  void _editCard() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MemberCardFormScreen(card: _card)),
    );
    if (result == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _toggleFavorite() async {
    final isar = await ref.read(localDbProvider.future);
    _card.isFavorite = !_card.isFavorite;
    await isar.writeTxn(() async => isar.memberCards.put(_card));
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
        title: Text(_card.isArchived ? '取消归档' : '归档会员卡'),
        content: Text(_card.isArchived ? '将此卡片恢复到主列表？' : '将此卡片移入归档，它将从主列表中隐藏。'),
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
    await isar.writeTxn(() async => isar.memberCards.put(_card));
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除会员卡'),
        content: const Text('此操作不可恢复，确定要永久删除？'),
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
    await isar.writeTxn(() async => isar.memberCards.delete(_card.id));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final hasBarcode = _card.barcodeData?.isNotEmpty == true;
    final hasQr = _card.qrcodeData?.isNotEmpty == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('会员卡详情'),
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
              PopupMenuItem(value: 'archive', child: ListTile(
                leading: Icon(_card.isArchived ? Icons.unarchive : Icons.archive),
                title: Text(_card.isArchived ? '取消归档' : '归档'), dense: true)),
              const PopupMenuItem(value: 'delete', child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('删除', style: TextStyle(color: Colors.red)), dense: true)),
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

          // 条码/二维码区域
          if (hasBarcode || hasQr) ...[
            if (hasBarcode && hasQr)
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('条形码'), icon: Icon(Icons.qr_code_2)),
                  ButtonSegment(value: true, label: Text('二维码'), icon: Icon(Icons.qr_code)),
                ],
                selected: {_showQr},
                onSelectionChanged: (s) => setState(() => _showQr = s.first),
              ),
            const SizedBox(height: 16),
            _buildCodeView(hasBarcode, hasQr),
            const SizedBox(height: 16),
          ],

          _buildSectionTitle('会员信息'),
          _buildInfoRow('品牌', _card.brand ?? '', '品牌名称'),
          _buildInfoRow('会员卡名称', _card.cardName ?? '', '会员卡名称'),
          _buildInfoRow('别名', _card.aliasName ?? '', '别名'),
          _buildInfoRow('会员编号', _card.memberNumber ?? '', '会员编号'),
          _buildInfoRow('会员等级', _card.tierCode ?? '', '会员等级'),
          _buildInfoRow('积分', _card.points?.toString() ?? '', '积分'),
          _buildInfoRow('绑定手机', _card.phoneNumber ?? '', '手机号'),
          _buildInfoRow(
            '有效期至',
            _card.validUntil != null
                ? '${_card.validUntil!.year}-${_card.validUntil!.month.toString().padLeft(2, '0')}-${_card.validUntil!.day.toString().padLeft(2, '0')}'
                : '永久',
            '有效期',
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('其他'),
          _buildInfoRow('备注', _card.note ?? '', '备注'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCardVisual() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8F00), Color(0xFFE65100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_card.brand ?? '未知品牌',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              if (_card.tierCode?.isNotEmpty == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                  child: Text(_card.tierCode!,
                      style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
            ],
          ),
          const Spacer(),
          Text(_card.cardName?.isNotEmpty == true ? _card.cardName! : '普通会员卡',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(_card.memberNumber ?? 'NO NUMBER',
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, letterSpacing: 1.5, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildCodeView(bool hasBarcode, bool hasQr) {
    final showBarcode = hasBarcode && (!_showQr || !hasQr);

    if (showBarcode) {
      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              BarcodeWidget(
                barcode: Barcode.code128(),
                data: _card.barcodeData!,
                height: 80,
                drawText: true,
                errorBuilder: (_, e) => Text('条码生成失败: $e'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('复制条码内容'),
                onPressed: () => _copy(_card.barcodeData!, '条码内容'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: QrImageView(
                data: _card.qrcodeData!,
                version: QrVersions.auto,
                size: 160,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(8),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('复制二维码内容'),
              onPressed: () => _copy(_card.qrcodeData!, '二维码内容'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        )),
  );

  Widget _buildInfoRow(String label, String value, String copyLabel) {
    if (value.isEmpty) return const SizedBox.shrink();
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
            Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
            Icon(Icons.copy, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
