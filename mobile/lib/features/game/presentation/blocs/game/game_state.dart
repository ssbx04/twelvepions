part of 'game_bloc.dart';

abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {}

class GameLoading extends GameState {}

class GameActive extends GameState {
  final String gameId;
  final String yourColor;
  final List<String> board;
  final String turn;
  final String? mustContinueFrom;
  final int ply;
  final String status;
  final String? winner;
  final String? endReason;
  
  final Map<String, dynamic> playerX;
  final Map<String, dynamic> playerO;

  final int? turnDeadlineEpochMs;

  // --- UI State Local ---
  final Map<String, int>? selectedCell;
  final List<Map<String, dynamic>> validDestinations; // Contient 'r', 'c', et optionnellement 'captured'
  final List<Map<String, dynamic>> pendingSequence; // Mouvements accumulés (pour Coudou)
  final Map<String, int>? localMustContinueFrom; // Réfère à la case où la pièce est en pleine séquence de Coudou
  final int? coudouDeadlineEpochMs; // Deadline locale du timer 3s après capture

  // --- Surplace (OOPS) ---
  final List<Map<String, int>> oopsFaultyPositions; // Positions des pions adverses fautifs
  final Map<String, int>? oopsMovedFrom; // Position originale du pion fautif avant son coup simple
  final bool surplaceMode; // true quand le joueur est en mode surplace (clic sur pion fautif)
  final bool oopsJustHappened; // true quand un surplace vient d'être appliqué (pour le banner)

  // --- Déconnexion Adversaire ---
  final bool isOpponentDisconnected;
  final int? forfeitDeadlineEpochMs;

  const GameActive({
    required this.gameId,
    required this.yourColor,
    required this.board,
    required this.turn,
    required this.mustContinueFrom,
    required this.ply,
    required this.status,
    required this.winner,
    required this.endReason,
    required this.playerX,
    required this.playerO,
    this.turnDeadlineEpochMs,
    this.selectedCell,
    this.validDestinations = const [],
    this.pendingSequence = const [],
    this.localMustContinueFrom,
    this.coudouDeadlineEpochMs,
    this.oopsFaultyPositions = const [],
    this.oopsMovedFrom,
    this.surplaceMode = false,
    this.oopsJustHappened = false,
    this.isOpponentDisconnected = false,
    this.forfeitDeadlineEpochMs,
  });

  bool get isMyTurn => turn == yourColor;

  bool get isFinished => status == 'FINISHED';

  @override
  List<Object?> get props => [
        gameId,
        yourColor,
        board,
        turn,
        mustContinueFrom,
        ply,
        status,
        winner,
        endReason,
        playerX,
        playerO,
        turnDeadlineEpochMs,
        selectedCell,
        validDestinations,
        pendingSequence,
        localMustContinueFrom,
        coudouDeadlineEpochMs,
        oopsFaultyPositions,
        oopsMovedFrom,
        surplaceMode,
        oopsJustHappened,
        isOpponentDisconnected,
        forfeitDeadlineEpochMs,
      ];

  GameActive copyWith({
    String? gameId,
    String? yourColor,
    List<String>? board,
    String? turn,
    String? mustContinueFrom,
    int? ply,
    String? status,
    String? winner,
    String? endReason,
    Map<String, dynamic>? playerX,
    Map<String, dynamic>? playerO,
    int? turnDeadlineEpochMs,
    Map<String, int>? selectedCell,
    List<Map<String, dynamic>>? validDestinations,
    List<Map<String, dynamic>>? pendingSequence,
    Map<String, int>? localMustContinueFrom,
    int? coudouDeadlineEpochMs,
    List<Map<String, int>>? oopsFaultyPositions,
    Map<String, int>? oopsMovedFrom,
    bool? surplaceMode,
    bool? oopsJustHappened,
    bool? isOpponentDisconnected,
    int? forfeitDeadlineEpochMs,
    bool clearSelection = false,
    bool clearCoudouDeadline = false,
    bool clearForfeitDeadline = false,
  }) {
    return GameActive(
      gameId: gameId ?? this.gameId,
      yourColor: yourColor ?? this.yourColor,
      board: board ?? this.board,
      turn: turn ?? this.turn,
      mustContinueFrom: mustContinueFrom ?? this.mustContinueFrom,
      ply: ply ?? this.ply,
      status: status ?? this.status,
      winner: winner ?? this.winner,
      endReason: endReason ?? this.endReason,
      playerX: playerX ?? this.playerX,
      playerO: playerO ?? this.playerO,
      turnDeadlineEpochMs: turnDeadlineEpochMs ?? this.turnDeadlineEpochMs,
      selectedCell: clearSelection ? null : (selectedCell ?? this.selectedCell),
      validDestinations: validDestinations ?? (clearSelection ? [] : this.validDestinations),
      pendingSequence: pendingSequence ?? this.pendingSequence,
      localMustContinueFrom: localMustContinueFrom ?? this.localMustContinueFrom,
      coudouDeadlineEpochMs: clearCoudouDeadline ? null : (coudouDeadlineEpochMs ?? this.coudouDeadlineEpochMs),
      oopsFaultyPositions: oopsFaultyPositions ?? this.oopsFaultyPositions,
      oopsMovedFrom: oopsMovedFrom ?? this.oopsMovedFrom,
      surplaceMode: surplaceMode ?? this.surplaceMode,
      oopsJustHappened: oopsJustHappened ?? false,
      isOpponentDisconnected: isOpponentDisconnected ?? this.isOpponentDisconnected,
      forfeitDeadlineEpochMs: clearForfeitDeadline ? null : (forfeitDeadlineEpochMs ?? this.forfeitDeadlineEpochMs),
    );
  }
}

class GameError extends GameState {
  final String message;

  const GameError(this.message);

  @override
  List<Object?> get props => [message];
}
