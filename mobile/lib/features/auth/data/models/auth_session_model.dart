import '../../domain/entities/auth_session.dart';
import 'user_model.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.token,
    required super.profileComplete,
    required super.user,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      token: json['token'] as String,
      profileComplete: json['profileComplete'] as bool,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
