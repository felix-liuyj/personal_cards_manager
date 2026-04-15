import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/debug_logger.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService(ref.read(debugLoggerProvider.notifier));
});

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final DebugLogger _logger;

  BiometricService(this._logger);

  /// 检查设备是否支持生物识别及其相关权限环境
  Future<bool> get isBiometricSupported async {
    _logger.info('检查设备生物识别支持');
    try {
      final isAvailable = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      final result = isAvailable && isDeviceSupported;

      _logger.info(
        '生物识别检查结果: canCheckBiometrics=$isAvailable, isDeviceSupported=$isDeviceSupported, 最终结果=$result',
      );

      if (result) {
        // 获取可用的生物识别类型
        try {
          final availableBiometrics = await _auth.getAvailableBiometrics();
          _logger.info('可用的生物识别类型: $availableBiometrics');
        } catch (e) {
          _logger.warning('无法获取生物识别类型: $e');
        }
      }

      return result;
    } catch (e) {
      _logger.error('检查生物识别支持时出错', error: e);
      return false;
    }
  }

  /// 唤起系统层级授权验证（TouchID / FaceID / PIN）
  Future<bool> authenticate(String localizedReason) async {
    _logger.info('开始生物识别验证: $localizedReason');
    try {
      final result = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // 若生物识别失败，允许回退到系统密码/PIN
        ),
      );

      _logger.info('生物识别验证结果: ${result ? "成功" : "失败"}');
      return result;
    } catch (e) {
      _logger.error('生物识别验证异常', error: e);
      return false; // 用户取消或是其他错误直接挂断
    }
  }
}
