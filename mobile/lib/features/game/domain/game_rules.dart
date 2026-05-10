class GameRules {
  static const int size = 5;

  static const List<List<int>> ortho = [
    [1, 0],
    [-1, 0],
    [0, 1],
    [0, -1]
  ];

  static int forwardDir(String color) => color.toUpperCase() == 'X' ? 1 : -1;

  static List<List<int>> pionDirs(String color) => [
        [forwardDir(color), 0],
        [0, -1],
        [0, 1],
      ];

  static bool inBounds(int r, int c) => r >= 0 && r < size && c >= 0 && c < size;

  static bool isDame(String char) {
    if (char == '.') return false;
    return char == char.toLowerCase(); // 'x' ou 'o' sont des dames
  }

  static String getColor(String char) {
    return char.toUpperCase();
  }

  // --- Mouvements simples ---
  static List<Map<String, int>> simpleMoves(List<String> board, int r, int c) {
    final char = board.length > r && board[r].length > c ? board[r][c] : '.';
    if (char == '.') return [];

    final out = <Map<String, int>>[];
    final isD = isDame(char);
    final color = getColor(char);

    if (isD) {
      for (final dir in ortho) {
        int nr = r + dir[0];
        int nc = c + dir[1];
        while (inBounds(nr, nc) && board[nr][nc] == '.') {
          out.add({'r': nr, 'c': nc});
          nr += dir[0];
          nc += dir[1];
        }
      }
    } else {
      for (final dir in pionDirs(color)) {
        final nr = r + dir[0];
        final nc = c + dir[1];
        if (inBounds(nr, nc) && board[nr][nc] == '.') {
          out.add({'r': nr, 'c': nc});
        }
      }
    }
    return out;
  }

  // --- Captures ---
  static List<Map<String, dynamic>> captureMoves(List<String> board, int r, int c) {
    final char = board.length > r && board[r].length > c ? board[r][c] : '.';
    if (char == '.') return [];

    final out = <Map<String, dynamic>>[];
    final isD = isDame(char);
    final color = getColor(char);

    if (isD) {
      for (final dir in ortho) {
        int nr = r + dir[0];
        int nc = c + dir[1];
        while (inBounds(nr, nc) && board[nr][nc] == '.') {
          nr += dir[0];
          nc += dir[1];
        }
        if (!inBounds(nr, nc)) continue;
        
        final targetChar = board[nr][nc];
        if (getColor(targetChar) == color) continue;

        int capR = nr;
        int capC = nc;

        int lr = nr + dir[0];
        int lc = nc + dir[1];
        while (inBounds(lr, lc) && board[lr][lc] == '.') {
          out.add({
            'r': lr,
            'c': lc,
            'captured': {'r': capR, 'c': capC}
          });
          lr += dir[0];
          lc += dir[1];
        }
      }
    } else {
      for (final dir in pionDirs(color)) {
        final mr = r + dir[0];
        final mc = c + dir[1];
        final tr = r + 2 * dir[0];
        final tc = c + 2 * dir[1];

        if (!inBounds(tr, tc)) continue;

        final midChar = board[mr][mc];
        if (midChar != '.' && getColor(midChar) != color && board[tr][tc] == '.') {
          out.add({
            'r': tr,
            'c': tc,
            'captured': {'r': mr, 'c': mc}
          });
        }
      }
    }
    return out;
  }

  static bool hasAnyCapture(List<String> board, String color) {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final p = board[r][c];
        if (p != '.' && getColor(p) == color) {
          if (captureMoves(board, r, c).isNotEmpty) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // --- Application Locale de Mouvement ---
  static List<String> applyMove(List<String> board, int fromR, int fromC, int toR, int toC, Map<String, int>? captured) {
    final newBoard = board.map((row) => row.split('')).toList();
    
    final char = newBoard[fromR][fromC];
    newBoard[fromR][fromC] = '.';
    
    if (captured != null) {
      newBoard[captured['r']!][captured['c']!] = '.';
    }
    
    // Check promotion
    String finalChar = char;
    if (!isDame(char)) {
      final color = getColor(char);
      if ((color == 'X' && toR == size - 1) || (color == 'O' && toR == 0)) {
        finalChar = finalChar.toLowerCase();
      }
    }
    
    newBoard[toR][toC] = finalChar;
    return newBoard.map((row) => row.join('')).toList();
  }
}
