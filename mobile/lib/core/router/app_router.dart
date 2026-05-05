import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/complete_profile_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/phone_page.dart';
import '../../features/home/presentation/blocs/home/home_bloc.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../di/service_locator.dart';

/// Routes nommées globales.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String phone = '/phone';
  static const String otp = '/otp';
  static const String completeProfile = '/complete-profile';
  static const String home = '/home';
}

/// Configuration centrale du routeur de l'app.
final GoRouter appRouter = GoRouter(
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
      builder: (context, state) => const PhonePage(),
    ),
    GoRoute(
      path: AppRoutes.otp,
      name: 'otp',
      builder: (context, state) {
        final phone = state.extra as String? ?? '';
        return OtpPage(phone: phone);
      },
    ),
    GoRoute(
      path: AppRoutes.completeProfile,
      name: 'complete-profile',
      builder: (context, state) => const CompleteProfilePage(),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<HomeBloc>()..add(const HomeStarted()),
        child: const HomePage(),
      ),
    ),
  ],
);
