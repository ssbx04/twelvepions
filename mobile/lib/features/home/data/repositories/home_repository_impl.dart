import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/auth_local_storage.dart';
import '../../domain/entities/game_summary.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remote;
  final AuthLocalStorage local;

  HomeRepositoryImpl({required this.remote, required this.local});

  @override
  Future<Either<Failure, List<GameSummary>>> getRecentGames({int limit = 5}) async {
    final token = await local.readJwt();
    if (token == null) return const Left(UnauthorizedFailure());
    try {
      final models = await remote.getRecentGames(token, limit: limit);
      return Right(models);
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
