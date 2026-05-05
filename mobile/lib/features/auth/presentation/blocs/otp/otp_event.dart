part of 'otp_bloc.dart';

sealed class OtpEvent extends Equatable {
  const OtpEvent();
  @override
  List<Object?> get props => [];
}

class OtpVerifySubmitted extends OtpEvent {
  final String phone;
  final String code;
  const OtpVerifySubmitted({required this.phone, required this.code});

  @override
  List<Object?> get props => [phone, code];
}

class OtpResendSubmitted extends OtpEvent {
  final String phone;
  const OtpResendSubmitted(this.phone);

  @override
  List<Object?> get props => [phone];
}
