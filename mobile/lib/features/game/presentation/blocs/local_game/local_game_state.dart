part of 'local_game_bloc.dart';

abstract class LocalGameState extends Equatable {
  const LocalGameState();
  @override
  List<Object?> get props => [];
}

class LocalGameActive extends LocalGameState {
  final List<String> board;
  final String turn;
  final String status;
  final String? winner;
  final String? endReason;

  // Timer
  final int? turnDeadlineEpochMs;

  // UI State
  final Map<String, int>? selectedCell;
  final List<Map<String, dynamic>> validDestinations;
  final Map<String, int>? localMustContinueFrom;
  final int chainCaptureCount; // Nombre de captures dans la chaîne en cours

  // Surplace
  final List<Map<String, int>> oopsFaultyPositions;
  final bool surplaceMode;
  /// Démonstration du coup manqué (from → to)
  final Map<String, int>? surplaceDemoFrom;
  final Map<String, int>? surplaceDemoTo;

  const LocalGameActive({
    required this.board,
    required this.turn,
    required this.status,
    this.winner,
    this.endReason,
    this.turnDeadlineEpochMs,
    this.selectedCell,
    this.validDestinations = const [],
    this.localMustContinueFrom,
    this.chainCaptureCount = 0,
    this.oopsFaultyPositions = const [],
    this.surplaceMode = false,
    this.surplaceDemoFrom,
    this.surplaceDemoTo,
  });

  bool get isFinished => status == 'FINISHED';

  @override
  List<Object?> get props => [
        board, turn, status, winner, endReason, turnDeadlineEpochMs,
        selectedCell, validDestinations, localMustContinueFrom,
        chainCaptureCount, oopsFaultyPositions, surplaceMode,
        surplaceDemoFrom, surplaceDemoTo,
      ];

  LocalGameActive copyWith({
    List<String>? board,
    String? turn,
    String? status,
    String? winner,
    String? endReason,
    int? turnDeadlineEpochMs,
    Map<String, int>? selectedCell,
    List<Map<String, dynamic>>? validDestinations,
    Map<String, int>? localMustContinueFrom,
    int? chainCaptureCount,
    List<Map<String, int>>? oopsFaultyPositions,
    bool? surplaceMode,
    Map<String, int>? surplaceDemoFrom,
    Map<String, int>? surplaceDemoTo,
    bool clearSelection = false,
    bool clearDeadline = false,
    bool clearDemo = false,
  }) {
    return LocalGameActive(
      board: board ?? this.board,
      turn: turn ?? this.turn,
      status: status ?? this.status,
      winner: winner ?? this.winner,
      endReason: endReason ?? this.endReason,
      turnDeadlineEpochMs: clearDeadline ? null : (turnDeadlineEpochMs ?? this.turnDeadlineEpochMs),
      selectedCell: clearSelection ? null : (selectedCell ?? this.selectedCell),
      validDestinations: validDestinations ?? (clearSelection ? [] : this.validDestinations),
      localMustContinueFrom: localMustContinueFrom ?? this.localMustContinueFrom,
      chainCaptureCount: chainCaptureCount ?? this.chainCaptureCount,
      oopsFaultyPositions: oopsFaultyPositions ?? this.oopsFaultyPositions,
      surplaceMode: surplaceMode ?? this.surplaceMode,
      surplaceDemoFrom: clearDemo ? null : (surplaceDemoFrom ?? this.surplaceDemoFrom),
      surplaceDemoTo: clearDemo ? null : (surplaceDemoTo ?? this.surplaceDemoTo),
    );
  }
}
