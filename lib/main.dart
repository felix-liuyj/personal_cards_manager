import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/init_auth/auth_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'core/notifications/notification_service.dart';
import 'core/security/auto_lock_wrapper.dart';
import 'core/theme/fabric_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  runApp(const ProviderScope(child: PersonalCardsApp()));
}

class PersonalCardsApp extends ConsumerStatefulWidget {
  const PersonalCardsApp({super.key});

  @override
  ConsumerState<PersonalCardsApp> createState() => _PersonalCardsAppState();
}

class _PersonalCardsAppState extends ConsumerState<PersonalCardsApp> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: '卡片包',
      debugShowCheckedModeBanner: false,
      theme: FabricTheme.lightTheme(),
      darkTheme: FabricTheme.darkTheme(),
      themeMode: ThemeMode.system,
      home: AutoLockWrapper(
        child: authState == AuthState.locked
            ? const AuthScreen()
            : const HomeScreen(),
      ),
    );
  }
}
