import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// 检查设备是否支持生物识别及其相关权限环境
  Future<bool> get isBiometricSupported async {
    final isAvailable = await _auth.canCheckBiometrics;
    final isDeviceSupported = await _auth.isDeviceSupported();
    return isAvailable && isDeviceSupported;
  }

  /// 唤起系统层级授权验证（TouchID / FaceID / PIN）
  Future<bool> authenticate(String localizedReason) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // 若生物识别失败，允许回退到系统密码/PIN
        ),
      );
    } catch (e) {
      return false; // 用户取消或是其他错误直接挂断
    }
  }
}
