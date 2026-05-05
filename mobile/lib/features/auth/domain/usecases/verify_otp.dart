import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class VerifyOtp {
  final AuthRepository repository;
  VerifyOtp(this.repository);

  Future<Either<Failure, AuthSession>> call({
    required String phone,
    required String code,
  }) =>
      repository.verifyOtp(phone, code);
}
