import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 全局安全的存储服务提供者
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final FlutterSecureStorage _storage;

  static const String _isarMasterKey = 'isar_master_key';

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          // 确保开启了特定平台的安全选项，防克隆和备份泄漏
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  /// 写入任意敏感信息
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// 读取任意敏感信息
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// 获取或生成 Isar 本地数据库的主密钥 (长度通常为32字节/256位)
  Future<List<int>> getOrGenerateIsarKey() async {
    final existingKey = await read(_isarMasterKey);
    if (existingKey != null) {
      return base64Decode(existingKey);
    }

    // 生成安全的随机 32 字节密钥
    final random = Random.secure();
    final newKey = List<int>.generate(32, (_) => random.nextInt(256));
    final encodedKey = base64Encode(newKey);
    
    await write(_isarMasterKey, encodedKey);
    return newKey;
  }
}
