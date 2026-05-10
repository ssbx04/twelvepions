part of 'local_game_bloc.dart';

abstract class LocalGameEvent extends Equatable {
  const LocalGameEvent();
  @override
  List<Object?> get props => [];
}

class LocalCellClicked extends LocalGameEvent {
  final int row;
  final int col;
  const LocalCellClicked(this.row, this.col);
  @override
  List<Object?> get props => [row, col];
}

class LocalSurplaceRequested extends LocalGameEvent {}

class LocalSurplaceClicked extends LocalGameEvent {
  final int row;
  final int col;
  const LocalSurplaceClicked(this.row, this.col);
  @override
  List<Object?> get props => [row, col];
}

class LocalSurplaceCancelled extends LocalGameEvent {}

class LocalNewGame extends LocalGameEvent {}

class LocalTurnTimeout extends LocalGameEvent {}

class LocalCoudouTimeout extends LocalGameEvent {}
