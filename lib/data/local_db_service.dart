import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/models.dart';

final localDbProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  
  // 初始化 Isar 纯本地容器实例 (数据落盘已受到系统硬件与 iOS/Android 沙盒的双重保护)
  final isar = await Isar.open(
    [BankCardSchema, MemberCardSchema, IDCardSchema, CustomTagSchema, CustomGroupSchema],
    directory: dir.path,
    inspector: true,
  );
  
  return isar;
});
