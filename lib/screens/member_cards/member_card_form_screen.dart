import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';
import 'package:personal_cards_manager/screens/tags/tag_group_selector.dart';

class MemberCardFormScreen extends ConsumerStatefulWidget {
  final MemberCard? card;

  const MemberCardFormScreen({super.key, this.card});

  @override
  ConsumerState<MemberCardFormScreen> createState() =>
      _MemberCardFormScreenState();
}

class _MemberCardFormScreenState extends ConsumerState<MemberCardFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _brandController;
  late TextEditingController _cardNameController;
  late TextEditingController _aliasNameController;
  late TextEditingController _memberNumberController;
  late TextEditingController _tierCodeController;
  late TextEditingController _pointsController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _barcodeDataController;
  late TextEditingController _qrcodeDataController;
  late TextEditingController _noteController;

  DateTime? _validUntil;
  bool _isFavorite = false;
  String _selectedTemplate = 'default';

  List<CustomTag> _selectedTags = [];
  CustomGroup? _selectedGroup;

  bool get _isEditing => widget.card != null;

  @override
  void initState() {
    super.initState();
    final card = widget.card;
    _brandController = TextEditingController(text: card?.brand ?? '');
    _cardNameController = TextEditingController(text: card?.cardName ?? '');
    _aliasNameController = TextEditingController(text: card?.aliasName ?? '');
    _memberNumberController = TextEditingController(
      text: card?.memberNumber ?? '',
    );
    _tierCodeController = TextEditingController(text: card?.tierCode ?? '');
    _pointsController = TextEditingController(
      text: card?.points?.toString() ?? '',
    );
    _phoneNumberController = TextEditingController(
      text: card?.phoneNumber ?? '',
    );
    _barcodeDataController = TextEditingController(
      text: card?.barcodeData ?? '',
    );
    _qrcodeDataController = TextEditingController(text: card?.qrcodeData ?? '');
    _noteController = TextEditingController(text: card?.note ?? '');

    if (card != null) {
      _validUntil = card.validUntil;
      _isFavorite = card.isFavorite;
      _selectedTemplate = card.templateName ?? 'default';
      _selectedTags = card.tags.toList();
      _selectedGroup = card.groups.isNotEmpty ? card.groups.first : null;
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _cardNameController.dispose();
    _aliasNameController.dispose();
    _memberNumberController.dispose();
    _tierCodeController.dispose();
    _pointsController.dispose();
    _phoneNumberController.dispose();
    _barcodeDataController.dispose();
    _qrcodeDataController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    final isar = await ref.read(localDbProvider.future);

    final card = widget.card ?? MemberCard();
    card.brand = _brandController.text;
    card.cardName = _cardNameController.text;
    card.aliasName = _aliasNameController.text;
    card.memberNumber = _memberNumberController.text;
    card.tierCode = _tierCodeController.text;
    card.points = double.tryParse(_pointsController.text) ?? 0;
    card.phoneNumber = _phoneNumberController.text;
    card.barcodeData = _barcodeDataController.text;
    card.qrcodeData = _qrcodeDataController.text;
    card.note = _noteController.text;
    card.validUntil = _validUntil;
    card.isFavorite = _isFavorite;
    card.templateName = _selectedTemplate;
    card.updatedAt = DateTime.now();

    if (!_isEditing) {
      card.createdAt = DateTime.now();
    }

    await isar.writeTxn(() async {
      await isar.memberCards.put(card);
      card.tags.clear();
      card.tags.addAll(_selectedTags);
      card.groups.clear();
      if (_selectedGroup != null) card.groups.add(_selectedGroup!);
      await card.tags.save();
      await card.groups.save();
    });

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validUntil ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _validUntil = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑会员卡' : '添加会员卡'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? Colors.amber : null,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          TextButton(onPressed: _saveCard, child: const Text('保存')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ref.watch(localDbProvider).whenOrNull(data: (isar) => TagGroupSelector(
              isar: isar,
              selectedTags: _selectedTags,
              selectedGroup: _selectedGroup,
              onTagsChanged: (t) => setState(() => _selectedTags = t),
              onGroupChanged: (g) => setState(() => _selectedGroup = g),
            )) ?? const SizedBox.shrink(),
            const SizedBox(height: 16),
            _buildSectionTitle('基本信息'),
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: '品牌名称',
                hintText: '如：星巴克、Costco',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入品牌名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cardNameController,
              decoration: const InputDecoration(
                labelText: '会员卡名称',
                hintText: '如：金卡会员',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _aliasNameController,
              decoration: const InputDecoration(
                labelText: '卡片别名',
                hintText: '可选',
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('会员信息'),
            TextFormField(
              controller: _memberNumberController,
              decoration: const InputDecoration(labelText: '会员编号'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入会员编号';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tierCodeController,
              decoration: const InputDecoration(
                labelText: '会员等级',
                hintText: '如：金卡、白金卡',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pointsController,
              decoration: const InputDecoration(labelText: '积分'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(labelText: '绑定手机号'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('有效期'),
              subtitle: Text(
                _validUntil != null
                    ? '${_validUntil!.year}-${_validUntil!.month.toString().padLeft(2, '0')}-${_validUntil!.day.toString().padLeft(2, '0')}'
                    : '未设置',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('条码/二维码'),
            TextFormField(
              controller: _barcodeDataController,
              decoration: const InputDecoration(
                labelText: '条码内容',
                hintText: '用于生成条码',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _qrcodeDataController,
              decoration: const InputDecoration(
                labelText: '二维码内容',
                hintText: '用于生成二维码',
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('其他'),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '备注',
                hintText: '可选',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
