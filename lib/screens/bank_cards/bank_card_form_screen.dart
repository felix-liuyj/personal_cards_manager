import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';
import 'package:uuid/uuid.dart';

class BankCardFormScreen extends ConsumerStatefulWidget {
  final BankCard? card;

  const BankCardFormScreen({super.key, this.card});

  @override
  ConsumerState<BankCardFormScreen> createState() => _BankCardFormScreenState();
}

class _BankCardFormScreenState extends ConsumerState<BankCardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late TextEditingController _issuerNameController;
  late TextEditingController _cardNameController;
  late TextEditingController _aliasNameController;
  late TextEditingController _holderNameController;
  late TextEditingController _fullNumberController;
  late TextEditingController _cvvController;
  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;
  late TextEditingController _countryController;
  late TextEditingController _noteController;

  String _selectedNetwork = 'Visa';
  int _expMonth = 1;
  int _expYear = DateTime.now().year;
  String _selectedCurrency = 'CNY';
  String _selectedColor = 'blue';
  bool _isFavorite = false;

  final List<String> _networks = [
    'Visa',
    'Mastercard',
    'UnionPay',
    'Amex',
    'Discover',
    'Other',
  ];
  final List<String> _currencies = ['CNY', 'USD', 'EUR', 'GBP', 'JPY', 'HKD'];
  final List<String> _colors = [
    'blue',
    'red',
    'green',
    'purple',
    'orange',
    'black',
    'gold',
  ];

  bool get _isEditing => widget.card != null;

  @override
  void initState() {
    super.initState();
    final card = widget.card;
    _issuerNameController = TextEditingController(text: card?.issuerName ?? '');
    _cardNameController = TextEditingController(text: card?.cardName ?? '');
    _aliasNameController = TextEditingController(text: card?.aliasName ?? '');
    _holderNameController = TextEditingController(text: card?.holderName ?? '');
    _fullNumberController = TextEditingController(text: card?.fullNumber ?? '');
    _cvvController = TextEditingController(text: card?.cvv ?? '');
    _addressLine1Controller = TextEditingController(
      text: card?.addressLine1 ?? '',
    );
    _addressLine2Controller = TextEditingController(
      text: card?.addressLine2 ?? '',
    );
    _cityController = TextEditingController(text: card?.city ?? '');
    _stateController = TextEditingController(text: card?.stateProvince ?? '');
    _zipCodeController = TextEditingController(text: card?.zipCode ?? '');
    _countryController = TextEditingController(text: card?.country ?? '');
    _noteController = TextEditingController(text: card?.note ?? '');

    if (card != null) {
      _selectedNetwork = card.network ?? 'Visa';
      _expMonth = card.expMonth ?? 1;
      _expYear = card.expYear ?? DateTime.now().year;
      _selectedCurrency = card.currency ?? 'CNY';
      _selectedColor = card.colorTheme ?? 'blue';
      _isFavorite = card.isFavorite;
    }
  }

  @override
  void dispose() {
    _issuerNameController.dispose();
    _cardNameController.dispose();
    _aliasNameController.dispose();
    _holderNameController.dispose();
    _fullNumberController.dispose();
    _cvvController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;

    final isar = await ref.read(localDbProvider.future);

    final card = widget.card ?? BankCard();
    card.issuerName = _issuerNameController.text;
    card.network = _selectedNetwork;
    card.cardName = _cardNameController.text;
    card.aliasName = _aliasNameController.text;
    card.holderName = _holderNameController.text;
    card.fullNumber = _fullNumberController.text.replaceAll(' ', '');
    card.expMonth = _expMonth;
    card.expYear = _expYear;
    card.cvv = _cvvController.text;
    card.addressLine1 = _addressLine1Controller.text;
    card.addressLine2 = _addressLine2Controller.text;
    card.city = _cityController.text;
    card.stateProvince = _stateController.text;
    card.zipCode = _zipCodeController.text;
    card.country = _countryController.text;
    card.currency = _selectedCurrency;
    card.note = _noteController.text;
    card.colorTheme = _selectedColor;
    card.isFavorite = _isFavorite;
    card.updatedAt = DateTime.now();

    if (!_isEditing) {
      card.createdAt = DateTime.now();
    }

    await isar.writeTxn(() async {
      await isar.bankCards.put(card);
    });

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑银行卡' : '添加银行卡'),
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
            _buildSectionTitle('基本信息'),
            TextFormField(
              controller: _issuerNameController,
              decoration: const InputDecoration(
                labelText: '发卡行名称',
                hintText: '如：中国银行、Chase',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入发卡行名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedNetwork,
              decoration: const InputDecoration(labelText: '卡组织'),
              items: _networks
                  .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedNetwork = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cardNameController,
              decoration: const InputDecoration(
                labelText: '卡片名称',
                hintText: '如：工资卡、旅行卡',
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
            _buildSectionTitle('支付信息'),
            TextFormField(
              controller: _holderNameController,
              decoration: const InputDecoration(labelText: '持卡人姓名'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fullNumberController,
              decoration: const InputDecoration(
                labelText: '完整卡号',
                hintText: '1234 5678 9012 3456',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入卡号';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _expMonth,
                    decoration: const InputDecoration(labelText: '有效期月'),
                    items: List.generate(12, (i) => i + 1)
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.toString().padLeft(2, '0')),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _expMonth = value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _expYear,
                    decoration: const InputDecoration(labelText: '有效期年'),
                    items: List.generate(10, (i) => DateTime.now().year + i)
                        .map(
                          (y) => DropdownMenuItem(
                            value: y,
                            child: Text(y.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _expYear = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cvvController,
              decoration: const InputDecoration(
                labelText: 'CVV/CVC',
                hintText: '3位安全码',
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('账单地址'),
            TextFormField(
              controller: _addressLine1Controller,
              decoration: const InputDecoration(labelText: '地址第一行'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressLine2Controller,
              decoration: const InputDecoration(labelText: '地址第二行'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: '城市'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(labelText: '州/省'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _zipCodeController,
                    decoration: const InputDecoration(labelText: '邮编'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(labelText: '国家/地区'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('其他'),
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: const InputDecoration(labelText: '币种'),
              items: _currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCurrency = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedColor,
              decoration: const InputDecoration(labelText: '卡片颜色'),
              items: _colors
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedColor = value!),
            ),
            const SizedBox(height: 16),
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
