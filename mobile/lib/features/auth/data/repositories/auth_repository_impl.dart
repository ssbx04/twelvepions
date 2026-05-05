import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/auth_local_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/user_level.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final AuthLocalStorage local;

  AuthRepositoryImpl({required this.remote, required this.local});

  @override
  Future<Either<Failure, String>> sendOtp(String phone) async {
    try {
      final otp = await remote.sendOtp(phone);
      return Right(otp);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(_mapServer(e));
    }
  }

  @override
  Future<Either<Failure, AuthSession>> verifyOtp(
    String phone,
    String code,
  ) async {
    try {
      final session = await remote.verifyOtp(phone, code);
      // Persiste le JWT immédiatement.
      await local.writeJwt(session.token);
      await local.writeUserId(session.user.id);
      await local.writeProfileComplete(session.profileComplete);
      return Right(session);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(_mapServer(e));
    }
  }

  @override
  Future<Either<Failure, AuthSession>> completeProfile({
    required String fullName,
    required String username,
    required UserLevel level,
  }) async {
    final token = await local.readJwt();
    if (token == null) return const Left(UnauthorizedFailure());
    try {
      final session = await remote.completeProfile(
        token: token,
        fullName: fullName,
        username: username,
        level: level,
      );
      await local.writeJwt(session.token);
      await local.writeProfileComplete(session.profileComplete);
      return Right(session);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(_mapServer(e));
    }
  }

  @override
  Future<Either<Failure, bool>> checkUsername(String username) async {
    try {
      final available = await remote.checkUsername(username);
      return Right(available);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(_mapServer(e));
    }
  }

  @override
  Future<Either<Failure, User>> getMe() async {
    final token = await local.readJwt();
    if (token == null) return const Left(UnauthorizedFailure());
    try {
      final user = await remote.getMe(token);
      return Right(user);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(_mapServer(e));
    }
  }

  @override
  Future<void> logout() => local.clear();

  @override
  Future<bool> hasSession() async => (await local.readJwt()) != null;

  /// Mapping des codes d'erreur backend vers les Failure métier.
  Failure _mapServer(ServerException e) {
    return switch (e.code) {
      'otp_cooldown' => OtpCooldownFailure(e.message),
      'otp_rate_limit' => OtpRateLimitFailure(e.message),
      'otp_expired' => OtpExpiredFailure(e.message),
      'otp_invalid' => OtpInvalidFailure(e.message),
      'otp_attempts_exceeded' => OtpAttemptsExceededFailure(e.message),
      'username_taken' => UsernameTakenFailure(e.message),
      'profile_already_complete' => ProfileAlreadyCompleteFailure(e.message),
      'user_not_found' => UserNotFoundFailure(e.message),
      'validation_error' => ValidationFailure(e.message),
      _ => e.statusCode != null && e.statusCode! >= 500
          ? ServerFailure(e.message)
          : ServerFailure(e.message),
    };
  }
}
