import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/errors/failures.dart';
import '../../../domain/entities/auth_session.dart';
import '../../../domain/entities/user_level.dart';
import '../../../domain/usecases/check_username.dart';
import '../../../domain/usecases/complete_profile.dart';

part 'complete_profile_event.dart';
part 'complete_profile_state.dart';

class CompleteProfileBloc
    extends Bloc<CompleteProfileEvent, CompleteProfileState> {
  final CheckUsername checkUsername;
  final CompleteProfile completeProfile;

  CompleteProfileBloc({
    required this.checkUsername,
    required this.completeProfile,
  }) : super(const CompleteProfileState()) {
    on<UsernameCheckRequested>(_onCheckUsername);
    on<UsernameCleared>(
      (_, emit) => emit(state.copyWith(
        usernameStatus: UsernameStatus.idle,
        lastCheckedUsername: '',
      )),
    );
    on<ProfileSubmitted>(_onSubmit);
  }

  Future<void> _onCheckUsername(
    UsernameCheckRequested event,
    Emitter<CompleteProfileState> emit,
  ) async {
    emit(state.copyWith(
      usernameStatus: UsernameStatus.checking,
      lastCheckedUsername: event.username,
    ));
    final result = await checkUsername(event.username);
    // Si le user a changé de username entre-temps, ignore le résultat.
    if (state.lastCheckedUsername != event.username) return;
    result.fold(
      (failure) => emit(state.copyWith(
        usernameStatus: UsernameStatus.error,
        errorMessage: failure.message,
      )),
      (available) => emit(state.copyWith(
        usernameStatus:
            available ? UsernameStatus.available : UsernameStatus.taken,
        clearError: true,
      )),
    );
  }

  Future<void> _onSubmit(
    ProfileSubmitted event,
    Emitter<CompleteProfileState> emit,
  ) async {
    emit(state.copyWith(submitStatus: SubmitStatus.loading, clearError: true));
    final result = await completeProfile(
      fullName: event.fullName,
      username: event.username,
      level: event.level,
    );
    result.fold(
      (failure) {
        // Si username pris pendant la soumission, refléter aussi sur l'état dispo.
        final newUsernameStatus = failure is UsernameTakenFailure
            ? UsernameStatus.taken
            : state.usernameStatus;
        emit(state.copyWith(
          submitStatus: SubmitStatus.error,
          errorMessage: failure.message,
          usernameStatus: newUsernameStatus,
        ));
      },
      (session) => emit(state.copyWith(
        submitStatus: SubmitStatus.success,
        session: session,
        clearError: true,
      )),
    );
  }
}
