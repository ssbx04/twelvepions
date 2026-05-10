part of 'matchmaking_bloc.dart';

abstract class MatchmakingState extends Equatable {
  const MatchmakingState();
  
  @override
  List<Object?> get props => [];
}

class MatchmakingInitial extends MatchmakingState {}

class MatchmakingSearching extends MatchmakingState {}

class MatchmakingMatched extends MatchmakingState {
  final String gameId;
  final String yourColor;
  final Map<String, dynamic> stateData;

  const MatchmakingMatched({required this.gameId, required this.yourColor, required this.stateData});

  @override
  List<Object?> get props => [gameId, yourColor, stateData];
}

class MatchmakingError extends MatchmakingState {
  final String message;

  const MatchmakingError(this.message);

  @override
  List<Object?> get props => [message];
}
