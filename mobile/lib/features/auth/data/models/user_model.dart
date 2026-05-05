import '../../domain/entities/user.dart';
import '../../domain/entities/user_level.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.phone,
    super.fullName,
    super.username,
    super.level,
    required super.elo,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String,
      fullName: json['fullName'] as String?,
      username: json['username'] as String?,
      level: json['level'] != null
          ? UserLevel.fromApi(json['level'] as String)
          : null,
      elo: json['elo'] as int,
    );
  }
}
