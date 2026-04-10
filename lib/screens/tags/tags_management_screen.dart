import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:personal_cards_manager/data/local_db_service.dart';
import 'package:personal_cards_manager/data/models/models.dart';

class TagsManagementScreen extends ConsumerStatefulWidget {
  const TagsManagementScreen({super.key});

  @override
  ConsumerState<TagsManagementScreen> createState() => _TagsManagementScreenState();
}

class _TagsManagementScreenState extends ConsumerState<TagsManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addOrEditTag(BuildContext context, {CustomTag? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name);
    // Simple predefined colors for tags
    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, 
      Colors.purple, Colors.teal, Colors.pink, Colors.brown
    ];
    
    // Parse existing color if available
    Color selectedColor = colors.first;
    if (existing?.colorHex != null) {
      try {
        final val = int.parse(existing!.colorHex!.replaceAll('#', '0xFF'));
        selectedColor = Color(val);
      } catch (_) {}
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16, right: 16, top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing == null ? '新建标签' : '编辑标签', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '名称', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                const Text('选择颜色:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: colors.map((c) => InkWell(
                    onTap: () => setModalState(() => selectedColor = c),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: selectedColor == c ? Colors.black : Colors.transparent, width: 3),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final isar = await ref.read(localDbProvider.future);
                      
                      final tag = existing ?? CustomTag();
                      tag.name = nameCtrl.text.trim();
                      tag.colorHex = '#${selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2)}'; // rrggbb
                      
                      await isar.writeTxn(() async {
                        await isar.customTags.put(tag);
                      });
                      
                      if (context.mounted) Navigator.pop(ctx);
                      setState(() {});
                    },
                    child: const Text('保存'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
      ),
    );
  }

  Future<void> _addOrEditGroup(BuildContext context, {CustomGroup? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name);
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? '新建分组' : '编辑分组'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: '名称', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final isar = await ref.read(localDbProvider.future);
              
              final group = existing ?? CustomGroup();
              group.name = nameCtrl.text.trim();
              if (existing == null) {
                final all = await isar.customGroups.where().findAll();
                group.sortOrder = all.length;
              }
              
              await isar.writeTxn(() async {
                await isar.customGroups.put(group);
              });
              
              if (context.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('保存'),
          )
        ],
      )
    );
  }

  Future<void> _deleteTag(CustomTag tag) async {
    final isar = await ref.read(localDbProvider.future);
    await isar.writeTxn(() async {
      await isar.customTags.delete(tag.id);
    });
    setState(() {});
  }

  Future<void> _deleteGroup(CustomGroup group) async {
    final isar = await ref.read(localDbProvider.future);
    await isar.writeTxn(() async {
      await isar.customGroups.delete(group.id);
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isarAsync = ref.watch(localDbProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '标签'),
            Tab(text: '分组'),
          ],
        ),
      ),
      body: isarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
        data: (isar) => TabBarView(
          controller: _tabController,
          children: [
            _buildTagsList(isar),
            _buildGroupsList(isar),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _addOrEditTag(context);
          } else {
            _addOrEditGroup(context);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTagsList(Isar isar) {
    return FutureBuilder<List<CustomTag>>(
      future: isar.customTags.where().findAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final tags = snapshot.data!;
        if (tags.isEmpty) return const Center(child: Text('暂无标签，点击右下角添加'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tags.length,
          itemBuilder: (_, i) {
            final t = tags[i];
            Color c = Colors.grey;
            if (t.colorHex != null) {
              try { c = Color(int.parse(t.colorHex!.replaceAll('#', '0xFF'))); } catch (_) {}
            }

            return Card(
              elevation: 0,
              color: c.withOpacity(0.1),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: c, radius: 12),
                title: Text(t.name ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _addOrEditTag(context, existing: t)),
                    IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _deleteTag(t)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupsList(Isar isar) {
    return FutureBuilder<List<CustomGroup>>(
      future: isar.customGroups.where().sortBySortOrder().findAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final groups = snapshot.data!;
        if (groups.isEmpty) return const Center(child: Text('暂无分组，点击右下角添加'));

        return ReorderableListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          onReorder: (oldIndex, newIndex) async {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = groups.removeAt(oldIndex);
            groups.insert(newIndex, item);
            
            await isar.writeTxn(() async {
              for (int i=0; i<groups.length; i++) {
                groups[i].sortOrder = i;
                await isar.customGroups.put(groups[i]);
              }
            });
            setState(() {});
          },
          itemBuilder: (_, i) {
            final g = groups[i];
            return Card(
              key: ValueKey(g.id),
              elevation: 0,
              color: Colors.grey.withOpacity(0.1),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(g.name ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _addOrEditGroup(context, existing: g)),
                    IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _deleteGroup(g)),
                    const Icon(Icons.drag_handle),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
