import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper sur [FlutterSecureStorage] pour persister le JWT et l'ID user.
///
/// Le JWT est stocké chiffré (Keystore Android, Keychain iOS).
class AuthLocalStorage {
  static const String _jwtKey = '12pions.jwt';
  static const String _userIdKey = '12pions.userId';
  static const String _profileCompleteKey = '12pions.profileComplete';
  static const String _tutorialKey = '12pions.tutorial';

  final FlutterSecureStorage _storage;

  AuthLocalStorage(this._storage);

  Future<String?> readJwt() => _storage.read(key: _jwtKey);

  Future<void> writeJwt(String token) => _storage.write(key: _jwtKey, value: token);

  Future<String?> readUserId() => _storage.read(key: _userIdKey);

  Future<void> writeUserId(String userId) =>
      _storage.write(key: _userIdKey, value: userId);

  Future<bool> readProfileComplete() async {
    final v = await _storage.read(key: _profileCompleteKey);
    return v == 'true';
  }

  Future<void> writeProfileComplete(bool complete) => _storage.write(
        key: _profileCompleteKey,
        value: complete.toString(),
      );

  Future<bool> readHasSeenTutorial() async {
    final v = await _storage.read(key: _tutorialKey);
    return v == 'true';
  }

  Future<void> writeHasSeenTutorial(bool seen) => _storage.write(
        key: _tutorialKey,
        value: seen.toString(),
      );

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _jwtKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _profileCompleteKey),
      // On garde _tutorialKey pour qu'il ne se réaffiche pas à chaque reconnexion
    ]);
  }
}
