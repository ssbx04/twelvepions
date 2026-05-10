import 'package:equatable/equatable.dart';

enum Presence { online, inGame, offline }

class Friend extends Equatable {
  final String id;
  final String username;
  final String? fullName;
  final int elo;
  final Presence presence;

  const Friend({
    required this.id,
    required this.username,
    this.fullName,
    required this.elo,
    required this.presence,
  });

  @override
  List<Object?> get props => [id, username, elo, presence];
}

class FriendRequest extends Equatable {
  final String requestId;
  final Friend from;
  final String createdAt;

  const FriendRequest({
    required this.requestId,
    required this.from,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [requestId];
}

class UserSearchResult extends Equatable {
  final String id;
  final String username;
  final String? fullName;
  final int elo;
  final String friendshipStatus; // NONE | PENDING_SENT | PENDING_RECEIVED | FRIENDS

  const UserSearchResult({
    required this.id,
    required this.username,
    this.fullName,
    required this.elo,
    required this.friendshipStatus,
  });

  @override
  List<Object?> get props => [id, friendshipStatus];
}
