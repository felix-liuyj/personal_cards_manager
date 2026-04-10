import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_cards_manager/features/settings/settings_provider.dart';

final clipboardServiceProvider = Provider<ClipboardService>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return ClipboardService(
    autoClearEnabled: settings.clipboardClearEnabled,
    autoClearSeconds: settings.clipboardClearSeconds,
  );
});

class ClipboardService {
  final bool autoClearEnabled;
  final int autoClearSeconds;

  ClipboardService({
    this.autoClearEnabled = true,
    this.autoClearSeconds = 60,
  });

  /// 复制文本到剪贴板，并根据设置自动在指定秒数后清除
  Future<void> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (autoClearEnabled && autoClearSeconds > 0) {
      Future.delayed(Duration(seconds: autoClearSeconds), () async {
        final current = await Clipboard.getData('text/plain');
        if (current?.text == text) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      });
    }
  }

  /// 立即清除剪贴板
  Future<void> clear() async {
    await Clipboard.setData(const ClipboardData(text: ''));
  }
}
