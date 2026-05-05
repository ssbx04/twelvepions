import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../blocs/phone/phone_bloc.dart';
import '../widgets/phone_input_field.dart';

class PhonePage extends StatelessWidget {
  const PhonePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PhoneBloc>(
      create: (_) => sl<PhoneBloc>(),
      child: const _PhoneView(),
    );
  }
}

class _PhoneView extends StatefulWidget {
  const _PhoneView();

  @override
  State<_PhoneView> createState() => _PhoneViewState();
}

class _PhoneViewState extends State<_PhoneView> {
  final TextEditingController _controller = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    final digits = _controller.text.replaceAll(RegExp(r'\D'), '');
    final valid = digits.length == 9;
    if (valid != _isValid) setState(() => _isValid = valid);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final digits = _controller.text.replaceAll(RegExp(r'\D'), '');
    final phone = '+221$digits';
    context.read<PhoneBloc>().add(PhoneSubmitted(phone));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        greenOffset: const Offset(-180, -120),
        redOffset: const Offset(220, 80),
        child: SafeArea(
          child: BlocConsumer<PhoneBloc, PhoneState>(
            listener: (context, state) {
              if (state is PhoneOtpSent) {
                context.push(AppRoutes.otp, extra: state.phone);
              } else if (state is PhoneError) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        state.message,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: AppColors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
              }
            },
            builder: (context, state) {
              final loading = state is PhoneLoading;
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
                          'Entrez votre numéro',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h1,
                        ),
                        const SizedBox(height: AppDimensions.paddingSm),
                        Text(
                          'On vous enverra un code de vérification',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: AppDimensions.paddingXl),
                        PhoneInputField(controller: _controller),
                        const SizedBox(height: AppDimensions.paddingMd),
                        const _DisclaimerText(),
                        const SizedBox(height: AppDimensions.paddingLg),
                        PrimaryButton(
                          label: 'Continuer',
                          loading: loading,
                          onPressed: (_isValid && !loading) ? _submit : null,
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

class _DisclaimerText extends StatelessWidget {
  const _DisclaimerText();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
        children: [
          const TextSpan(text: 'En cliquant sur continuer vous acceptez nos '),
          TextSpan(text: 'Termes', style: AppTextStyles.linkSm),
          const TextSpan(text: ' & '),
          TextSpan(text: 'Conditions', style: AppTextStyles.linkSm),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
