part of 'otp_bloc.dart';

sealed class OtpState extends Equatable {
  const OtpState();
  @override
  List<Object?> get props => [];
}

class OtpInitial extends OtpState {
  const OtpInitial();
}

class OtpVerifying extends OtpState {
  const OtpVerifying();
}

class OtpResending extends OtpState {
  const OtpResending();
}

class OtpVerified extends OtpState {
  final AuthSession session;
  const OtpVerified(this.session);

  @override
  List<Object?> get props => [session];
}

class OtpResent extends OtpState {
  const OtpResent();
}

class OtpError extends OtpState {
  /// True si l'erreur s'est produite pendant un resend (sinon : verify).
  final bool duringResend;
  final String message;
  const OtpError({required this.message, this.duringResend = false});

  @override
  List<Object?> get props => [duringResend, message];
}
