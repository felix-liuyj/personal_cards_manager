import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_cards_manager/core/utils/debug_logger.dart';

class DebugLogScreen extends ConsumerWidget {
  const DebugLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(debugLoggerProvider);
    final logger = ref.read(debugLoggerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('调试日志'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: '复制全部日志',
            onPressed: () => _copyAllLogs(context, logs),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清空日志',
            onPressed: () {
              logger.clear();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('日志已清空')));
            },
          ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无日志', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildLogItem(context, log);
              },
            ),
    );
  }

  Widget _buildLogItem(BuildContext context, LogEntry log) {
    Color levelColor;
    IconData levelIcon;

    switch (log.level) {
      case 'ERROR':
        levelColor = Colors.red;
        levelIcon = Icons.error_outline;
        break;
      case 'WARN':
        levelColor = Colors.orange;
        levelIcon = Icons.warning_amber_outlined;
        break;
      case 'INFO':
        levelColor = Colors.blue;
        levelIcon = Icons.info_outline;
        break;
      case 'DEBUG':
        levelColor = Colors.grey;
        levelIcon = Icons.bug_report_outlined;
        break;
      default:
        levelColor = Colors.grey;
        levelIcon = Icons.circle_outlined;
    }

    final timeStr =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:'
        '${log.timestamp.minute.toString().padLeft(2, '0')}:'
        '${log.timestamp.second.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(levelIcon, size: 16, color: levelColor),
                const SizedBox(width: 8),
                Text(
                  log.level,
                  style: TextStyle(
                    color: levelColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(log.message, style: const TextStyle(fontSize: 14)),
            if (log.error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.error!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _copyAllLogs(BuildContext context, List<LogEntry> logs) {
    if (logs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有日志可复制')));
      return;
    }

    final logText = logs.map((log) => log.toString()).join('\n');
    Clipboard.setData(ClipboardData(text: logText));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已复制所有日志到剪贴板')));
  }
}
