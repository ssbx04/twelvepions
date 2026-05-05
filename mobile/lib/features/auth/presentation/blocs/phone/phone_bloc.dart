import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/services/notification_service.dart';
import '../../../domain/usecases/send_otp.dart';

part 'phone_event.dart';
part 'phone_state.dart';

class PhoneBloc extends Bloc<PhoneEvent, PhoneState> {
  final SendOtp sendOtp;

  PhoneBloc({required this.sendOtp}) : super(const PhoneInitial()) {
    on<PhoneSubmitted>(_onSubmitted);
    on<PhoneReset>((event, emit) => emit(const PhoneInitial()));
  }

  Future<void> _onSubmitted(
    PhoneSubmitted event,
    Emitter<PhoneState> emit,
  ) async {
    emit(const PhoneLoading());
    final result = await sendOtp(event.phone);
    result.fold(
      (failure) => emit(PhoneError(failure.message)),
      (otp) {
        NotificationService().showOtpNotification(otp);
        emit(PhoneOtpSent(event.phone));
      },
    );
  }
}
