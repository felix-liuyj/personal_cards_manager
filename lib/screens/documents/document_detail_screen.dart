import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';
import 'package:personal_cards_manager/features/clipboard/clipboard_service.dart';
import 'package:personal_cards_manager/features/home/recent_usage_service.dart';
import 'package:personal_cards_manager/screens/documents/id_card_form_screen.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final IDCard card;

  const DocumentDetailScreen({super.key, required this.card});

  @override
  ConsumerState<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  late IDCard _card;
  bool _showSensitiveInfo = false;

  @override
  void initState() {
    super.initState();
    _card = widget.card;
    _recordView();
  }

  Future<void> _recordView() async {
    await ref.read(recentUsageServiceProvider).recordViewed(
      type: 'id',
      id: _card.id,
      title: _card.cardName?.isNotEmpty == true ? _card.cardName! : _card.fullName ?? '证件',
    );
  }

  Future<void> _copy(String text, String label) async {
    if (text.isEmpty) return;
    await ref.read(clipboardServiceProvider).copy(text);
    await ref.read(recentUsageServiceProvider).recordCopied(
      type: 'id',
      id: _card.id,
      title: _card.cardName?.isNotEmpty == true ? _card.cardName! : _card.fullName ?? '证件',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已复制 $label')));
    }
  }

  void _editCard() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => IDCardFormScreen(card: _card)),
    );
    if (result == true && mounted) Navigator.pop(context, true);
  }

  Future<void> _toggleFavorite() async {
    final isar = await ref.read(localDbProvider.future);
    _card.isFavorite = !_card.isFavorite;
    await isar.writeTxn(() async => isar.iDCards.put(_card));
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
        title: Text(_card.isArchived ? '取消归档' : '归档证件'),
        content: Text(_card.isArchived ? '将此证件恢复到主列表？' : '将此证件移入归档，它将从主列表中隐藏。'),
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
    await isar.writeTxn(() async => isar.iDCards.put(_card));
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除证件'),
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
    await isar.writeTxn(() async => isar.iDCards.delete(_card.id));
    if (mounted) Navigator.pop(context, true);
  }

  Color _getDocumentColor(String? type) {
    switch (type) {
      case 'ID': return Colors.blue;
      case 'PASSPORT': return Colors.indigo;
      case 'DRIVER_LICENSE': return Colors.green;
      case 'HK_MACAU_PASS': return Colors.purple;
      case 'TAIWAN_PASS': return Colors.teal;
      case 'RESIDENCE_PERMIT': return Colors.blue;
      case 'SOCIAL_SECURITY': return Colors.cyan;
      case 'STUDENT_ID': return Colors.amber;
      case 'WORK_PERMIT': return Colors.brown;
      default: return Colors.blueGrey;
    }
  }

  String _getDocumentTypeName() {
    switch (_card.documentType) {
      case 'ID': return '居民身份证';
      case 'PASSPORT': return '护照';
      case 'DRIVER_LICENSE': return '驾驶证';
      case 'HK_MACAU_PASS': return '港澳通行证';
      case 'TAIWAN_PASS': return '台湾通行证';
      case 'RESIDENCE_PERMIT': return '居住证';
      case 'SOCIAL_SECURITY': return '社保卡';
      case 'STUDENT_ID': return '学生证';
      case 'WORK_PERMIT': return '工作证';
      default: return '其他证件';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('证件详情'),
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
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.archive, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Text('此证件已归档', style: TextStyle(color: Colors.orange)),
              ]),
            ),
          _buildCardVisual(),
          const SizedBox(height: 16),
          _buildControlRow(),
          const SizedBox(height: 16),
          _buildSectionTitle('基本资料'),
          _buildInfoRow('姓名', _card.fullName ?? '', '姓名'),
          _buildInfoRow('英文姓名', _card.englishName ?? '', '英文姓名'),
          _buildInfoRow('性别', _card.gender == 'M' ? '男' : _card.gender == 'F' ? '女' : _card.gender ?? '', '性别'),
          _buildInfoRow('国籍/地区', _card.countryCode ?? '', '国籍'),
          _buildInfoRow(
            '出生日期',
            _card.birthDate != null
                ? '${_card.birthDate!.year}-${_card.birthDate!.month.toString().padLeft(2, '0')}-${_card.birthDate!.day.toString().padLeft(2, '0')}'
                : '',
            '出生日期',
          ),
          _buildInfoRow('证件号码', _card.documentNumber ?? '', '证件号码', isSensitive: true),
          const SizedBox(height: 16),
          _buildSectionTitle('签发信息'),
          _buildInfoRow('签发机关', _card.issueAuthority ?? '', '签发机关'),
          _buildInfoRow(
            '签发日期',
            _card.issueDate != null
                ? '${_card.issueDate!.year}-${_card.issueDate!.month.toString().padLeft(2, '0')}-${_card.issueDate!.day.toString().padLeft(2, '0')}'
                : '',
            '签发日期',
          ),
          _buildInfoRow(
            '有效期至',
            _card.expireDate != null
                ? '${_card.expireDate!.year}-${_card.expireDate!.month.toString().padLeft(2, '0')}-${_card.expireDate!.day.toString().padLeft(2, '0')}'
                : '长期有效',
            '有效期',
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('扩展信息'),
          _buildInfoRow('住址', _card.fullAddress ?? '', '住址'),
          _buildInfoRow('附加说明', _card.extras ?? '', '附加说明'),
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
            label: const Text('复制核心信息'),
            onPressed: () {
              final text = '姓名: ${_card.fullName ?? ''}\n证件号: ${_card.documentNumber ?? ''}';
              _copy(text.trim(), '证件核心信息');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardVisual() {
    final mode = _card.displayMode;
    final isPassport = mode == DisplayMode.passportCover || mode == DisplayMode.passportSpread;
    final ratio = _card.aspectRatio > 0 ? _card.aspectRatio : (isPassport ? 1.38 : 1.58);
    final color = _getDocumentColor(_card.documentType);

    final maskedNumber = _card.documentNumber != null && _card.documentNumber!.length >= 4
        ? '**** **** **** ${_card.documentNumber!.substring(_card.documentNumber!.length - 4)}'
        : '****';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width / ratio;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          padding: EdgeInsets.all(isPassport ? 32 : 24),
          child: isPassport ? _buildPassportCover() : _buildStandardCard(maskedNumber),
        );
      },
    );
  }

  Widget _buildPassportCover() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        _card.countryCode ?? '',
        style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 4),
      ),
      const SizedBox(height: 20),
      const Icon(Icons.public, color: Colors.white, size: 56),
      const SizedBox(height: 20),
      Text(
        _card.cardName?.isNotEmpty == true ? _card.cardName! : 'PASSPORT',
        style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.bold),
      ),
    ],
  );

  Widget _buildStandardCard(String maskedNumber) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(_getDocumentTypeName(),
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Icon(Icons.badge, color: Colors.white.withOpacity(0.5), size: 28),
      ]),
      const Spacer(),
      Text(_card.fullName ?? '未填写姓名',
          style: const TextStyle(color: Colors.white, fontSize: 20)),
      const SizedBox(height: 6),
      Text(
        _showSensitiveInfo ? (_card.documentNumber ?? '****') : maskedNumber,
        style: const TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 1.5, fontFamily: 'monospace'),
      ),
    ],
  );

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
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
