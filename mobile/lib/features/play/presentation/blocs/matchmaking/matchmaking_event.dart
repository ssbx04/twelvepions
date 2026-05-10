part of 'matchmaking_bloc.dart';

abstract class MatchmakingEvent extends Equatable {
  const MatchmakingEvent();

  @override
  List<Object?> get props => [];
}

class MatchmakingJoinQueue extends MatchmakingEvent {}

class MatchmakingJoinAiQueue extends MatchmakingEvent {}

class MatchmakingLeaveQueue extends MatchmakingEvent {}

class MatchmakingWsMessageReceived extends MatchmakingEvent {
  final Map<String, dynamic> message;

  const MatchmakingWsMessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}
