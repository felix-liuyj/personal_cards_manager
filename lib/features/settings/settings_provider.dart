import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==================== Keys ====================
const _kBiometricsEnabled = 'security_biometrics_enabled';
const _kAutoLockEnabled = 'security_auto_lock_enabled';
const _kAutoLockMinutes = 'security_auto_lock_minutes';
const _kClipboardClearEnabled = 'security_clipboard_clear_enabled';
const _kClipboardClearSeconds = 'security_clipboard_clear_seconds';

// ==================== Model ====================
class AppSettings {
  final bool biometricsEnabled;
  final bool autoLockEnabled;
  final int autoLockMinutes;
  final bool clipboardClearEnabled;
  final int clipboardClearSeconds;

  const AppSettings({
    this.biometricsEnabled = false,
    this.autoLockEnabled = false,
    this.autoLockMinutes = 5,
    this.clipboardClearEnabled = true,
    this.clipboardClearSeconds = 60,
  });

  AppSettings copyWith({
    bool? biometricsEnabled,
    bool? autoLockEnabled,
    int? autoLockMinutes,
    bool? clipboardClearEnabled,
    int? clipboardClearSeconds,
  }) {
    return AppSettings(
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      autoLockEnabled: autoLockEnabled ?? this.autoLockEnabled,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      clipboardClearEnabled:
          clipboardClearEnabled ?? this.clipboardClearEnabled,
      clipboardClearSeconds:
          clipboardClearSeconds ?? this.clipboardClearSeconds,
    );
  }
}

// ==================== Provider ====================
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
      return AppSettingsNotifier();
    });

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      biometricsEnabled: prefs.getBool(_kBiometricsEnabled) ?? false,
      autoLockEnabled: prefs.getBool(_kAutoLockEnabled) ?? false,
      autoLockMinutes: prefs.getInt(_kAutoLockMinutes) ?? 5,
      clipboardClearEnabled: prefs.getBool(_kClipboardClearEnabled) ?? true,
      clipboardClearSeconds: prefs.getInt(_kClipboardClearSeconds) ?? 60,
    );
  }

  Future<void> setBiometricsEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricsEnabled, v);
    state = state.copyWith(biometricsEnabled: v);
  }

  Future<void> setAutoLockEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoLockEnabled, v);
    state = state.copyWith(autoLockEnabled: v);
  }

  Future<void> setAutoLockMinutes(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAutoLockMinutes, v);
    state = state.copyWith(autoLockMinutes: v);
  }

  Future<void> setClipboardClearEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kClipboardClearEnabled, v);
    state = state.copyWith(clipboardClearEnabled: v);
  }

  Future<void> setClipboardClearSeconds(int v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kClipboardClearSeconds, v);
    state = state.copyWith(clipboardClearSeconds: v);
  }
}
