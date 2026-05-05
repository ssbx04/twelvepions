import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_session.dart';
import '../entities/user_level.dart';
import '../repositories/auth_repository.dart';

class CompleteProfile {
  final AuthRepository repository;
  CompleteProfile(this.repository);

  Future<Either<Failure, AuthSession>> call({
    required String fullName,
    required String username,
    required UserLevel level,
  }) =>
      repository.completeProfile(
        fullName: fullName,
        username: username,
        level: level,
      );
}
