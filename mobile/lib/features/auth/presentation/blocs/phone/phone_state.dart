part of 'phone_bloc.dart';

sealed class PhoneState extends Equatable {
  const PhoneState();
  @override
  List<Object?> get props => [];
}

class PhoneInitial extends PhoneState {
  const PhoneInitial();
}

class PhoneLoading extends PhoneState {
  const PhoneLoading();
}

class PhoneOtpSent extends PhoneState {
  final String phone;
  const PhoneOtpSent(this.phone);

  @override
  List<Object?> get props => [phone];
}

class PhoneError extends PhoneState {
  final String message;
  const PhoneError(this.message);

  @override
  List<Object?> get props => [message];
}
