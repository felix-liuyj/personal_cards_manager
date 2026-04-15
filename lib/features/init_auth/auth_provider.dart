import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/security/biometric_service.dart';
import '../../core/utils/debug_logger.dart';
import '../settings/settings_provider.dart';

enum AuthState { locked, unlocked }

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final settings = ref.watch(appSettingsProvider);
  final logger = ref.read(debugLoggerProvider.notifier);
  return AuthNotifier(
    ref.read(biometricServiceProvider),
    settings.biometricsEnabled,
    logger,
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final BiometricService _biometricService;
  final DebugLogger _logger;

  AuthNotifier(this._biometricService, bool biometricsEnabled, this._logger)
    : super(biometricsEnabled ? AuthState.locked : AuthState.unlocked) {
    _logger.info(
      'AuthNotifier 初始化: biometricsEnabled=$biometricsEnabled, 初始状态=${biometricsEnabled ? "locked" : "unlocked"}',
    );
  }

  /// 执行高安全验证以解锁应用
  Future<void> authenticate() async {
    _logger.info('AuthNotifier: 开始执行身份验证');
    final success = await _biometricService.authenticate('请验证以解锁您的核心资产记录');
    if (success) {
      _logger.info('AuthNotifier: 验证成功，解锁应用');
      state = AuthState.unlocked;
    } else {
      _logger.warning('AuthNotifier: 验证失败，保持锁定状态');
    }
  }

  /// 剥夺当前访问权限，强制应用重归锁定状态
  void lock() {
    _logger.info('AuthNotifier: 锁定应用');
    state = AuthState.locked;
  }
}
