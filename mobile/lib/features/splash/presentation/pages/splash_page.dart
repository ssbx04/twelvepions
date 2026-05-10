import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/fcm_token_service.dart';
import '../../../../core/storage/auth_local_storage.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

/// Splash screen — affiché au lancement de l'app, ~2,5 s.
///
/// Composition (du plus en arrière au plus en avant) :
///  1. Linear gradient sombre (fond)
///  2. Image du pion vert (haut-droite, image blurrée)
///  3. Image du pion rouge (bas-gauche, image blurrée)
///  4. Logo "12 PIONS" centré
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const Duration _minSplashDuration = Duration(milliseconds: 2000);
  static const double _pionSize = 440;
  static const double _blurSigma = 12;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Détermine où rediriger l'utilisateur en fonction de la session locale
  /// et de la validité du JWT côté serveur.
  Future<void> _bootstrap() async {
    final minDelay = Future<void>.delayed(_minSplashDuration);
    final route = await _resolveRoute();
    await minDelay;
    if (!mounted) return;
    context.go(route);
  }

  Future<String> _resolveRoute() async {
    final repo = sl<AuthRepository>();
    final storage = sl<AuthLocalStorage>();

    if (!await repo.hasSession()) return AppRoutes.phone;

    final result = await repo.getMe();
    return result.fold(
      (failure) async {
        if (failure is UnauthorizedFailure) {
          await repo.logout();
          return AppRoutes.phone;
        }
        final complete = await storage.readProfileComplete();
        return complete ? AppRoutes.home : AppRoutes.completeProfile;
      },
      (user) async {
        // Upload FCM token maintenant qu'on sait que le JWT est valide.
        sl<FcmTokenService>().init();
        return user.profileComplete ? AppRoutes.home : AppRoutes.completeProfile;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgGradientStart, AppColors.bgGradientEnd],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // ─── Pion vert (haut-droite, image floutée) ──────────────
                Positioned(
                  top: -90,
                  right: -100,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: _blurSigma,
                      sigmaY: _blurSigma,
                    ),
                    child: Image.asset(
                      'assets/images/pion_green.png',
                      width: _pionSize,
                      height: _pionSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // ─── Pion rouge (bas-gauche, image floutée) ──────────────
                Positioned(
                  bottom: -90,
                  left: -100,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: _blurSigma,
                      sigmaY: _blurSigma,
                    ),
                    child: Image.asset(
                      'assets/images/pion_rouge.png',
                      width: _pionSize,
                      height: _pionSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // ─── Logo central ────────────────────────────────────────
                Center(
                  child: SvgPicture.asset(
                    'assets/logos/logo.svg',
                    width: w * 0.45,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
