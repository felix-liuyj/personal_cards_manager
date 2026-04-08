import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';
import 'package:personal_cards_manager/screens/documents/id_card_form_screen.dart';

class DocumentsListScreen extends ConsumerStatefulWidget {
  const DocumentsListScreen({super.key});

  @override
  ConsumerState<DocumentsListScreen> createState() =>
      _DocumentsListScreenState();
}

class _DocumentsListScreenState extends ConsumerState<DocumentsListScreen> {
  Future<List<IDCard>> _loadDocuments(Isar isar) async {
    return await isar.iDCards.where().findAll();
  }

  @override
  Widget build(BuildContext context) {
    final isarAsync = ref.watch(localDbProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('证件'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addDocument(),
          ),
        ],
      ),
      body: isarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('错误: $err')),
        data: (isar) => FutureBuilder<List<IDCard>>(
          future: _loadDocuments(isar),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final documents = snapshot.data ?? [];
            if (documents.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  return _buildDocumentItem(documents[index]);
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
          Icon(Icons.badge_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '暂无证件',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角 + 添加证件',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addDocument,
            icon: const Icon(Icons.add),
            label: const Text('添加证件'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(IDCard doc) {
    final maskedNumber =
        doc.documentNumber != null && doc.documentNumber!.length >= 4
        ? '**** **** **** ${doc.documentNumber!.substring(doc.documentNumber!.length - 4)}'
        : '****';

    final isExpired =
        doc.expireDate != null && doc.expireDate!.isBefore(DateTime.now());
    final isExpiring =
        doc.expireDate != null &&
        doc.expireDate!.isAfter(DateTime.now()) &&
        doc.expireDate!.difference(DateTime.now()).inDays <= 30;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewDocument(doc),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getDocumentColor(doc.documentType),
                    child: Icon(
                      _getDocumentIcon(doc.documentType),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.cardName?.isNotEmpty == true
                              ? doc.cardName!
                              : _getDocumentTypeName(doc.documentType),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _getDocumentTypeName(doc.documentType),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  if (isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '已过期',
                        style: TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  if (isExpiring)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '即将过期',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  if (doc.isFavorite)
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    doc.fullName ?? '未设置姓名',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    maskedNumber,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDocumentColor(String? type) {
    switch (type) {
      case 'ID':
        return Colors.blue;
      case 'PASSPORT':
        return Colors.red;
      case 'DRIVER_LICENSE':
        return Colors.green;
      case 'HK_MACAU_PASS':
        return Colors.purple;
      case 'TAIWAN_PASS':
        return Colors.teal;
      case 'RESIDENCE_PERMIT':
        return Colors.indigo;
      case 'SOCIAL_SECURITY':
        return Colors.cyan;
      case 'STUDENT_ID':
        return Colors.amber;
      case 'WORK_PERMIT':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  IconData _getDocumentIcon(String? type) {
    switch (type) {
      case 'ID':
        return Icons.badge;
      case 'PASSPORT':
        return Icons.flight;
      case 'DRIVER_LICENSE':
        return Icons.directions_car;
      case 'HK_MACAU_PASS':
      case 'TAIWAN_PASS':
        return Icons.card_travel;
      case 'RESIDENCE_PERMIT':
        return Icons.home;
      case 'SOCIAL_SECURITY':
        return Icons.health_and_safety;
      case 'STUDENT_ID':
        return Icons.school;
      case 'WORK_PERMIT':
        return Icons.work;
      default:
        return Icons.description;
    }
  }

  String _getDocumentTypeName(String? type) {
    switch (type) {
      case 'ID':
        return '居民身份证';
      case 'PASSPORT':
        return '护照';
      case 'DRIVER_LICENSE':
        return '驾驶证';
      case 'HK_MACAU_PASS':
        return '港澳通行证';
      case 'TAIWAN_PASS':
        return '台湾通行证';
      case 'RESIDENCE_PERMIT':
        return '居住证';
      case 'SOCIAL_SECURITY':
        return '社保卡';
      case 'STUDENT_ID':
        return '学生证';
      case 'WORK_PERMIT':
        return '工作证';
      default:
        return '其他证件';
    }
  }

  void _addDocument() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IDCardFormScreen()),
    );
    if (result == true) {
      setState(() {});
    }
  }

  void _viewDocument(IDCard doc) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => IDCardFormScreen(card: doc)),
    );
    if (result == true) {
      setState(() {});
    }
  }
}
