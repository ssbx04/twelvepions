import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class GetMe {
  final AuthRepository repository;
  GetMe(this.repository);

  Future<Either<Failure, User>> call() async {
    return repository.getMe();
  }
}
