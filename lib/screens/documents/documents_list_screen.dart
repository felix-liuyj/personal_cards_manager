import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_cards_manager/core/database/database_service.dart';
import 'package:personal_cards_manager/models/identity_document.dart';

class DocumentsListScreen extends ConsumerStatefulWidget {
  const DocumentsListScreen({super.key});

  @override
  ConsumerState<DocumentsListScreen> createState() =>
      _DocumentsListScreenState();
}

class _DocumentsListScreenState extends ConsumerState<DocumentsListScreen> {
  List<IdentityDocument> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    final docs = await DatabaseService.instance.getAllDocuments();
    setState(() {
      _documents = docs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('证件'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addDocument),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadDocuments,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _documents.length,
                itemBuilder: (context, index) {
                  return _buildDocumentItem(_documents[index]);
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
        ],
      ),
    );
  }

  Widget _buildDocumentItem(IdentityDocument doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getDocumentColor(doc.documentType),
          child: Icon(
            _getDocumentIcon(doc.documentType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(doc.documentName.isNotEmpty ? doc.documentName : doc.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getDocumentTypeName(doc.documentType)),
            if (doc.documentNumber.isNotEmpty) Text('号码: ${doc.maskedNumber}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (doc.isExpired)
              const Icon(Icons.warning, color: Colors.red, size: 20),
            if (doc.isFavorite)
              const Icon(Icons.star, color: Colors.amber, size: 20),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => _viewDocument(doc),
      ),
    );
  }

  Color _getDocumentColor(DocumentType type) {
    switch (type) {
      case DocumentType.idCard:
        return Colors.blue;
      case DocumentType.passport:
        return Colors.red;
      case DocumentType.driverLicense:
        return Colors.green;
      case DocumentType.hkMacauPass:
        return Colors.purple;
      case DocumentType.taiwanPass:
        return Colors.teal;
      case DocumentType.residencePermit:
        return Colors.indigo;
      case DocumentType.socialSecurityCard:
        return Colors.cyan;
      case DocumentType.studentId:
        return Colors.amber;
      case DocumentType.workPermit:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  IconData _getDocumentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.idCard:
        return Icons.badge;
      case DocumentType.passport:
        return Icons.flight;
      case DocumentType.driverLicense:
        return Icons.directions_car;
      case DocumentType.hkMacauPass:
      case DocumentType.taiwanPass:
        return Icons.card_travel;
      case DocumentType.residencePermit:
        return Icons.home;
      case DocumentType.socialSecurityCard:
        return Icons.health_and_safety;
      case DocumentType.studentId:
        return Icons.school;
      case DocumentType.workPermit:
        return Icons.work;
      default:
        return Icons.description;
    }
  }

  String _getDocumentTypeName(DocumentType type) {
    switch (type) {
      case DocumentType.idCard:
        return '身份证';
      case DocumentType.passport:
        return '护照';
      case DocumentType.driverLicense:
        return '驾驶证';
      case DocumentType.hkMacauPass:
        return '港澳通行证';
      case DocumentType.taiwanPass:
        return '台湾通行证';
      case DocumentType.residencePermit:
        return '居住证';
      case DocumentType.socialSecurityCard:
        return '社保卡';
      case DocumentType.studentId:
        return '学生证';
      case DocumentType.workPermit:
        return '工作证';
      default:
        return '其他证件';
    }
  }

  void _addDocument() {
    // TODO: Navigate to add document screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('添加证件功能开发中')));
  }

  void _viewDocument(IdentityDocument doc) {
    // TODO: Navigate to document detail screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('查看证件: ${doc.documentName}')));
  }
}
