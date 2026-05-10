import '../../domain/entities/friend.dart';

class FriendModel extends Friend {
  const FriendModel({
    required super.id,
    required super.username,
    super.fullName,
    required super.elo,
    required super.presence,
  });

  factory FriendModel.fromJson(Map<String, dynamic> j) => FriendModel(
        id: j['id'] as String,
        username: j['username'] as String,
        fullName: j['fullName'] as String?,
        elo: j['elo'] as int,
        presence: _parsePresence(j['presence'] as String),
      );

  static Presence _parsePresence(String s) => switch (s) {
        'ONLINE' => Presence.online,
        'IN_GAME' => Presence.inGame,
        _ => Presence.offline,
      };
}

class FriendRequestModel extends FriendRequest {
  const FriendRequestModel({
    required super.requestId,
    required super.from,
    required super.createdAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> j) =>
      FriendRequestModel(
        requestId: j['requestId'] as String,
        from: FriendModel.fromJson(j['from'] as Map<String, dynamic>),
        createdAt: j['createdAt'] as String,
      );
}

class UserSearchResultModel extends UserSearchResult {
  const UserSearchResultModel({
    required super.id,
    required super.username,
    super.fullName,
    required super.elo,
    required super.friendshipStatus,
  });

  factory UserSearchResultModel.fromJson(Map<String, dynamic> j) =>
      UserSearchResultModel(
        id: j['id'] as String,
        username: j['username'] as String,
        fullName: j['fullName'] as String?,
        elo: j['elo'] as int,
        friendshipStatus: j['friendshipStatus'] as String,
      );
}
