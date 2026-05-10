part of 'friends_bloc.dart';

abstract class FriendsEvent {}

class FriendsLoaded extends FriendsEvent {}

class FriendsSearchChanged extends FriendsEvent {
  final String query;
  FriendsSearchChanged(this.query);
}

class FriendRequestSent extends FriendsEvent {
  final String targetId;
  FriendRequestSent(this.targetId);
}

class FriendRequestAccepted extends FriendsEvent {
  final String requestId;
  final String fromId;
  FriendRequestAccepted({required this.requestId, required this.fromId});
}

class FriendRequestDeclined extends FriendsEvent {
  final String requestId;
  final String fromId;
  FriendRequestDeclined({required this.requestId, required this.fromId});
}

class FriendRemoved extends FriendsEvent {
  final String friendId;
  FriendRemoved(this.friendId);
}

// Événements internes déclenchés par le WS
class _FriendRequestReceivedWs extends FriendsEvent {
  final String requestId;
  final String fromId;
  final String fromUsername;
  final int fromElo;
  _FriendRequestReceivedWs({required this.requestId, required this.fromId, required this.fromUsername, required this.fromElo});
}

class _FriendRequestAcceptedWs extends FriendsEvent {
  final String byUsername;
  _FriendRequestAcceptedWs({required this.byUsername});
}

class _FriendPresenceChangedWs extends FriendsEvent {
  final String userId;
  final String presence;
  _FriendPresenceChangedWs({required this.userId, required this.presence});
}
