part of 'game_bloc.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

class GameStarted extends GameEvent {
  final String gameId;
  final String yourColor;
  final Map<String, dynamic>? initialStateData;

  const GameStarted({required this.gameId, required this.yourColor, this.initialStateData});

  @override
  List<Object?> get props => [gameId, yourColor, initialStateData];
}

class GameCellClicked extends GameEvent {
  final int row;
  final int col;

  const GameCellClicked(this.row, this.col);

  @override
  List<Object?> get props => [row, col];
}

class GameWsMessageReceived extends GameEvent {
  final Map<String, dynamic> message;

  const GameWsMessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class GamePieceMoved extends GameEvent {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;

  const GamePieceMoved({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
  });

  @override
  List<Object?> get props => [fromRow, fromCol, toRow, toCol];
}

class GameSurplaceRequested extends GameEvent {}

class GameSurplaceClicked extends GameEvent {
  final int row;
  final int col;
  const GameSurplaceClicked(this.row, this.col);
  @override
  List<Object?> get props => [row, col];
}

class GameSurplaceCancelled extends GameEvent {}

class GameDrawOffered extends GameEvent {}

class GameDrawAccepted extends GameEvent {}

class GameResigned extends GameEvent {}

class GameCoudouTimeout extends GameEvent {}
