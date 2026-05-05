import 'package:equatable/equatable.dart';

import 'user_level.dart';

class User extends Equatable {
  final String id;
  final String phone;
  final String? fullName;
  final String? username;
  final UserLevel? level;
  final int elo;

  const User({
    required this.id,
    required this.phone,
    this.fullName,
    this.username,
    this.level,
    required this.elo,
  });

  bool get profileComplete => fullName != null && username != null && level != null;

  @override
  List<Object?> get props => [id, phone, fullName, username, level, elo];
}
