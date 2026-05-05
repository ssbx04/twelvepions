part of 'phone_bloc.dart';

sealed class PhoneEvent extends Equatable {
  const PhoneEvent();
  @override
  List<Object?> get props => [];
}

class PhoneSubmitted extends PhoneEvent {
  final String phone;
  const PhoneSubmitted(this.phone);

  @override
  List<Object?> get props => [phone];
}

class PhoneReset extends PhoneEvent {
  const PhoneReset();
}
