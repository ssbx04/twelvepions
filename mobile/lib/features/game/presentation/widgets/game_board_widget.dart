import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/services/vibration_service.dart';
import 'pion_widget.dart';

class GameBoardWidget extends StatefulWidget {
  final List<String> board;
  final String yourColor;
  final bool isMyTurn;
  final Map<String, int>? selectedCell;
  final List<Map<String, dynamic>> validDestinations;
  final bool surplaceMode;
  final List<Map<String, int>> oopsFaultyPositions;
  final Map<String, int>? chainFromCell;
  final Function(int r, int c) onCellClicked;

  const GameBoardWidget({
    super.key,
    required this.board,
    required this.yourColor,
    required this.isMyTurn,
    this.selectedCell,
    this.validDestinations = const [],
    this.surplaceMode = false,
    this.oopsFaultyPositions = const [],
    this.chainFromCell,
    required this.onCellClicked,
  });

  @override
  State<GameBoardWidget> createState() => _GameBoardWidgetState();
}

class _PieceData {
  final String id;
  String type;
  int r;
  int c;

  _PieceData({
    required this.id,
    required this.type,
    required this.r,
    required this.c,
  });
}

class _GameBoardWidgetState extends State<GameBoardWidget>
    with TickerProviderStateMixin {
  final List<_PieceData> _pieces = [];
  final List<_DyingPiece> _dyingPieces = [];
  final Set<String> _promotedIds = {};

  @override
  void initState() {
    super.initState();
    _syncBoard();
  }

  @override
  void didUpdateWidget(GameBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.board != widget.board) {
      _syncBoard();
    }
  }

  @override
  void dispose() {
    for (final dp in _dyingPieces) {
      dp.controller.dispose();
    }
    super.dispose();
  }

  void _syncBoard() {
    final newPieces = <Map<String, dynamic>>[];
    for (int r = 0; r < widget.board.length; r++) {
      for (int c = 0; c < widget.board[r].length; c++) {
        final piece = widget.board[r][c];
        if (piece != '.') {
          newPieces.add({'r': r, 'c': c, 'type': piece});
        }
      }
    }

    final matchedOldIds = <String>{};
    final matchedNewIndices = <int>{};

    // 1. Matches exacts (même position, même type de couleur)
    for (int i = 0; i < newPieces.length; i++) {
      final np = newPieces[i];
      final npColor = (np['type'] as String).toLowerCase();
      for (final p in _pieces) {
        if (matchedOldIds.contains(p.id)) continue;
        if (p.r == np['r'] && p.c == np['c'] && p.type.toLowerCase() == npColor) {
          // Détecter promotion
          if (p.type != np['type'] && (np['type'] as String) == (np['type'] as String).toLowerCase()) {
            _promotedIds.add(p.id);
            SoundService.instance.play(SoundType.dame);
          }
          p.type = np['type'] as String;
          matchedOldIds.add(p.id);
          matchedNewIndices.add(i);
          break;
        }
      }
    }

    // 2. Déplacements
    final toAdd = <_PieceData>[];
    bool hadCapture = false;
    for (int i = 0; i < newPieces.length; i++) {
      if (matchedNewIndices.contains(i)) continue;
      final np = newPieces[i];
      final npColor = (np['type'] as String).toLowerCase();

      _PieceData? found;
      for (final p in _pieces) {
        if (matchedOldIds.contains(p.id)) continue;
        if (p.type.toLowerCase() == npColor) {
          found = p;
          break;
        }
      }

      if (found != null) {
        found.r = np['r'] as int;
        found.c = np['c'] as int;
        // Détecter promotion lors du mouvement
        if (found.type != np['type'] && (np['type'] as String) == (np['type'] as String).toLowerCase()) {
          _promotedIds.add(found.id);
          SoundService.instance.play(SoundType.dame);
        }
        found.type = np['type'] as String;
        matchedOldIds.add(found.id);
      } else {
        final p = _PieceData(
          id: '${DateTime.now().microsecondsSinceEpoch}_$i',
          type: np['type'] as String,
          r: np['r'] as int,
          c: np['c'] as int,
        );
        toAdd.add(p);
      }
    }

    for (final p in toAdd) {
      matchedOldIds.add(p.id);
      _pieces.add(p);
    }

    // Dying animation pour les pièces capturées
    final dying = _pieces.where((p) => !matchedOldIds.contains(p.id)).toList();
    for (final p in dying) {
      hadCapture = true;
      _spawnDyingPiece(p);
    }
    _pieces.removeWhere((p) => !matchedOldIds.contains(p.id));

    // Sons + vibrations
    if (hadCapture) {
      SoundService.instance.play(SoundType.capture);
      VibrationService.instance.vibrate();
    } else if (toAdd.isEmpty && dying.isEmpty) {
      // Pas de changement = pas de son/vibration
    } else {
      SoundService.instance.play(SoundType.move);
      VibrationService.instance.vibrateLight();
    }

    setState(() {});

    // Clear promoted after a delay
    if (_promotedIds.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _promotedIds.clear());
      });
    }
  }

  void _spawnDyingPiece(_PieceData piece) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    final dp = _DyingPiece(
      type: piece.type,
      r: piece.r,
      c: piece.c,
      controller: controller,
    );
    _dyingPieces.add(dp);
    controller.forward().then((_) {
      if (mounted) {
        setState(() => _dyingPieces.remove(dp));
        controller.dispose();
      }
    });
  }

  // Convertit les coordonnées logiques (r,c) en coordonnées visuelles
  int _toVisualRow(int r) => widget.yourColor == 'O' ? r : 4 - r;
  int _toVisualCol(int c) => widget.yourColor == 'O' ? c : 4 - c;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.boardBorder,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Labels
            SizedBox(
              height: 20,
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Expanded(child: _buildHorizLabels()),
                  const SizedBox(width: 20),
                ],
              ),
            ),
            // Grid
            Expanded(
              child: Row(
                children: [
                  // Left Labels
                  SizedBox(
                    width: 20,
                    child: _buildVertLabels(),
                  ),
                  // The Board
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cellSize = constraints.maxWidth / 5;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            children: [
                              // Layer 1: Background cells (static grid)
                              _buildCellGrid(cellSize),
                              // Layer 2: Animated pieces on top
                              ..._buildAnimatedPieces(cellSize),
                              // Layer 3: Dying pieces (capture animation)
                              ..._buildDyingPieces(cellSize),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Right Labels
                  SizedBox(
                    width: 20,
                    child: _buildVertLabels(),
                  ),
                ],
              ),
            ),
            // Bottom Labels
            SizedBox(
              height: 20,
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Expanded(child: _buildHorizLabels()),
                  const SizedBox(width: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Grille de fond : couleurs des cases, X central, indicateurs de destination
  Widget _buildCellGrid(double cellSize) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
      ),
      itemCount: 25,
      itemBuilder: (context, index) {
        final visualRow = index ~/ 5;
        final visualCol = index % 5;

        final r = widget.yourColor == 'O' ? visualRow : 4 - visualRow;
        final c = widget.yourColor == 'O' ? visualCol : 4 - visualCol;

        final isCenter = r == 2 && c == 2;
        final isTopZone = r < 2 || (r == 2 && c < 2); // Zone initiale de X (Vert)
        final isBottomZone = r > 2 || (r == 2 && c > 2); // Zone initiale de O (Rouge)

        Color cellColor = AppColors.boardYellowCell;
        if (isTopZone) cellColor = AppColors.boardGreenCell;
        if (isBottomZone) cellColor = AppColors.boardRedCell;

        final isSelected = widget.selectedCell != null &&
            widget.selectedCell!['r'] == r &&
            widget.selectedCell!['c'] == c;

        if (isSelected) {
          cellColor = const Color(0xFFFDEF42);
        }

        return GestureDetector(
          onTap: () => widget.onCellClicked(r, c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: cellColor,
              border: Border.all(
                color: const Color(0x804A3017),
                width: 0.5,
              ),
              boxShadow: isSelected
                  ? [
                      const BoxShadow(
                        color: Color(0xE6FDEF42),
                        blurRadius: 22,
                        blurStyle: BlurStyle.inner,
                      )
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isCenter) ...[
                  Transform.rotate(
                    angle: 0.785398,
                    child: Container(
                        width: cellSize * 0.7,
                        height: 2,
                        color: const Color(0x604A3017)),
                  ),
                  Transform.rotate(
                    angle: -0.785398,
                    child: Container(
                        width: cellSize * 0.7,
                        height: 2,
                        color: const Color(0x604A3017)),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Pièces animées : chaque pion est un AnimatedPositioned qui glisse
  List<Widget> _buildAnimatedPieces(double cellSize) {
    final piecesWidgets = <Widget>[];
    final pionSize = cellSize * 0.95;

    for (final piece in _pieces) {
      final vr = _toVisualRow(piece.r);
      final vc = _toVisualCol(piece.c);

      final left = vc * cellSize + (cellSize - pionSize) / 2;
      final top = vr * cellSize + (cellSize - pionSize) / 2;

      final isSelected = widget.selectedCell != null &&
          widget.selectedCell!['r'] == piece.r &&
          widget.selectedCell!['c'] == piece.c;

      final isPromoted = _promotedIds.contains(piece.id);

      // Determine decoration
      BoxDecoration? decoration;
      if (isPromoted) {
        decoration = BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.7),
              blurRadius: 30,
              spreadRadius: 12,
            ),
          ],
        );
      } else if (isSelected) {
        decoration = const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xE6FDEF42),
              blurRadius: 22,
              blurStyle: BlurStyle.outer,
            )
          ],
        );
      }

      piecesWidgets.add(
        AnimatedPositioned(
          key: ValueKey(piece.id),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          left: left,
          top: top,
          width: pionSize,
          height: pionSize,
          child: IgnorePointer(
            ignoring: !widget.surplaceMode,
            child: GestureDetector(
              onTap: widget.surplaceMode ? () => widget.onCellClicked(piece.r, piece.c) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: decoration,
                child: AnimatedScale(
                  scale: isPromoted ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 400),
                  child: PionWidget(
                    type: piece.type,
                    size: pionSize,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return piecesWidgets;
  }

  /// Dying pieces : animation scale+rotation+fade pour les pions capturés
  List<Widget> _buildDyingPieces(double cellSize) {
    final widgets = <Widget>[];
    final pionSize = cellSize * 0.95;

    for (final dp in _dyingPieces) {
      final vr = _toVisualRow(dp.r);
      final vc = _toVisualCol(dp.c);
      final left = vc * cellSize + (cellSize - pionSize) / 2;
      final top = vr * cellSize + (cellSize - pionSize) / 2;

      widgets.add(
        Positioned(
          left: left,
          top: top,
          width: pionSize,
          height: pionSize,
          child: AnimatedBuilder(
            animation: dp.controller,
            builder: (context, child) {
              final t = dp.controller.value;
              // scale: 1 → 1.3 (at 50%) → 0
              final scale = t < 0.5
                  ? 1.0 + (t * 2) * 0.3
                  : 1.3 * (1.0 - ((t - 0.5) * 2));
              // rotation: 0 → 45°
              final rotation = t * pi / 4;
              // opacity: 1 → 0.8 → 0
              final opacity = t < 0.5
                  ? 1.0 - t * 0.4
                  : (1.0 - t) * 2 * 0.8;

              return Transform.scale(
                scale: scale.clamp(0.0, 2.0),
                child: Transform.rotate(
                  angle: rotation,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
              );
            },
            child: PionWidget(type: dp.type, size: pionSize),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildHorizLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ['A', 'B', 'C', 'D', 'E']
          .map((l) => Text(
                l,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0x8C4A3017)),
              ))
          .toList(),
    );
  }

  Widget _buildVertLabels() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ['1', '2', '3', '4', '5']
          .map((l) => Text(
                l,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0x8C4A3017)),
              ))
          .toList(),
    );
  }
}

class _DyingPiece {
  final String type;
  final int r;
  final int c;
  final AnimationController controller;

  _DyingPiece({
    required this.type,
    required this.r,
    required this.c,
    required this.controller,
  });
}
