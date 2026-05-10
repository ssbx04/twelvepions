import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../auth/domain/entities/user.dart';
import '../../../../auth/domain/usecases/get_me.dart';
import '../../../../../core/services/websocket_service.dart';
import '../../../../../core/storage/auth_local_storage.dart';
import '../../../domain/entities/game_summary.dart';
import '../../../domain/usecases/get_recent_games.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetMe getMe;
  final GetRecentGames getRecentGames;
  final AuthLocalStorage authLocal;
  final WebSocketService wsService;

  HomeBloc({
    required this.getMe,
    required this.getRecentGames,
    required this.authLocal,
    required this.wsService,
  }) : super(const HomeLoading()) {
    on<HomeStarted>(_onStarted);
  }

  Future<void> _onStarted(
    HomeStarted event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());

    // Lancer les deux requêtes en parallèle
    final meF = getMe();
    final gamesF = getRecentGames(limit: 15);
    final meResult = await meF;
    final gamesResult = await gamesF;

    await meResult.fold(
      (failure) async => emit(HomeError(failure.message)),
      (user) async {
        final token = await authLocal.readJwt();
        if (token != null) wsService.connect(token);
        // Si getRecentGames échoue (réseau), on affiche quand même le lobby
        final games = gamesResult.fold<List<GameSummary>>((_) => [], (g) => g);
        if (!emit.isDone) emit(HomeLoaded(user, recentGames: games));
      },
    );
  }
}
