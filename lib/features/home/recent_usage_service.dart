import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kRecentViewed = 'recent_viewed';
const _kRecentCopied = 'recent_copied';
const _maxEntries = 20;

class RecentEntry {
  final String type; // 'bank', 'member', 'id'
  final int id;
  final String title;
  final DateTime timestamp;

  RecentEntry({
    required this.type,
    required this.id,
    required this.title,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'title': title,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RecentEntry.fromJson(Map<String, dynamic> json) => RecentEntry(
    type: json['type'] as String,
    id: json['id'] as int,
    title: json['title'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

final recentUsageServiceProvider = Provider<RecentUsageService>((ref) {
  return RecentUsageService();
});

class RecentUsageService {
  Future<List<RecentEntry>> getRecentViewed() => _load(_kRecentViewed);
  Future<List<RecentEntry>> getRecentCopied() => _load(_kRecentCopied);

  Future<void> recordViewed({
    required String type,
    required int id,
    required String title,
  }) => _addEntry(_kRecentViewed, RecentEntry(
    type: type, id: id, title: title, timestamp: DateTime.now()));

  Future<void> recordCopied({
    required String type,
    required int id,
    required String title,
  }) => _addEntry(_kRecentCopied, RecentEntry(
    type: type, id: id, title: title, timestamp: DateTime.now()));

  Future<void> clearViewed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRecentViewed);
  }

  Future<void> clearCopied() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRecentCopied);
  }

  Future<List<RecentEntry>> _load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(key) ?? [];
    return raw
        .map((e) {
          try {
            return RecentEntry.fromJson(jsonDecode(e) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<RecentEntry>()
        .toList();
  }

  Future<void> _addEntry(String key, RecentEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await _load(key);

    // 移除同 id+type 的旧记录（保持最新在前）
    final filtered = existing
        .where((e) => !(e.id == entry.id && e.type == entry.type))
        .toList();

    filtered.insert(0, entry);

    final limited = filtered.take(_maxEntries).toList();
    await prefs.setStringList(
      key,
      limited.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
