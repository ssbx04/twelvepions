part of 'complete_profile_bloc.dart';

enum UsernameStatus { idle, checking, available, taken, error }

enum SubmitStatus { idle, loading, success, error }

class CompleteProfileState extends Equatable {
  final UsernameStatus usernameStatus;
  final String? lastCheckedUsername;
  final SubmitStatus submitStatus;
  final String? errorMessage;
  final AuthSession? session;

  const CompleteProfileState({
    this.usernameStatus = UsernameStatus.idle,
    this.lastCheckedUsername,
    this.submitStatus = SubmitStatus.idle,
    this.errorMessage,
    this.session,
  });

  CompleteProfileState copyWith({
    UsernameStatus? usernameStatus,
    String? lastCheckedUsername,
    SubmitStatus? submitStatus,
    String? errorMessage,
    AuthSession? session,
    bool clearError = false,
  }) {
    return CompleteProfileState(
      usernameStatus: usernameStatus ?? this.usernameStatus,
      lastCheckedUsername: lastCheckedUsername ?? this.lastCheckedUsername,
      submitStatus: submitStatus ?? this.submitStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      session: session ?? this.session,
    );
  }

  @override
  List<Object?> get props => [
        usernameStatus,
        lastCheckedUsername,
        submitStatus,
        errorMessage,
        session,
      ];
}
