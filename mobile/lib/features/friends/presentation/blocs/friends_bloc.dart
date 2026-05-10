import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/websocket_service.dart';
import '../../data/datasources/friends_remote_datasource.dart';
import '../../domain/entities/friend.dart';

part 'friends_event.dart';
part 'friends_state.dart';

class FriendsBloc extends Bloc<FriendsEvent, FriendsState> {
  final FriendsRemoteDataSource _datasource;
  final WebSocketService _ws;
  StreamSubscription? _wsSub;

  FriendsBloc(this._datasource, this._ws) : super(const FriendsState()) {
    _wsSub = _ws.messages.listen(_onWsMessage);
    on<FriendsLoaded>(_onLoaded);
    on<FriendsSearchChanged>(_onSearchChanged);
    on<FriendRequestSent>(_onRequestSent);
    on<FriendRequestAccepted>(_onRequestAccepted);
    on<FriendRequestDeclined>(_onRequestDeclined);
    on<FriendRemoved>(_onFriendRemoved);
    on<_FriendRequestReceivedWs>(_onRequestReceivedWs);
    on<_FriendRequestAcceptedWs>(_onRequestAcceptedWs);
    on<_FriendPresenceChangedWs>(_onPresenceChangedWs);
  }

  void _onWsMessage(Map<String, dynamic> msg) {
    switch (msg['type'] as String?) {
      case 'friend.request.received':
        add(_FriendRequestReceivedWs(
          requestId: msg['requestId'] as String,
          fromId: msg['fromId'] as String,
          fromUsername: msg['fromUsername'] as String,
          fromElo: msg['fromElo'] as int,
        ));
      case 'friend.request.accepted':
        add(_FriendRequestAcceptedWs(byUsername: msg['byUsername'] as String));
      case 'friend.presence.changed':
        add(_FriendPresenceChangedWs(
          userId: msg['userId'] as String,
          presence: msg['presence'] as String,
        ));
    }
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    return super.close();
  }

  Future<void> _onLoaded(FriendsLoaded event, Emitter<FriendsState> emit) async {
    emit(state.copyWith(status: FriendsStatus.loading, searchQuery: '', searchResults: [], isSearching: false));
    try {
      final friends = await _datasource.getFriends();
      final requests = await _datasource.getRequests();
      List<UserSearchResult> suggestions = [];
      try {
        suggestions = await _datasource.getSuggestions();
      } catch (_) {}
      emit(state.copyWith(
        status: FriendsStatus.loaded,
        friends: friends,
        requests: requests,
        suggestions: suggestions,
      ));
    } catch (_) {
      emit(state.copyWith(status: FriendsStatus.error, errorMessage: 'Impossible de charger les amis'));
    }
  }

  Future<void> _onSearchChanged(FriendsSearchChanged event, Emitter<FriendsState> emit) async {
    final q = event.query.trim();
    emit(state.copyWith(searchQuery: q, isSearching: q.isNotEmpty));
    if (q.length < 2) {
      emit(state.copyWith(searchResults: []));
      return;
    }
    try {
      final results = await _datasource.searchUsers(q);
      emit(state.copyWith(searchResults: results));
    } catch (_) {
      emit(state.copyWith(searchResults: []));
    }
  }

  Future<void> _onRequestSent(FriendRequestSent event, Emitter<FriendsState> emit) async {
    try {
      await _datasource.sendRequest(event.targetId);
      UserSearchResult markSent(UserSearchResult r) => r.id == event.targetId
          ? UserSearchResult(id: r.id, username: r.username, fullName: r.fullName, elo: r.elo, friendshipStatus: 'PENDING_SENT')
          : r;
      emit(state.copyWith(
        searchResults: state.searchResults.map(markSent).toList(),
        suggestions: state.suggestions.map(markSent).toList(),
      ));
    } catch (_) {}
  }

  Future<void> _onRequestAccepted(FriendRequestAccepted event, Emitter<FriendsState> emit) async {
    try {
      await _datasource.acceptRequest(event.requestId);
      final newRequests = state.requests.where((r) => r.requestId != event.requestId).toList();
      emit(state.copyWith(requests: newRequests));
      final friends = await _datasource.getFriends();
      List<UserSearchResult> suggestions = state.suggestions;
      try {
        suggestions = await _datasource.getSuggestions();
      } catch (_) {}
      emit(state.copyWith(friends: friends, suggestions: suggestions));
    } catch (_) {}
  }

  Future<void> _onRequestDeclined(FriendRequestDeclined event, Emitter<FriendsState> emit) async {
    try {
      await _datasource.removeOrDecline(event.fromId);
      final newRequests = state.requests.where((r) => r.requestId != event.requestId).toList();
      emit(state.copyWith(requests: newRequests));
    } catch (_) {}
  }

  Future<void> _onFriendRemoved(FriendRemoved event, Emitter<FriendsState> emit) async {
    try {
      await _datasource.removeOrDecline(event.friendId);
      final newFriends = state.friends.where((f) => f.id != event.friendId).toList();
      emit(state.copyWith(friends: newFriends));
    } catch (_) {}
  }

  void _onRequestReceivedWs(_FriendRequestReceivedWs event, Emitter<FriendsState> emit) {
    final newRequest = FriendRequest(
      requestId: event.requestId,
      from: Friend(id: event.fromId, username: event.fromUsername, elo: event.fromElo, presence: Presence.online),
      createdAt: DateTime.now().toIso8601String(),
    );
    // Éviter les doublons si l'onglet vient juste d'être rechargé
    if (state.requests.any((r) => r.requestId == event.requestId)) return;
    emit(state.copyWith(requests: [newRequest, ...state.requests]));
  }

  Future<void> _onRequestAcceptedWs(_FriendRequestAcceptedWs event, Emitter<FriendsState> emit) async {
    try {
      final friends = await _datasource.getFriends();
      List<UserSearchResult> suggestions = state.suggestions;
      try {
        suggestions = await _datasource.getSuggestions();
      } catch (_) {}
      emit(state.copyWith(friends: friends, suggestions: suggestions));
    } catch (_) {}
  }

  void _onPresenceChangedWs(_FriendPresenceChangedWs event, Emitter<FriendsState> emit) {
    final newPresence = switch (event.presence) {
      'ONLINE'  => Presence.online,
      'IN_GAME' => Presence.inGame,
      _         => Presence.offline,
    };
    final updated = state.friends.map((f) {
      return f.id == event.userId
          ? Friend(id: f.id, username: f.username, fullName: f.fullName, elo: f.elo, presence: newPresence)
          : f;
    }).toList();
    emit(state.copyWith(friends: updated));
  }
}
