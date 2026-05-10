import '../../domain/entities/game_summary.dart';

class GameSummaryModel extends GameSummary {
  const GameSummaryModel({
    required super.gameId,
    required super.opponentUsername,
    required super.opponentElo,
    required super.result,
    required super.eloChange,
    required super.endReason,
    super.finishedAt,
  });

  factory GameSummaryModel.fromJson(Map<String, dynamic> json) {
    final finishedAtStr = json['finishedAt'] as String?;
    return GameSummaryModel(
      gameId: json['gameId'] as String,
      opponentUsername: json['opponentUsername'] as String,
      opponentElo: json['opponentElo'] as int,
      result: json['result'] as String,
      eloChange: json['eloChange'] as int,
      endReason: json['endReason'] as String,
      finishedAt: (finishedAtStr != null && finishedAtStr.isNotEmpty)
          ? DateTime.tryParse(finishedAtStr)
          : null,
    );
  }
}
