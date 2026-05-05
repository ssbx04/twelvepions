import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/auth_session.dart';
import '../../../domain/usecases/send_otp.dart';
import '../../../domain/usecases/verify_otp.dart';

part 'otp_event.dart';
part 'otp_state.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  final VerifyOtp verifyOtp;
  final SendOtp sendOtp;

  OtpBloc({required this.verifyOtp, required this.sendOtp})
      : super(const OtpInitial()) {
    on<OtpVerifySubmitted>(_onVerify);
    on<OtpResendSubmitted>(_onResend);
  }

  Future<void> _onVerify(
    OtpVerifySubmitted event,
    Emitter<OtpState> emit,
  ) async {
    emit(const OtpVerifying());
    final result = await verifyOtp(phone: event.phone, code: event.code);
    result.fold(
      (failure) => emit(OtpError(message: failure.message)),
      (session) => emit(OtpVerified(session)),
    );
  }

  Future<void> _onResend(
    OtpResendSubmitted event,
    Emitter<OtpState> emit,
  ) async {
    emit(const OtpResending());
    final result = await sendOtp(event.phone);
    result.fold(
      (failure) => emit(
        OtpError(message: failure.message, duringResend: true),
      ),
      (_) => emit(const OtpResent()),
    );
  }
}
