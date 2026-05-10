import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/services/websocket_service.dart';

part 'matchmaking_event.dart';
part 'matchmaking_state.dart';

class MatchmakingBloc extends Bloc<MatchmakingEvent, MatchmakingState> {
  final WebSocketService wsService;
  StreamSubscription? _wsSubscription;

  MatchmakingBloc({required this.wsService}) : super(MatchmakingInitial()) {
    on<MatchmakingJoinQueue>(_onJoinQueue);
    on<MatchmakingJoinAiQueue>(_onJoinAiQueue);
    on<MatchmakingLeaveQueue>(_onLeaveQueue);
    on<MatchmakingWsMessageReceived>(_onWsMessageReceived);

    _wsSubscription = wsService.messages.listen((message) {
      add(MatchmakingWsMessageReceived(message));
    });
  }

  void _onJoinQueue(MatchmakingJoinQueue event, Emitter<MatchmakingState> emit) {
    emit(MatchmakingSearching());
    wsService.sendMessage({'type': 'queue.join'});
  }

  void _onJoinAiQueue(MatchmakingJoinAiQueue event, Emitter<MatchmakingState> emit) {
    emit(MatchmakingSearching());
    wsService.sendMessage({'type': 'queue.join.ai'});
  }

  void _onLeaveQueue(MatchmakingLeaveQueue event, Emitter<MatchmakingState> emit) {
    wsService.sendMessage({'type': 'queue.leave'});
    emit(MatchmakingInitial());
  }

  void _onWsMessageReceived(MatchmakingWsMessageReceived event, Emitter<MatchmakingState> emit) {
    final type = event.message['type'] as String?;

    if (type == 'game.matched' && state is MatchmakingSearching) {
      final stateData = event.message['state'];
      final gameId = stateData['gameId'] as String;
      final yourColor = event.message['yourColor'] as String;

      emit(MatchmakingMatched(gameId: gameId, yourColor: yourColor, stateData: stateData));
    } else if (type == 'error') {
      emit(MatchmakingError(event.message['message'] as String? ?? 'Erreur inconnue'));
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
