import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/game_rules.dart';

part 'local_game_event.dart';
part 'local_game_state.dart';

class LocalGameBloc extends Bloc<LocalGameEvent, LocalGameState> {
  static const int coudouDurationSeconds = 3;
  Timer? _coudouTimer;

  LocalGameBloc() : super(LocalGameActive(
    board: const ['XXXXX', 'XXXXX', 'XX.OO', 'OOOOO', 'OOOOO'],
    turn: 'X',
    status: 'IN_PROGRESS',
  )) {
    on<LocalCellClicked>(_onCellClicked);
    on<LocalSurplaceRequested>(_onSurplaceRequested);
    on<LocalSurplaceClicked>(_onSurplaceClicked);
    on<LocalSurplaceCancelled>(_onSurplaceCancelled);
    on<LocalNewGame>(_onNewGame);
    on<LocalCoudouTimeout>(_onCoudouTimeout);
  }

  int _newCoudouDeadline() => DateTime.now().millisecondsSinceEpoch + coudouDurationSeconds * 1000;

  void _armCoudouTimer() {
    _coudouTimer?.cancel();
    _coudouTimer = Timer(Duration(seconds: coudouDurationSeconds), () {
      add(LocalCoudouTimeout());
    });
  }



  /// Coudou timeout : le joueur n'a pas continué la chaîne dans les 3s → fin du tour
  void _onCoudouTimeout(LocalCoudouTimeout event, Emitter<LocalGameState> emit) {
    if (state is! LocalGameActive) return;
    final s = state as LocalGameActive;
    if (s.isFinished) return;
    if (s.localMustContinueFrom == null) return; // pas en mode coudou

    // Fin du tour normalement
    _finishTurn(s.board, s.turn, s, emit);
  }

  void _onNewGame(LocalNewGame event, Emitter<LocalGameState> emit) {
    _coudouTimer?.cancel();
    emit(LocalGameActive(
      board: const ['XXXXX', 'XXXXX', 'XX.OO', 'OOOOO', 'OOOOO'],
      turn: 'X',
      status: 'IN_PROGRESS',
    ));
  }

  void _onCellClicked(LocalCellClicked event, Emitter<LocalGameState> emit) {
    if (state is! LocalGameActive) return;
    final s = state as LocalGameActive;
    if (s.isFinished) return;

    final r = event.row;
    final c = event.col;
    final piece = s.board[r][c];

    // 1. En mode coudou (chaîne optionnelle)
    if (s.localMustContinueFrom != null) {
      // Clic sur le pion en coudou = ne rien faire
      if (r == s.localMustContinueFrom!['r'] && c == s.localMustContinueFrom!['c']) return;

      // Clic sur une destination valide = continuer la chaîne
      final validDest = s.validDestinations.where((d) => d['r'] == r && d['c'] == c).toList();
      if (validDest.isNotEmpty) {
        _coudouTimer?.cancel();
        // selectedCell est null (pas de sélection visuelle), on injecte la source
        final withSource = s.copyWith(selectedCell: s.localMustContinueFrom);
        _applyMove(validDest.first, withSource, emit);
        return;
      }

      // Clic ailleurs = le joueur refuse de continuer → fin du tour
      _coudouTimer?.cancel();
      _finishTurn(s.board, s.turn, s, emit);
      return;
    }

    // 2. Sélection d'un pion du joueur actif
    if (piece != '.' && GameRules.getColor(piece) == s.turn) {
      if (s.selectedCell != null && s.selectedCell!['r'] == r && s.selectedCell!['c'] == c) {
        emit(s.copyWith(clearSelection: true));
        return;
      }

      final captures = GameRules.captureMoves(s.board, r, c);
      final simples = GameRules.simpleMoves(s.board, r, c);
      final allMoves = [...captures, ...simples];
      if (allMoves.isNotEmpty) {
        emit(s.copyWith(
          selectedCell: {'r': r, 'c': c},
          validDestinations: allMoves,
        ));
      }
      return;
    }

    // 3. Clic sur une destination valide
    if (piece == '.' && s.selectedCell != null) {
      final validDest = s.validDestinations.where((d) => d['r'] == r && d['c'] == c).toList();
      if (validDest.isNotEmpty) {
        _applyMove(validDest.first, s, emit);
      } else {
        emit(s.copyWith(clearSelection: true));
      }
      return;
    }

    if (s.selectedCell != null) {
      emit(s.copyWith(clearSelection: true));
    }
  }

  void _applyMove(Map<String, dynamic> moveObj, LocalGameActive s, Emitter<LocalGameState> emit) {
    final fromR = s.selectedCell!['r']!;
    final fromC = s.selectedCell!['c']!;
    final toR = moveObj['r'] as int;
    final toC = moveObj['c'] as int;
    final captured = moveObj['captured'] as Map<String, int>?;

    var newBoard = GameRules.applyMove(s.board, fromR, fromC, toR, toC, captured);

    // Si capture → toujours attendre 3s (pour ne pas révéler s'il y a un coudou)
    if (captured != null) {
      final newChainCount = s.chainCaptureCount + 1;
      final nextCaptures = GameRules.captureMoves(newBoard, toR, toC);

      // Toujours armer le timer 3s, qu'il y ait une chaîne ou pas
      _armCoudouTimer();
      emit(s.copyWith(
        board: newBoard,
        localMustContinueFrom: {'r': toR, 'c': toC},
        clearSelection: true,
        validDestinations: nextCaptures, // vide si pas de chaîne
        turnDeadlineEpochMs: _newCoudouDeadline(),
        chainCaptureCount: newChainCount,
      ));
      return;
    }

    // Pas de capture → fin du tour directe
    _finishTurn(newBoard, s.turn, s, emit);
  }

  /// Termine le tour : vérifie surplace, promotion, fin de partie, et passe au joueur suivant
  void _finishTurn(List<String> board, String currentColor, LocalGameActive s, Emitter<LocalGameState> emit) {
    final opponentColor = currentColor == 'X' ? 'O' : 'X';

    // Vérifier surplace (le joueur avait une capture possible mais n'a pas capturé)
    List<Map<String, int>> faultyPositions = [];
    if (s.localMustContinueFrom == null) {
      // On vérifie seulement si ce n'est pas un coudou timeout (le joueur a déjà capturé)
      final hadCapture = GameRules.hasAnyCapture(s.board, currentColor);
      if (hadCapture) {
        for (int pr = 0; pr < 5; pr++) {
          for (int pc = 0; pc < 5; pc++) {
            final p = s.board[pr][pc];
            if (p != '.' && GameRules.getColor(p) == currentColor) {
              if (GameRules.captureMoves(s.board, pr, pc).isNotEmpty) {
                faultyPositions.add({'r': pr, 'c': pc});
              }
            }
          }
        }
      }
    }

    // Auto-promotion du dernier pion
    var newBoard = _autoPromoteLast(board, currentColor);

    // Vérifier fin de partie
    final opCount = _countPieces(newBoard, opponentColor);
    final myCount = _countPieces(newBoard, currentColor);
    String? winner;
    String? endReason;
    String status = 'IN_PROGRESS';

    if (opCount == 0) {
      status = 'FINISHED';
      winner = currentColor;
      endReason = 'CAPTURE_ALL';
    } else if (!_hasAnyMove(newBoard, opponentColor)) {
      status = 'FINISHED';
      winner = currentColor;
      endReason = 'BLOCKED';
    } else if (myCount == 1 && opCount == 1 && !GameRules.hasAnyCapture(newBoard, opponentColor) && faultyPositions.isEmpty) {
      status = 'FINISHED';
      endReason = 'DRAW';
    }

    if (status == 'FINISHED') {
      _coudouTimer?.cancel();
    }

    emit(LocalGameActive(
      board: newBoard,
      turn: opponentColor,
      status: status,
      winner: winner,
      endReason: endReason,
      oopsFaultyPositions: faultyPositions,
    ));
  }

  void _onSurplaceRequested(LocalSurplaceRequested event, Emitter<LocalGameState> emit) {
    if (state is! LocalGameActive) return;
    final s = state as LocalGameActive;
    emit(s.copyWith(surplaceMode: true, clearSelection: true));
  }

  void _onSurplaceClicked(LocalSurplaceClicked event, Emitter<LocalGameState> emit) async {
    if (state is! LocalGameActive) return;
    final s = state as LocalGameActive;
    if (!s.surplaceMode) return;

    final piece = s.board[event.row][event.col];
    final opponentColor = s.turn == 'X' ? 'O' : 'X';
    if (piece == '.' || GameRules.getColor(piece) != opponentColor) return;

    final isFaulty = s.oopsFaultyPositions.any(
      (p) => p['r'] == event.row && p['c'] == event.col,
    );

    if (!isFaulty) {
      emit(s.copyWith(surplaceMode: false));
      return;
    }

    // Trouver le coup que le pion aurait dû faire
    final missedCaptures = GameRules.captureMoves(s.board, event.row, event.col);
    if (missedCaptures.isNotEmpty) {
      final demoMove = missedCaptures.first;
      final demoR = demoMove['r'] as int;
      final demoC = demoMove['c'] as int;
      final capturedPos = demoMove['captured'] as Map<String, int>?;

      // Étape 1 : déplacer le pion vers la destination (le pion glisse)
      var demoBoard = s.board.map((row) => row.split('')).toList();
      final pieceChar = demoBoard[event.row][event.col];
      demoBoard[event.row][event.col] = '.';
      demoBoard[demoR][demoC] = pieceChar;
      // Retirer le pion capturé pour montrer le coup complet
      if (capturedPos != null) {
        demoBoard[capturedPos['r']!][capturedPos['c']!] = '.';
      }
      emit(s.copyWith(
        board: demoBoard.map((row) => row.join('')).toList(),
        surplaceMode: false,
      ));

      await Future.delayed(const Duration(milliseconds: 800));

      // Étape 2 : remettre le pion à sa place (le pion glisse en retour)
      emit(s.copyWith(
        board: s.board,
        surplaceMode: false,
      ));

      await Future.delayed(const Duration(milliseconds: 800));
    }

    // Retirer le pion fautif
    if (state is! LocalGameActive) return;
    final current = state as LocalGameActive;
    final newBoard = current.board.map((row) => row.split('')).toList();
    newBoard[event.row][event.col] = '.';
    final boardStrings = newBoard.map((row) => row.join('')).toList();

    final myCount = _countPieces(boardStrings, opponentColor);
    String? winner;
    String? endReason;
    String status = 'IN_PROGRESS';

    if (myCount == 0) {
      status = 'FINISHED';
      winner = current.turn;
      endReason = 'CAPTURE_ALL';
    }

    if (status == 'FINISHED') {
      _coudouTimer?.cancel();
    }

    emit(LocalGameActive(
      board: boardStrings,
      turn: current.turn,
      status: status,
      winner: winner,
      endReason: endReason,
    ));
  }

  void _onSurplaceCancelled(LocalSurplaceCancelled event, Emitter<LocalGameState> emit) {
    if (state is! LocalGameActive) return;
    final s = state as LocalGameActive;
    emit(s.copyWith(surplaceMode: false));
  }

  @override
  Future<void> close() {
    _coudouTimer?.cancel();
    return super.close();
  }

  // --- Helpers ---

  int _countPieces(List<String> board, String color) {
    int count = 0;
    for (var row in board) {
      for (var i = 0; i < row.length; i++) {
        if (row[i].toUpperCase() == color) count++;
      }
    }
    return count;
  }

  bool _hasAnyMove(List<String> board, String color) {
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        final p = board[r][c];
        if (p != '.' && GameRules.getColor(p) == color) {
          if (GameRules.simpleMoves(board, r, c).isNotEmpty || GameRules.captureMoves(board, r, c).isNotEmpty) {
            return true;
          }
        }
      }
    }
    return false;
  }

  List<String> _autoPromoteLast(List<String> board, String color) {
    int count = _countPieces(board, color);
    if (count != 1) return board;

    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        if (board[r][c].toUpperCase() == color && board[r][c] == board[r][c].toUpperCase()) {
          final newBoard = board.map((row) => row.split('')).toList();
          newBoard[r][c] = color.toLowerCase();
          return newBoard.map((row) => row.join('')).toList();
        }
      }
    }
    return board;
  }
}

