import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final backupServiceProvider = Provider((ref) => BackupService());

class BackupService {
  /// 模拟将本地 Isar 全量记录通过强 AES 加锁后生成为纯本地迁移文件 (.pcm 格式)
  Future<String> exportEncryptedBackup(Map<String, dynamic> isarRawDump, String pinToken) async {
    // 此处将在应用层针对 Dump 做纯 Dart 侧的 AES 混合加密处理 (为减少体积采用 Base64)
    final jsonPayload = jsonEncode(isarRawDump);
    // [Mock] AES execution flow
    final mockEncryptedString = base64Encode(utf8.encode(jsonPayload));
    return mockEncryptedString; 
  }
}
