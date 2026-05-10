/// Endpoints du backend.
///
/// L'URL de base est injectée au lancement via `--dart-define=API_URL=...`.
/// En dev sans flag, fallback sur `http://localhost:8080` (utile pour l'émulateur
/// avec `adb reverse tcp:8080 tcp:8080`).
///
/// Pour le debug wireless, utiliser le script `mobile/run.sh` qui détecte
/// automatiquement l'IP WiFi de la machine et l'injecte.
class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://localhost:8080/ws',
  );

  static const String authPhone = '/auth/phone';
  static const String authVerifyOtp = '/auth/verify-otp';
  static const String authCompleteProfile = '/auth/complete-profile';
  static const String authCheckUsername = '/auth/check-username';

  static const String me = '/me';
  static const String meGames = '/me/games';

  static const String aiMove = '/ai/move';

  static const String friends = '/friends';
  static const String friendsRequests = '/friends/requests';
  static const String friendsRequest = '/friends/request';
  static const String friendsAccept = '/friends/accept';
  static const String usersSearch = '/users/search';
}

