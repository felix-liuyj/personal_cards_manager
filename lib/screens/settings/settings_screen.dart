import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricsEnabled = false;
  bool _autoLockEnabled = true;
  bool _clipboardClearEnabled = true;
  int _autoLockMinutes = 5;
  int _clipboardClearSeconds = 60;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Load settings from secure storage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          _buildSecuritySection(),
          _buildDisplaySection(),
          _buildDataSection(),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '安全设置',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('生物识别'),
          subtitle: const Text('使用指纹或面容解锁'),
          value: _biometricsEnabled,
          onChanged: (value) {
            setState(() => _biometricsEnabled = value);
          },
        ),
        ListTile(
          title: const Text('修改 PIN'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _changePin,
        ),
        SwitchListTile(
          title: const Text('自动锁定'),
          subtitle: Text('$_autoLockMinutes 分钟无操作后锁定'),
          value: _autoLockEnabled,
          onChanged: (value) {
            setState(() => _autoLockEnabled = value);
          },
        ),
        if (_autoLockEnabled)
          ListTile(
            title: const Text('锁定时间'),
            trailing: Text('$_autoLockMinutes 分钟'),
            onTap: _selectAutoLockTime,
          ),
        SwitchListTile(
          title: const Text('自动清理剪贴板'),
          subtitle: Text('复制后 $_clipboardClearSeconds 秒清理'),
          value: _clipboardClearEnabled,
          onChanged: (value) {
            setState(() => _clipboardClearEnabled = value);
          },
        ),
      ],
    );
  }

  Widget _buildDisplaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '显示设置',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        ListTile(
          title: const Text('主题模式'),
          trailing: const Text('跟随系统'),
          onTap: () {
            // TODO: Theme selection
          },
        ),
        ListTile(
          title: const Text('列表显示方式'),
          trailing: const Text('卡片'),
          onTap: () {
            // TODO: List display mode
          },
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '数据管理',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        ListTile(
          title: const Text('备份数据'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _backupData,
        ),
        ListTile(
          title: const Text('恢复数据'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _restoreData,
        ),
        ListTile(
          title: const Text('清除缓存'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _clearCache,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '关于',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        const ListTile(title: Text('版本'), trailing: Text('1.0.0')),
        ListTile(
          title: const Text('隐私政策'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Privacy policy
          },
        ),
      ],
    );
  }

  void _changePin() {
    // TODO: Navigate to change PIN screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('修改 PIN 功能开发中')));
  }

  void _selectAutoLockTime() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('1 分钟'),
              onTap: () {
                setState(() => _autoLockMinutes = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('5 分钟'),
              onTap: () {
                setState(() => _autoLockMinutes = 5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('10 分钟'),
              onTap: () {
                setState(() => _autoLockMinutes = 10);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('30 分钟'),
              onTap: () {
                setState(() => _autoLockMinutes = 30);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _backupData() {
    // TODO: Backup data
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('备份功能开发中')));
  }

  void _restoreData() {
    // TODO: Restore data
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('恢复功能开发中')));
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除缓存'),
        content: const Text('确定要清除缓存吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('缓存已清除')));
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
