import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/game_summary.dart';
import '../repositories/home_repository.dart';

class GetRecentGames {
  final HomeRepository repository;

  GetRecentGames(this.repository);

  Future<Either<Failure, List<GameSummary>>> call({int limit = 5}) =>
      repository.getRecentGames(limit: limit);
}
