import 'package:equatable/equatable.dart';

class GameSummary extends Equatable {
  final String gameId;
  final String opponentUsername;
  final int opponentElo;
  final String result; // 'WIN', 'LOSS', 'DRAW'
  final int eloChange;
  final String endReason;
  final DateTime? finishedAt;

  const GameSummary({
    required this.gameId,
    required this.opponentUsername,
    required this.opponentElo,
    required this.result,
    required this.eloChange,
    required this.endReason,
    this.finishedAt,
  });

  @override
  List<Object?> get props => [gameId];
}
