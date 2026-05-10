import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../core/services/websocket_service.dart';
import '../../../domain/game_rules.dart';

part 'game_event.dart';
part 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final WebSocketService wsService;
  StreamSubscription? _wsSubscription;
  Timer? _replayTimer;
  Timer? _coudouTimer;
  static const int coudouDurationSeconds = 3;

  GameBloc({required this.wsService}) : super(GameInitial()) {
    on<GameStarted>(_onGameStarted);
    on<GameCellClicked>(_onCellClicked);
    on<GameWsMessageReceived>(_onWsMessageReceived);
    on<GamePieceMoved>(_onPieceMoved);
    on<GameSurplaceRequested>(_onSurplaceRequested);
    on<GameSurplaceClicked>(_onSurplaceClicked);
    on<GameSurplaceCancelled>(_onSurplaceCancelled);
    on<GameDrawOffered>(_onDrawOffered);
    on<GameDrawAccepted>(_onDrawAccepted);
    on<GameResigned>(_onResigned);
    on<GameCoudouTimeout>(_onCoudouTimeout);

    _wsSubscription = wsService.messages.listen((message) {
      add(GameWsMessageReceived(message));
    });
  }

  void _onGameStarted(GameStarted event, Emitter<GameState> emit) {
    if (event.initialStateData != null) {
      final stateData = event.initialStateData!;
      final boardList = (stateData['board'] as List).map((e) => e as String).toList();
      emit(GameActive(
        gameId: event.gameId,
        yourColor: event.yourColor,
        board: boardList,
        turn: stateData['turn'] as String,
        mustContinueFrom: stateData['mustContinueFrom'] as String?,
        ply: stateData['ply'] as int? ?? 0,
        status: stateData['status'] as String,
        winner: stateData['winner'] as String?,
        endReason: stateData['endReason'] as String?,
        playerX: stateData['playerX'] as Map<String, dynamic>,
        playerO: stateData['playerO'] as Map<String, dynamic>,
      ));
    } else {
      emit(GameLoading());
    }
  }

  Future<void> _onWsMessageReceived(GameWsMessageReceived event, Emitter<GameState> emit) async {
    final type = event.message['type'] as String?;

    if (type == 'game.matched' || type == 'game.resume' || type == 'game.update' || type == 'game.ended') {
      final stateData = event.message['state'];
      if (stateData == null) return;
      
      final boardList = (stateData['board'] as List).map((e) => e as String).toList();
      final gameId = stateData['gameId'] as String;
      
      String yourColor = 'X'; // Par défaut
      if (state is GameActive) {
        yourColor = (state as GameActive).yourColor;
      } else if (event.message['yourColor'] != null) {
        yourColor = event.message['yourColor'] as String;
      }
      
      // Parse les positions fautives (oops/surplace) si présentes
      List<Map<String, int>> faultyPositions = const [];
      if (event.message['oops'] != null) {
        final oops = event.message['oops'] as Map<String, dynamic>;
        final claimableBy = oops['claimableBy'] as String;
        // Seul le joueur concerné voit les positions fautives
        if (claimableBy == yourColor) {
          faultyPositions = (oops['faultyPositions'] as List)
              .map((p) => {'r': (p['r'] as num).toInt(), 'c': (p['c'] as num).toInt()})
              .toList();
        }
      }

      // Extraire lastMove ici pour le réutiliser dans la démo OOPS
      final lastMove = event.message['lastMove'] as List?;

      // Position originale du pion fautif : stockée si oops + lastMove présents
      Map<String, int>? oopsMovedFrom;
      if (event.message['oops'] != null && lastMove != null && lastMove.isNotEmpty) {
        final first = lastMove.first as Map<String, dynamic>;
        final from = first['from'] as Map<String, dynamic>?;
        if (from != null) {
          oopsMovedFrom = {'r': (from['r'] as num).toInt(), 'c': (from['c'] as num).toInt()};
        }
      }

      // --- Gestion du surplace (OOPS) reçu du serveur ---
      final oopsRemoved = event.message['oopsRemoved'] as Map<String, dynamic>?;
      if (oopsRemoved != null && state is GameActive) {
        final currentState = state as GameActive;
        final removedR = (oopsRemoved['r'] as num).toInt();
        final removedC = (oopsRemoved['c'] as num).toInt();

        // Position originale du pion fautif (peut avoir bougé via coup simple)
        final originalR = currentState.oopsMovedFrom?['r'] ?? removedR;
        final originalC = currentState.oopsMovedFrom?['c'] ?? removedC;

        // Reconstruire le board avant le coup fautif si le pion a bougé
        List<String> boardForDemo = currentState.board;
        if (originalR != removedR || originalC != removedC) {
          final mutable = currentState.board.map((row) => row.split('')).toList();
          final piece = mutable[removedR][removedC];
          mutable[removedR][removedC] = '.';
          mutable[originalR][originalC] = piece;
          boardForDemo = mutable.map((row) => row.join('')).toList();
        }

        final missedCaptures = GameRules.captureMoves(boardForDemo, originalR, originalC);
        if (missedCaptures.isNotEmpty) {
          final demoMove = missedCaptures.first;
          final demoR = demoMove['r'] as int;
          final demoC = demoMove['c'] as int;
          final capturedPos = demoMove['captured'] as Map<String, int>?;

          // Étape 1 : glisser le pion vers la destination de capture manquée
          var demoBoard = boardForDemo.map((row) => row.split('')).toList();
          final pieceChar = demoBoard[originalR][originalC];
          demoBoard[originalR][originalC] = '.';
          demoBoard[demoR][demoC] = pieceChar;
          if (capturedPos != null) {
            demoBoard[capturedPos['r']!][capturedPos['c']!] = '.';
          }
          emit(currentState.copyWith(
            board: demoBoard.map((row) => row.join('')).toList(),
            surplaceMode: false,
          ));
          await Future.delayed(const Duration(milliseconds: 800));

          // Étape 2 : remettre le board dans l'état après coup fautif (pion encore là)
          emit(currentState.copyWith(
            board: currentState.board,
            surplaceMode: false,
          ));
          await Future.delayed(const Duration(milliseconds: 600));
        }

        // Étape 3 : board final (pion retiré) + flag oops
        emit(GameActive(
          gameId: gameId,
          yourColor: yourColor,
          board: boardList,
          turn: stateData['turn'] as String,
          mustContinueFrom: stateData['mustContinueFrom'] as String?,
          ply: stateData['ply'] as int? ?? 0,
          status: stateData['status'] as String,
          winner: stateData['winner'] as String?,
          endReason: stateData['endReason'] as String?,
          playerX: stateData['playerX'] as Map<String, dynamic>,
          playerO: stateData['playerO'] as Map<String, dynamic>,
          turnDeadlineEpochMs: event.message['turnDeadlineEpochMs'] as int?,
          oopsFaultyPositions: faultyPositions,
          surplaceMode: false,
          oopsJustHappened: true,
        ));
        return;
      }

      // Coudou animation : si l'adversaire/IA a joué une séquence multi-capture,
      // on rejoue chaque étape avec un délai pour que le pion "tue un à un".
      final isOpponentMove = state is GameActive && (state as GameActive).yourColor != stateData['turn'];
      
      if (lastMove != null && lastMove.length > 1 && state is GameActive && !isOpponentMove) {
        // L'adversaire vient de jouer un coudou, on anime étape par étape
        _replayTimer?.cancel();
        final currentBoard = (state as GameActive).board;
        
        await _replaySequence(lastMove, currentBoard, emit, () => GameActive(
          gameId: gameId,
          yourColor: yourColor,
          board: boardList,
          turn: stateData['turn'] as String,
          mustContinueFrom: stateData['mustContinueFrom'] as String?,
          ply: stateData['ply'] as int? ?? 0,
          status: stateData['status'] as String,
          winner: stateData['winner'] as String?,
          endReason: stateData['endReason'] as String?,
          playerX: stateData['playerX'] as Map<String, dynamic>,
          playerO: stateData['playerO'] as Map<String, dynamic>,
          turnDeadlineEpochMs: event.message['turnDeadlineEpochMs'] as int?,
          oopsFaultyPositions: faultyPositions,
          oopsMovedFrom: oopsMovedFrom,
          surplaceMode: false,
        ));
        return;
      }

      emit(GameActive(
        gameId: gameId,
        yourColor: yourColor,
        board: boardList,
        turn: stateData['turn'] as String,
        mustContinueFrom: stateData['mustContinueFrom'] as String?,
        ply: stateData['ply'] as int? ?? 0,
        status: stateData['status'] as String,
        winner: stateData['winner'] as String?,
        endReason: stateData['endReason'] as String?,
        playerX: stateData['playerX'] as Map<String, dynamic>,
        playerO: stateData['playerO'] as Map<String, dynamic>,
        turnDeadlineEpochMs: event.message['turnDeadlineEpochMs'] as int?,
        oopsFaultyPositions: faultyPositions,
        oopsMovedFrom: oopsMovedFrom,
        surplaceMode: false,
      ));
    } else if (type == 'opponent.disconnected') {
      if (state is GameActive) {
        emit((state as GameActive).copyWith(
          isOpponentDisconnected: true,
          forfeitDeadlineEpochMs: event.message['forfeitDeadlineEpochMs'] as int?,
        ));
      }
    } else if (type == 'opponent.reconnected') {
      if (state is GameActive) {
        emit((state as GameActive).copyWith(
          isOpponentDisconnected: false,
          clearForfeitDeadline: true,
        ));
      }
    } else if (type == 'error') {
      const silentErrors = {'invalid_target', 'no_oops_pending', 'not_your_oops', 'illegal_move'};
      final code = event.message['code'] as String? ?? '';
      if (!silentErrors.contains(code)) {
        emit(GameError(event.message['message'] as String? ?? 'Erreur inconnue'));
      }
    }
  }

  void _onCellClicked(GameCellClicked event, Emitter<GameState> emit) {
    if (state is! GameActive) return;
    final currentState = state as GameActive;

    // Seul le joueur actif peut interagir
    if (!currentState.isMyTurn || currentState.isFinished) return;

    final r = event.row;
    final c = event.col;
    final piece = currentState.board[r][c];

    // 1. Si on est en mode coudou (chaîne optionnelle)
    if (currentState.localMustContinueFrom != null) {
      if (r == currentState.localMustContinueFrom!['r'] && c == currentState.localMustContinueFrom!['c']) {
        return; // Clic sur la pièce elle-même
      }
      
      // Clic sur une destination valide = continuer la chaîne
      final validDest = currentState.validDestinations.where((d) => d['r'] == r && d['c'] == c).toList();
      if (validDest.isNotEmpty) {
        _coudouTimer?.cancel();
        // selectedCell est null (pas de sélection visuelle), on injecte la source
        final withSource = currentState.copyWith(selectedCell: currentState.localMustContinueFrom);
        _applyLocalMove(validDest.first, withSource, emit);
        return;
      }

      // Clic ailleurs = le joueur refuse de continuer → envoyer la séquence
      _coudouTimer?.cancel();
      _sendPendingSequence(currentState, emit);
      return;
    }

    // 2. Sélection d'une pièce à moi
    if (piece != '.' && GameRules.getColor(piece) == currentState.yourColor) {
      // Si une pièce était déjà sélectionnée et on clique sur la même -> désélection
      if (currentState.selectedCell != null && currentState.selectedCell!['r'] == r && currentState.selectedCell!['c'] == c) {
        emit(currentState.copyWith(clearSelection: true));
        return;
      }

      // On affiche TOUS les coups possibles (captures + simples).
      // La capture n'est PAS obligatoire dans le 12 Pions sénégalais.
      // Si le joueur ne capture pas, l'adversaire peut le punir via Surplace (OOPS).
      final captures = GameRules.captureMoves(currentState.board, r, c);
      final simples = GameRules.simpleMoves(currentState.board, r, c);
      final allMoves = [...captures, ...simples];
      if (allMoves.isNotEmpty) {
        emit(currentState.copyWith(
          selectedCell: {'r': r, 'c': c},
          validDestinations: allMoves,
        ));
      }
      return;
    }

    // 3. Clic sur une case vide pour déplacer la pièce sélectionnée
    if (piece == '.' && currentState.selectedCell != null) {
      final validDest = currentState.validDestinations.where((d) => d['r'] == r && d['c'] == c).toList();
      if (validDest.isNotEmpty) {
        _applyLocalMove(validDest.first, currentState, emit);
      } else {
        // Clic sur du vide (non valide) -> désélection
        emit(currentState.copyWith(clearSelection: true));
      }
      return;
    }

    // Clic n'importe où ailleurs -> désélection
    if (currentState.selectedCell != null) {
      emit(currentState.copyWith(clearSelection: true));
    }
  }

  void _applyLocalMove(Map<String, dynamic> moveObj, GameActive currentState, Emitter<GameState> emit) {
    final fromR = currentState.selectedCell!['r']!;
    final fromC = currentState.selectedCell!['c']!;
    final toR = moveObj['r'] as int;
    final toC = moveObj['c'] as int;
    final captured = moveObj['captured'] as Map<String, int>?;

    final newSequence = List<Map<String, dynamic>>.from(currentState.pendingSequence);
    newSequence.add({
      'from': {'r': fromR, 'c': fromC},
      'to': {'r': toR, 'c': toC},
      if (captured != null) 'captured': captured,
    });

    final newBoard = GameRules.applyMove(currentState.board, fromR, fromC, toR, toC, captured);

    // Si capture → toujours attendre 3s (pour ne pas révéler s'il y a un coudou)
    if (captured != null) {
      final nextCaptures = GameRules.captureMoves(newBoard, toR, toC);

      // Toujours armer le timer 3s, qu'il y ait une chaîne ou pas
      _coudouTimer?.cancel();
      _coudouTimer = Timer(Duration(seconds: coudouDurationSeconds), () {
        add(GameCoudouTimeout());
      });
      emit(currentState.copyWith(
        board: newBoard,
        pendingSequence: newSequence,
        localMustContinueFrom: {'r': toR, 'c': toC},
        clearSelection: true,
        validDestinations: nextCaptures,
        coudouDeadlineEpochMs: DateTime.now().millisecondsSinceEpoch + (coudouDurationSeconds * 1000),
      ));
      return;
    }

    // Fin du tour → envoyer au backend
    _sendSequenceToServer(currentState.gameId, newSequence, newBoard, currentState, emit);
  }

  void _onCoudouTimeout(GameCoudouTimeout event, Emitter<GameState> emit) {
    if (state is! GameActive) return;
    final currentState = state as GameActive;
    if (currentState.localMustContinueFrom == null) return;
    _sendPendingSequence(currentState, emit);
  }

  /// Envoie la séquence en cours au serveur (coudou refusé ou timeout)
  void _sendPendingSequence(GameActive currentState, Emitter<GameState> emit) {
    _sendSequenceToServer(
      currentState.gameId,
      currentState.pendingSequence,
      currentState.board,
      currentState,
      emit,
    );
  }

  void _sendSequenceToServer(
    String gameId,
    List<Map<String, dynamic>> sequence,
    List<String> board,
    GameActive currentState,
    Emitter<GameState> emit,
  ) {
    wsService.sendMessage({
      'type': 'game.move',
      'gameId': gameId,
      'sequence': sequence,
    });

    emit(currentState.copyWith(
      board: board,
      clearSelection: true,
      clearCoudouDeadline: true,
      pendingSequence: [],
      localMustContinueFrom: null,
    ));
  }

  void _onPieceMoved(GamePieceMoved event, Emitter<GameState> emit) {
    // Cette méthode n'est plus utilisée, remplacée par _onCellClicked
  }

  void _onSurplaceRequested(GameSurplaceRequested event, Emitter<GameState> emit) {
    if (state is! GameActive) return;
    final s = state as GameActive;
    // Le joueur entre en mode surplace sans savoir s'il y a un fautif
    emit(s.copyWith(
      surplaceMode: true,
      clearSelection: true,
    ));
  }

  void _onSurplaceClicked(GameSurplaceClicked event, Emitter<GameState> emit) {
    if (state is! GameActive) return;
    final s = state as GameActive;
    if (!s.surplaceMode) return;

    // Vérifier que le pion cliqué est bien un pion adverse
    final piece = s.board[event.row][event.col];
    final opponentColor = s.yourColor == 'X' ? 'O' : 'X';
    if (piece == '.' || GameRules.getColor(piece) != opponentColor) return;

    // Envoyer le claim au serveur — il validera si c'est bien fautif
    wsService.sendMessage({
      'type': 'game.oops.claim',
      'gameId': s.gameId,
      'position': {'r': event.row, 'c': event.col},
    });

    // Sortir du mode surplace localement
    emit(s.copyWith(
      surplaceMode: false,
    ));
  }

  void _onSurplaceCancelled(GameSurplaceCancelled event, Emitter<GameState> emit) {
    if (state is! GameActive) return;
    final s = state as GameActive;
    emit(s.copyWith(surplaceMode: false));
  }

  void _onDrawOffered(GameDrawOffered event, Emitter<GameState> emit) {
    if (state is GameActive) {
      wsService.sendMessage({
        'type': 'game.draw.offer',
        'gameId': (state as GameActive).gameId,
      });
    }
  }

  void _onDrawAccepted(GameDrawAccepted event, Emitter<GameState> emit) {
    if (state is GameActive) {
      wsService.sendMessage({
        'type': 'game.draw.respond',
        'gameId': (state as GameActive).gameId,
        'accept': true,
      });
    }
  }

  void _onResigned(GameResigned event, Emitter<GameState> emit) {
    if (state is GameActive) {
      wsService.sendMessage({
        'type': 'game.resign',
        'gameId': (state as GameActive).gameId,
      });
    }
  }

  /// Rejoue une séquence de coups (coudou) étape par étape avec un délai entre chaque.
  Future<void> _replaySequence(
    List lastMove,
    List<String> startBoard,
    Emitter<GameState> emit,
    GameActive Function() buildFinalState,
  ) async {
    var currentBoard = startBoard;
    final currentState = state as GameActive;

    for (int i = 0; i < lastMove.length - 1; i++) {
      final move = lastMove[i];
      final fromR = (move['from']['r'] as num).toInt();
      final fromC = (move['from']['c'] as num).toInt();
      final toR = (move['to']['r'] as num).toInt();
      final toC = (move['to']['c'] as num).toInt();
      Map<String, int>? captured;
      if (move['captured'] != null) {
        captured = {
          'r': (move['captured']['r'] as num).toInt(),
          'c': (move['captured']['c'] as num).toInt(),
        };
      }

      currentBoard = GameRules.applyMove(currentBoard, fromR, fromC, toR, toC, captured);

      emit(currentState.copyWith(
        board: currentBoard,
        clearSelection: true,
      ));

      await Future.delayed(const Duration(milliseconds: 600));
    }

    // Dernière étape : appliquer aussi
    final lastStep = lastMove.last;
    final fromR = (lastStep['from']['r'] as num).toInt();
    final fromC = (lastStep['from']['c'] as num).toInt();
    final toR = (lastStep['to']['r'] as num).toInt();
    final toC = (lastStep['to']['c'] as num).toInt();
    Map<String, int>? captured;
    if (lastStep['captured'] != null) {
      captured = {
        'r': (lastStep['captured']['r'] as num).toInt(),
        'c': (lastStep['captured']['c'] as num).toInt(),
      };
    }
    currentBoard = GameRules.applyMove(currentBoard, fromR, fromC, toR, toC, captured);

    // Émettre l'état final du serveur (source de vérité)
    emit(buildFinalState());
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    _replayTimer?.cancel();
    _coudouTimer?.cancel();
    return super.close();
  }
}
