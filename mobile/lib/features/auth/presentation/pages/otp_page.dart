import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/fcm_token_service.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../blocs/otp/otp_bloc.dart';
import '../widgets/otp_input_field.dart';

class OtpPage extends StatelessWidget {
  /// Numéro au format E.164 (ex: `+221785384455`).
  final String phone;

  const OtpPage({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OtpBloc>(
      create: (_) => sl<OtpBloc>(),
      child: _OtpView(phone: phone),
    );
  }
}

class _OtpView extends StatefulWidget {
  final String phone;
  const _OtpView({required this.phone});

  @override
  State<_OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<_OtpView> {
  static const int _resendSeconds = 30;

  String _code = '';
  int _secondsLeft = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _secondsLeft = _resendSeconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _onCodeChanged(String code) {
    setState(() => _code = code);
  }

  void _verify() {
    context.read<OtpBloc>().add(
          OtpVerifySubmitted(phone: widget.phone, code: _code),
        );
  }

  void _resend() {
    if (_secondsLeft > 0) return;
    context.read<OtpBloc>().add(OtpResendSubmitted(widget.phone));
  }

  String _formatPhone(String e164) {
    if (!e164.startsWith('+221') || e164.length != 13) return e164;
    final d = e164.substring(4);
    return '+221 ${d.substring(0, 2)} ${d.substring(2, 5)} '
        '${d.substring(5, 7)} ${d.substring(7, 9)}';
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void _showSnack(String message, {Color? bg}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: bg ?? AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        greenOffset: const Offset(220, -100),
        redOffset: const Offset(-180, 200),
        child: SafeArea(
          child: BlocConsumer<OtpBloc, OtpState>(
            listener: (context, state) {
              if (state is OtpVerified) {
                sl<FcmTokenService>().init();
                if (state.session.profileComplete) {
                  context.go(AppRoutes.home);
                } else {
                  context.go(AppRoutes.completeProfile);
                }
              } else if (state is OtpResent) {
                _startCountdown();
                _showSnack('Nouveau code envoyé', bg: AppColors.green);
              } else if (state is OtpError) {
                _showSnack(state.message);
              }
            },
            builder: (context, state) {
              final verifying = state is OtpVerifying;
              final resending = state is OtpResending;
              final isComplete = _code.length == 6;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLg,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.sizeOf(context).height -
                        MediaQuery.viewPaddingOf(context).vertical -
                        MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),
                        SvgPicture.asset(
                          'assets/logos/logo.svg',
                          width: MediaQuery.sizeOf(context).width * 0.40,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: AppDimensions.paddingXl),
                        Text(
                          'Vérifiez votre numéro',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h1,
                        ),
                        const SizedBox(height: AppDimensions.paddingSm),
                        _Subtitle(phone: _formatPhone(widget.phone)),
                        const SizedBox(height: AppDimensions.paddingXl),
                        OtpInputField(
                          onChanged: _onCodeChanged,
                          enabled: !verifying,
                        ),
                        const SizedBox(height: AppDimensions.paddingMd),
                        _ResendRow(
                          secondsLeft: _secondsLeft,
                          formattedTimer: _formatTimer(_secondsLeft),
                          loading: resending,
                          onResend: _resend,
                        ),
                        const SizedBox(height: AppDimensions.paddingLg),
                        PrimaryButton(
                          label: 'Vérifier',
                          loading: verifying,
                          onPressed:
                              (isComplete && !verifying) ? _verify : null,
                        ),
                        const Spacer(flex: 3),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  final String phone;
  const _Subtitle({required this.phone});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTextStyles.subtitle,
        children: [
          const TextSpan(text: 'Code envoyé au '),
          TextSpan(
            text: phone,
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.yellow,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _ResendRow extends StatelessWidget {
  final int secondsLeft;
  final String formattedTimer;
  final bool loading;
  final VoidCallback onResend;

  const _ResendRow({
    required this.secondsLeft,
    required this.formattedTimer,
    required this.loading,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Vous n'avez pas reçu de code ?",
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm,
        ),
        const SizedBox(height: 4),
        if (loading)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.yellow,
            ),
          )
        else if (secondsLeft > 0)
          Text(
            'Renvoyer dans $formattedTimer',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.yellow,
              fontWeight: FontWeight.w700,
            ),
          )
        else
          GestureDetector(
            onTap: onResend,
            child: Text(
              'Renvoyer le code',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.yellow,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.yellow,
              ),
            ),
          ),
      ],
    );
  }
}
