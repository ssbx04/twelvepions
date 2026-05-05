import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class CheckUsername {
  final AuthRepository repository;
  CheckUsername(this.repository);

  Future<Either<Failure, bool>> call(String username) =>
      repository.checkUsername(username);
}
