import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../auth/domain/entities/user.dart';
import '../../../../auth/domain/usecases/get_me.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetMe getMe;

  HomeBloc({required this.getMe}) : super(const HomeLoading()) {
    on<HomeStarted>(_onStarted);
  }

  Future<void> _onStarted(
    HomeStarted event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    final result = await getMe();
    result.fold(
      (failure) => emit(HomeError(failure.message)),
      (user) => emit(HomeLoaded(user)),
    );
  }
}
