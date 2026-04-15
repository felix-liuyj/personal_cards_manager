import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:personal_cards_manager/data/models/models.dart';

class TagGroupSelector extends StatelessWidget {
  final Isar isar;
  final List<CustomTag> selectedTags;
  final CustomGroup? selectedGroup;
  final ValueChanged<List<CustomTag>> onTagsChanged;
  final ValueChanged<CustomGroup?> onGroupChanged;

  const TagGroupSelector({
    super.key,
    required this.isar,
    required this.selectedTags,
    required this.selectedGroup,
    required this.onTagsChanged,
    required this.onGroupChanged,
  });

  Future<void> _selectTags(BuildContext context) async {
    final allTags = await isar.customTags.where().findAll();
    if (!context.mounted) return;

    List<CustomTag> currentSelections = List.from(selectedTags);
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('选择标签'),
          content: SizedBox(
            width: double.maxFinite,
            child: allTags.isEmpty 
              ? const Text('暂无标签，请在设置中添加')
              : ListView.builder(
              shrinkWrap: true,
              itemCount: allTags.length,
              itemBuilder: (_, i) {
                final tag = allTags[i];
                final isSelected = currentSelections.any((t) => t.id == tag.id);
                Color c = Colors.grey;
                try { if (tag.colorHex != null) c = Color(int.parse(tag.colorHex!.replaceAll('#', '0xFF'))); } catch (_) {}
                
                return CheckboxListTile(
                  title: Row(
                    children: [
                      CircleAvatar(backgroundColor: c, radius: 8),
                      const SizedBox(width: 8),
                      Text(tag.name ?? ''),
                    ],
                  ),
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        currentSelections.add(tag);
                      } else {
                        currentSelections.removeWhere((t) => t.id == tag.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                onTagsChanged(currentSelections);
                Navigator.pop(ctx);
              },
              child: const Text('确定'),
            ),
          ],
        )
      )
    );
  }

  Future<void> _selectGroup(BuildContext context) async {
    final allGroups = await isar.customGroups.where().sortBySortOrder().findAll();
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择分组'),
        content: SizedBox(
          width: double.maxFinite,
          child: allGroups.isEmpty 
            ? const Text('暂无分组，请在设置中添加')
            : RadioGroup<int?>(
            groupValue: selectedGroup?.id,
            onChanged: (val) {
              if (val != null) {
                final group = allGroups.firstWhere((g) => g.id == val);
                onGroupChanged(group);
              }
              Navigator.pop(ctx);
            },
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allGroups.length,
              itemBuilder: (_, i) {
                final group = allGroups[i];
                return RadioListTile<int?>(
                  title: Text(group.name ?? ''),
                  value: group.id,
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              onGroupChanged(null);
              Navigator.pop(ctx);
            },
            child: const Text('清除分组'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('分类与标签', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.withValues(alpha: 0.3))),
          leading: const Icon(Icons.folder_outlined),
          title: Text(selectedGroup?.name ?? '未分组'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _selectGroup(context),
        ),
        const SizedBox(height: 8),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.withValues(alpha: 0.3))),
          leading: const Icon(Icons.label_outline),
          title: selectedTags.isEmpty 
            ? const Text('无标签', style: TextStyle(color: Colors.grey))
            : Wrap(
                spacing: 8,
                children: selectedTags.map((t) {
                  Color c = Colors.grey;
                  try { if (t.colorHex != null) c = Color(int.parse(t.colorHex!.replaceAll('#', '0xFF'))); } catch (_) {}
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: c.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                    child: Text(t.name ?? '', style: TextStyle(fontSize: 12, color: c)),
                  );
                }).toList(),
              ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _selectTags(context),
        ),
      ],
    );
  }
}
