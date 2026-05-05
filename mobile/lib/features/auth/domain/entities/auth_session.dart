import 'package:equatable/equatable.dart';

import 'user.dart';

/// Session d'authentification : JWT + état du profil + user.
class AuthSession extends Equatable {
  final String token;
  final bool profileComplete;
  final User user;

  const AuthSession({
    required this.token,
    required this.profileComplete,
    required this.user,
  });

  @override
  List<Object?> get props => [token, profileComplete, user];
}
