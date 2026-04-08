import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clipboardServiceProvider = Provider((ref) => ClipboardService());

class ClipboardService {
  /// 一键无损提取敏感信息并加载防泄漏倒计时
  Future<void> copyAndAutoClear(String text, {Duration autoClear = const Duration(seconds: 45)}) async {
    await Clipboard.setData(ClipboardData(text: text));
    
    // Phase 4: 到期全自动覆写清空剪贴板功能
    if (autoClear.inSeconds > 0) {
      Future.delayed(autoClear, () async {
        final current = await Clipboard.getData('text/plain');
        if (current?.text == text) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      });
    }
  }
}
