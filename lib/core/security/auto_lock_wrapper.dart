import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_cards_manager/features/init_auth/auth_provider.dart';
import 'package:personal_cards_manager/features/settings/settings_provider.dart';

class AutoLockWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AutoLockWrapper({super.key, required this.child});

  @override
  ConsumerState<AutoLockWrapper> createState() => _AutoLockWrapperState();
}

class _AutoLockWrapperState extends ConsumerState<AutoLockWrapper>
    with WidgetsBindingObserver {
  DateTime? _pausedTime;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final settings = ref.read(appSettingsProvider);
    if (!settings.autoLockEnabled) return;

    final autoLockDuration = Duration(minutes: settings.autoLockMinutes);

    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _pausedTime = DateTime.now();
      
      // 我们也可以启动一个后台定时器，如果用户一直不回来就自动锁定
      // 这里的确切执行依赖于 OS 是否允许定时器在后台运行
      _checkTimer?.cancel();
      _checkTimer = Timer(autoLockDuration, () {
        ref.read(authStateProvider.notifier).lock();
      });
    } else if (state == AppLifecycleState.resumed) {
      _checkTimer?.cancel();
      if (_pausedTime != null) {
        final elapsed = DateTime.now().difference(_pausedTime!);
        if (elapsed >= autoLockDuration) {
          // 时间已满足或超过要求，立即锁定
          ref.read(authStateProvider.notifier).lock();
        }
      }
      _pausedTime = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
