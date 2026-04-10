import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:personal_cards_manager/features/settings/settings_provider.dart';
import 'package:personal_cards_manager/features/settings/backup_service.dart';
import 'package:personal_cards_manager/features/init_auth/auth_provider.dart';
import 'package:personal_cards_manager/screens/tags/tags_management_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          _buildSectionHeader(context, '🔒 安全设置'),
          SwitchListTile(
            title: const Text('生物识别解锁'),
            subtitle: const Text('使用面容 ID / 指纹解锁应用'),
            value: settings.biometricsEnabled,
            onChanged: (v) => notifier.setBiometricsEnabled(v),
          ),
          SwitchListTile(
            title: const Text('自动锁定'),
            subtitle: Text(
              settings.autoLockEnabled
                  ? '${settings.autoLockMinutes} 分钟无操作后自动锁定'
                  : '已关闭',
            ),
            value: settings.autoLockEnabled,
            onChanged: (v) => notifier.setAutoLockEnabled(v),
          ),
          if (settings.autoLockEnabled)
            ListTile(
              title: const Text('自动锁定时间'),
              trailing: Text('${settings.autoLockMinutes} 分钟'),
              onTap: () => _selectAutoLockTime(context, notifier, settings.autoLockMinutes),
            ),

          const Divider(height: 1),
          _buildSectionHeader(context, '📋 剪贴板设置'),
          SwitchListTile(
            title: const Text('自动清理剪贴板'),
            subtitle: Text(
              settings.clipboardClearEnabled
                  ? '复制后 ${settings.clipboardClearSeconds} 秒自动清除'
                  : '已关闭',
            ),
            value: settings.clipboardClearEnabled,
            onChanged: (v) => notifier.setClipboardClearEnabled(v),
          ),
          if (settings.clipboardClearEnabled)
            ListTile(
              title: const Text('清除延迟'),
              trailing: Text('${settings.clipboardClearSeconds} 秒'),
              onTap: () =>
                  _selectClipboardClearTime(context, notifier, settings.clipboardClearSeconds),
            ),

          const Divider(height: 1),
          _buildSectionHeader(context, '📦 数据管理'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('备份数据'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _handleBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('恢复数据'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _handleRestore(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('清除缓存'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _confirmClearCache(context),
          ),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('分类管理 (标签/分组)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TagsManagementScreen())),
          ),

          const Divider(height: 1),
          _buildSectionHeader(context, 'ℹ️ 关于'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('应用版本'),
            trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('隐私政策'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _selectAutoLockTime(BuildContext context, AppSettingsNotifier notifier, int current) {
    final options = [1, 3, 5, 10, 15, 30];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('选择自动锁定时间',
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ...options.map((m) => ListTile(
                  title: Text('$m 分钟'),
                  trailing: current == m ? const Icon(Icons.check) : null,
                  onTap: () {
                    notifier.setAutoLockMinutes(m);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _selectClipboardClearTime(BuildContext context, AppSettingsNotifier notifier, int current) {
    final options = [10, 30, 60, 120, 300];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('选择剪贴板清除延迟',
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ...options.map((s) => ListTile(
                  title: Text('$s 秒'),
                  trailing: current == s ? const Icon(Icons.check) : null,
                  onTap: () {
                    notifier.setClipboardClearSeconds(s);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _confirmClearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除缓存'),
        content: const Text('确定要清除缓存吗？此操作不会删除已保存的卡片数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('缓存已清除')));
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackup(BuildContext context, WidgetRef ref) async {
    final passwordController = TextEditingController();
    final pwd = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导出备份'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请设置一个备份加密密码。通过此文件在其他设备恢复时需要验证密码。'),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: '备份密码', border: OutlineInputBorder()),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (passwordController.text.trim().isEmpty) return;
              Navigator.pop(ctx, passwordController.text);
            },
            child: const Text('导出'),
          ),
        ],
      ),
    );

    if (pwd != null) {
      if (!context.mounted) return;
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
        final filepath = await ref.read(backupServiceProvider).exportData(pwd);
        if (context.mounted) Navigator.pop(context); // 移除loading
        final result = await Share.shareXFiles([XFile(filepath)], text: '卡片包备份文件');
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // 移除loading
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('备份失败: $e')));
        }
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('警告：数据覆盖'),
        content: const Text('恢复备份将永久删除当前设备上的所有卡片记录，并使用备份文件的数据完全替换。\n\n您确定要继续吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('继续并选择文件'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any, // .pcmbak is custom, so we use any
    );

    if (result != null && result.files.single.path != null) {
      if (!context.mounted) return;
      final passwordController = TextEditingController();
      final pwd = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('验证备份'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('请输入恢复密码：'),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: '密码', border: OutlineInputBorder()),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx, passwordController.text);
              },
              child: const Text('恢复'),
            ),
          ],
        ),
      );

      if (pwd != null) {
        if (!context.mounted) return;
        try {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
          await ref.read(backupServiceProvider).importData(result.files.single.path!, pwd);
          if (context.mounted) {
            Navigator.pop(context); // popup loading
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数据恢复成功！')));
            // Force re-auth or go to home. Let's just lock so user sees fresh state
            ref.read(authStateProvider.notifier).lock();
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context); // popup loading
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('恢复失败: 密码错误或文件已损坏')));
          }
        }
      }
    }
  }
}
