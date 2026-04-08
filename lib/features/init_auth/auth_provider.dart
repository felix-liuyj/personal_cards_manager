import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/security/biometric_service.dart';

enum AuthState { locked, unlocked }

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(biometricServiceProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final BiometricService _biometricService;

  AuthNotifier(this._biometricService) : super(AuthState.locked);

  /// 执行高安全验证以解锁应用
  Future<void> authenticate() async {
    final success = await _biometricService.authenticate('请验证以解锁您的核心资产记录');
    if (success) {
      state = AuthState.unlocked;
    }
  }

  /// 剥夺当前访问权限，强制应用重归锁定状态
  void lock() {
    state = AuthState.locked;
  }
}
