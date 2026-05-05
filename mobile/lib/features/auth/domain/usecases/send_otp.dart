import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class SendOtp {
  final AuthRepository repository;
  SendOtp(this.repository);

  Future<Either<Failure, String>> call(String phone) async {
    return repository.sendOtp(phone);
  }
}
