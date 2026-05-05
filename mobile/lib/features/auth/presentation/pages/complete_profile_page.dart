import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/user_level.dart';
import '../blocs/complete_profile/complete_profile_bloc.dart';
import '../widgets/avatar_initials.dart';
import '../widgets/labeled_text_field.dart';
import '../widgets/level_selector.dart';

class CompleteProfilePage extends StatelessWidget {
  const CompleteProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CompleteProfileBloc>(
      create: (_) => sl<CompleteProfileBloc>(),
      child: const _CompleteProfileView(),
    );
  }
}

class _CompleteProfileView extends StatefulWidget {
  const _CompleteProfileView();

  @override
  State<_CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<_CompleteProfileView> {
  static final _usernameRegex = RegExp(r'^[a-z0-9_]{3,20}$');

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  UserLevel? _level;
  Timer? _usernameDebounce;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_refresh);
    _usernameController.addListener(_refresh);
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _onUsernameChanged(String value) {
    final bloc = context.read<CompleteProfileBloc>();
    _usernameDebounce?.cancel();

    if (value.isEmpty || !_usernameRegex.hasMatch(value)) {
      bloc.add(const UsernameCleared());
      return;
    }
    _usernameDebounce = Timer(
      const Duration(milliseconds: 500),
      () => bloc.add(UsernameCheckRequested(value)),
    );
  }

  void _onLevelChanged(UserLevel level) => setState(() => _level = level);

  bool _canSubmit(CompleteProfileState bs) {
    final fullName = _fullNameController.text.trim();
    if (fullName.length < 2) return false;
    if (!_usernameRegex.hasMatch(_usernameController.text)) return false;
    if (bs.usernameStatus != UsernameStatus.available) return false;
    if (_level == null) return false;
    if (bs.submitStatus == SubmitStatus.loading) return false;
    return true;
  }

  void _submit() {
    context.read<CompleteProfileBloc>().add(
          ProfileSubmitted(
            fullName: _fullNameController.text.trim(),
            username: _usernameController.text,
            level: _level!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        greenOffset: const Offset(-200, 400),
        redOffset: const Offset(200, -100),
        child: SafeArea(
          child: BlocConsumer<CompleteProfileBloc, CompleteProfileState>(
            listener: (context, state) {
              if (state.submitStatus == SubmitStatus.success) {
                context.go(AppRoutes.home);
              } else if (state.submitStatus == SubmitStatus.error &&
                  state.errorMessage != null) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage!,
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: AppColors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
              }
            },
            builder: (context, state) {
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
                        const SizedBox(height: AppDimensions.paddingXl),
                        Text(
                          'Complétez votre profil',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h1,
                        ),
                        const SizedBox(height: AppDimensions.paddingSm),
                        Text(
                          'Vous y êtes presque! Parlez-nous de vous.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subtitle,
                        ),
                        const SizedBox(height: AppDimensions.paddingXl),
                        AvatarInitials(fullName: _fullNameController.text),
                        const SizedBox(height: AppDimensions.paddingXl),
                        LabeledTextField(
                          controller: _fullNameController,
                          iconAsset: 'assets/icons/fullname.png',
                          hint: 'Nom complet',
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(100),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.paddingMd),
                        LabeledTextField(
                          controller: _usernameController,
                          iconAsset: 'assets/icons/@.png',
                          hint: 'username',
                          onChanged: _onUsernameChanged,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-z0-9_]'),
                            ),
                            LengthLimitingTextInputFormatter(20),
                          ],
                          trailing: _UsernameStatusIcon(
                            status: state.usernameStatus,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingMd),
                        LevelSelector(
                          selected: _level,
                          onChanged: _onLevelChanged,
                        ),
                        const SizedBox(height: AppDimensions.paddingLg),
                        PrimaryButton(
                          label: 'Commencer à jouer',
                          loading: state.submitStatus == SubmitStatus.loading,
                          onPressed: _canSubmit(state) ? _submit : null,
                          trailingIcon: Image.asset(
                            'assets/icons/final_check.png',
                            width: 20,
                            height: 20,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingLg),
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

class _UsernameStatusIcon extends StatelessWidget {
  final UsernameStatus status;
  const _UsernameStatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      UsernameStatus.checking => const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.yellow,
          ),
        ),
      UsernameStatus.available => Image.asset(
          'assets/icons/success.png',
          width: 22,
          height: 22,
        ),
      UsernameStatus.taken => const Icon(
          Icons.error_outline,
          color: AppColors.red,
          size: 22,
        ),
      UsernameStatus.error => const Icon(
          Icons.warning_amber,
          color: Colors.orangeAccent,
          size: 22,
        ),
      UsernameStatus.idle => const SizedBox.shrink(),
    };
  }
}
