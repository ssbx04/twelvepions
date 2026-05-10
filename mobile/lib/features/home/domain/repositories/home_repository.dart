import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/game_summary.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<GameSummary>>> getRecentGames({int limit = 5});
}
