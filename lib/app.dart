import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_cards_manager/core/database/database_service.dart';
import 'package:personal_cards_manager/core/security/security_service.dart';
import 'package:personal_cards_manager/screens/home/home_screen.dart';
import 'package:personal_cards_manager/screens/auth/auth_screen.dart';
import 'package:personal_cards_manager/screens/splash/splash_screen.dart';
import 'package:personal_cards_manager/screens/bank_cards/bank_cards_list_screen.dart';
import 'package:personal_cards_manager/screens/member_cards/member_cards_list_screen.dart';
import 'package:personal_cards_manager/screens/documents/documents_list_screen.dart';
import 'package:personal_cards_manager/screens/search/search_screen.dart';
import 'package:personal_cards_manager/screens/settings/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/bank-cards',
        builder: (context, state) => const BankCardsListScreen(),
      ),
      GoRoute(
        path: '/member-cards',
        builder: (context, state) => const MemberCardsListScreen(),
      ),
      GoRoute(
        path: '/documents',
        builder: (context, state) => const DocumentsListScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

final appInitializerProvider = FutureProvider<bool>((ref) async {
  await DatabaseService.instance.initialize();
  await SecurityService.instance.isInitialized();
  return SecurityService.instance.isInitialized();
});
