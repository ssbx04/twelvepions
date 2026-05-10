import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/complete_profile_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/phone_page.dart';
import '../../features/friends/presentation/blocs/friends_bloc.dart';
import '../../features/home/presentation/blocs/home/home_bloc.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/play/presentation/pages/matchmaking_page.dart';
import '../../features/game/presentation/pages/game_page.dart';
import '../../features/game/presentation/pages/local_game_page.dart';
import '../di/service_locator.dart';

/// Routes nommées globales.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String phone = '/phone';
  static const String otp = '/otp';
  static const String completeProfile = '/complete-profile';
  static const String home = '/home';
  static const String matchmaking = '/matchmaking';
  static const String localGame = '/local-game';
  static const String game = '/game/:gameId';
}

Page<dynamic> _buildFadeTransitionPage(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

Page<dynamic> _buildSlideUpTransitionPage(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);
      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}

/// Configuration centrale du routeur de l'app.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.phone,
      name: 'phone',
      pageBuilder: (context, state) => _buildFadeTransitionPage(context, state, const PhonePage()),
    ),
    GoRoute(
      path: AppRoutes.otp,
      name: 'otp',
      pageBuilder: (context, state) {
        final phone = state.extra as String? ?? '';
        return _buildFadeTransitionPage(context, state, OtpPage(phone: phone));
      },
    ),
    GoRoute(
      path: AppRoutes.completeProfile,
      name: 'complete-profile',
      pageBuilder: (context, state) => _buildFadeTransitionPage(context, state, const CompleteProfilePage()),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      pageBuilder: (context, state) => _buildFadeTransitionPage(
        context,
        state,
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<HomeBloc>()..add(const HomeStarted())),
            BlocProvider(create: (_) => sl<FriendsBloc>()..add(FriendsLoaded())),
          ],
          child: const HomePage(),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.matchmaking,
      name: 'matchmaking',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final isAi = extra['ai'] as bool? ?? false;
        return _buildFadeTransitionPage(context, state, MatchmakingPage(isAi: isAi));
      },
    ),
    GoRoute(
      path: AppRoutes.localGame,
      name: 'local-game',
      pageBuilder: (context, state) => _buildSlideUpTransitionPage(context, state, const LocalGamePage()),
    ),
    GoRoute(
      path: AppRoutes.game,
      name: 'game',
      pageBuilder: (context, state) {
        final gameId = state.pathParameters['gameId'] ?? '';
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final yourColor = extra['yourColor'] as String? ?? 'X';
        final stateData = extra['stateData'] as Map<String, dynamic>?;
        return _buildSlideUpTransitionPage(
          context,
          state,
          GamePage(gameId: gameId, yourColor: yourColor, initialStateData: stateData),
        );
      },
    ),
  ],
);
