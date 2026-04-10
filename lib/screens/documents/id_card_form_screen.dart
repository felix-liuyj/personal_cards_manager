import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';
import 'package:personal_cards_manager/features/id_cards/id_card_factory.dart';
import 'package:personal_cards_manager/screens/tags/tag_group_selector.dart';

class IDCardFormScreen extends ConsumerStatefulWidget {
  final IDCard? card;

  const IDCardFormScreen({super.key, this.card});

  @override
  ConsumerState<IDCardFormScreen> createState() => _IDCardFormScreenState();
}

class _IDCardFormScreenState extends ConsumerState<IDCardFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _cardNameController;
  late TextEditingController _fullNameController;
  late TextEditingController _englishNameController;
  late TextEditingController _documentNumberController;
  late TextEditingController _fullAddressController;
  late TextEditingController _issueAuthorityController;
  late TextEditingController _extrasController;
  late TextEditingController _noteController;

  String _selectedCountry = 'CN';
  String _selectedDocType = 'ID';
  String _selectedGender = 'M';
  DateTime? _birthDate;
  DateTime? _issueDate;
  DateTime? _expireDate;
  bool _isFavorite = false;
  String _selectedTemplate = 'default';

  List<CustomTag> _selectedTags = [];
  CustomGroup? _selectedGroup;

  final List<Map<String, String>> _countries = [
    {'code': 'CN', 'name': '中国'},
    {'code': 'US', 'name': '美国'},
    {'code': 'UK', 'name': '英国'},
    {'code': 'JP', 'name': '日本'},
    {'code': 'KR', 'name': '韩国'},
    {'code': 'OTHER', 'name': '其他'},
  ];

  final Map<String, List<Map<String, String>>> _docTypesByCountry = {
    'CN': [
      {'type': 'ID', 'name': '居民身份证'},
      {'type': 'PASSPORT', 'name': '护照'},
      {'type': 'DRIVER_LICENSE', 'name': '驾驶证'},
      {'type': 'HK_MACAU_PASS', 'name': '港澳通行证'},
      {'type': 'TAIWAN_PASS', 'name': '台湾通行证'},
      {'type': 'RESIDENCE_PERMIT', 'name': '居住证'},
      {'type': 'SOCIAL_SECURITY', 'name': '社保卡'},
      {'type': 'STUDENT_ID', 'name': '学生证'},
      {'type': 'WORK_PERMIT', 'name': '工作证'},
    ],
    'US': [
      {'type': 'PASSPORT', 'name': 'Passport'},
      {'type': 'DRIVER_LICENSE', 'name': "Driver's License"},
      {'type': 'STATE_ID', 'name': 'State ID'},
      {'type': 'SOCIAL_SECURITY', 'name': 'Social Security Card'},
      {'type': 'GREEN_CARD', 'name': 'Green Card'},
    ],
    'UK': [
      {'type': 'PASSPORT', 'name': 'Passport'},
      {'type': 'DRIVER_LICENSE', 'name': 'Driving Licence'},
      {'type': 'BRP', 'name': 'BRP'},
    ],
    'OTHER': [
      {'type': 'PASSPORT', 'name': 'Passport'},
      {'type': 'DRIVER_LICENSE', 'name': "Driver's License"},
      {'type': 'ID', 'name': 'ID Card'},
      {'type': 'OTHER', 'name': 'Other'},
    ],
  };

  bool get _isEditing => widget.card != null;

  List<Map<String, String>> get _currentDocTypes {
    return _docTypesByCountry[_selectedCountry] ?? _docTypesByCountry['OTHER']!;
  }

  @override
  void initState() {
    super.initState();
    final card = widget.card;
    _cardNameController = TextEditingController(text: card?.cardName ?? '');
    _fullNameController = TextEditingController(text: card?.fullName ?? '');
    _englishNameController = TextEditingController(
      text: card?.englishName ?? '',
    );
    _documentNumberController = TextEditingController(
      text: card?.documentNumber ?? '',
    );
    _fullAddressController = TextEditingController(
      text: card?.fullAddress ?? '',
    );
    _issueAuthorityController = TextEditingController(
      text: card?.issueAuthority ?? '',
    );
    _extrasController = TextEditingController(text: card?.extras ?? '');
    _noteController = TextEditingController(text: card?.note ?? '');

    if (card != null) {
      _selectedCountry = card.countryCode ?? 'CN';
      _selectedDocType = card.documentType ?? 'ID';
      _selectedGender = card.gender ?? 'M';
      _birthDate = card.birthDate;
      _issueDate = card.issueDate;
      _expireDate = card.expireDate;
      _isFavorite = card.isFavorite;
      _selectedTemplate = card.templateName ?? 'default';
      _selectedTags = card.tags.toList();
      _selectedGroup = card.groups.isNotEmpty ? card.groups.first : null;
    }
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _fullNameController.dispose();
    _englishNameController.dispose();
    _documentNumberController.dispose();
    _fullAddressController.dispose();
    _issueAuthorityController.dispose();
    _extrasController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    final isar = await ref.read(localDbProvider.future);

    final card = widget.card ?? IDCard();
    card.countryCode = _selectedCountry;
    card.documentType = _selectedDocType;
    card.cardName = _cardNameController.text;
    card.fullName = _fullNameController.text;
    card.englishName = _englishNameController.text;
    card.documentNumber = _documentNumberController.text;
    card.gender = _selectedGender;
    card.birthDate = _birthDate;
    card.fullAddress = _fullAddressController.text;
    card.issueAuthority = _issueAuthorityController.text;
    card.issueDate = _issueDate;
    card.expireDate = _expireDate;
    card.extras = _extrasController.text;
    card.note = _noteController.text;
    card.isFavorite = _isFavorite;
    card.templateName = _selectedTemplate;
    card.updatedAt = DateTime.now();

    // 应用显示模式约束
    IDCardFactory.applyConstraints(card);

    if (!_isEditing) {
      card.createdAt = DateTime.now();
    }

    await isar.writeTxn(() async {
      await isar.iDCards.put(card);
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

  Future<void> _selectDate(String field) async {
    DateTime? initialDate;
    switch (field) {
      case 'birth':
        initialDate = _birthDate ?? DateTime(1990);
        break;
      case 'issue':
        initialDate = _issueDate ?? DateTime.now();
        break;
      case 'expire':
        initialDate =
            _expireDate ?? DateTime.now().add(const Duration(days: 3650));
        break;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        switch (field) {
          case 'birth':
            _birthDate = picked;
            break;
          case 'issue':
            _issueDate = picked;
            break;
          case 'expire':
            _expireDate = picked;
            break;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '未设置';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final docTypeName = _currentDocTypes.firstWhere(
      (d) => d['type'] == _selectedDocType,
      orElse: () => {'name': '未知'},
    )['name'];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑证件' : '添加证件'),
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
            _buildSectionTitle('证件类型'),
            DropdownButtonFormField<String>(
              value: _selectedCountry,
              decoration: const InputDecoration(labelText: '国家/地区'),
              items: _countries
                  .map(
                    (c) => DropdownMenuItem(
                      value: c['code'],
                      child: Text(c['name']!),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCountry = value!;
                  _selectedDocType = _currentDocTypes.first['type']!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDocType,
              decoration: const InputDecoration(labelText: '证件类型'),
              items: _currentDocTypes
                  .map(
                    (d) => DropdownMenuItem(
                      value: d['type'],
                      child: Text(d['name']!),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedDocType = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cardNameController,
              decoration: InputDecoration(
                labelText: '证件名称',
                hintText: docTypeName,
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('个人信息'),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: '姓名'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入姓名';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _englishNameController,
              decoration: const InputDecoration(
                labelText: '英文姓名',
                hintText: '护照等证件需要',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _documentNumberController,
              decoration: const InputDecoration(labelText: '证件号码'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入证件号码';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(labelText: '性别'),
              items: const [
                DropdownMenuItem(value: 'M', child: Text('男')),
                DropdownMenuItem(value: 'F', child: Text('女')),
                DropdownMenuItem(value: 'X', child: Text('其他')),
              ],
              onChanged: (value) => setState(() => _selectedGender = value!),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('出生日期'),
              subtitle: Text(_formatDate(_birthDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate('birth'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fullAddressController,
              decoration: const InputDecoration(labelText: '地址'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('签发信息'),
            TextFormField(
              controller: _issueAuthorityController,
              decoration: const InputDecoration(labelText: '签发机关'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('签发日期'),
              subtitle: Text(_formatDate(_issueDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate('issue'),
            ),
            ListTile(
              title: const Text('到期日期'),
              subtitle: Text(_formatDate(_expireDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate('expire'),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('其他'),
            TextFormField(
              controller: _extrasController,
              decoration: const InputDecoration(labelText: '附加说明'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: '备注'),
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
