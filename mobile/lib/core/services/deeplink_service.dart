import 'dart:async';

import 'package:flutter/foundation.dart';

enum DeeplinkAction { openHome, openFriends, openFriendsRequests, openProfile }

/// Reçoit les données FCM et les convertit en actions de navigation.
/// - [stream] : écouter depuis HomePage pour switcher l'onglet
/// - [friendsSubTab] : écouter depuis FriendsTabView pour switcher le sous-onglet
/// - [setPending] / [consumePending] : cas app fermée → stocke avant que HomePage soit monté
class DeeplinkService {
  final _controller = StreamController<DeeplinkAction>.broadcast();
  final friendsSubTab = ValueNotifier<int>(0);
  DeeplinkAction? _pending;

  Stream<DeeplinkAction> get stream => _controller.stream;

  void handle(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final action = switch (type) {
      'friend_request' => DeeplinkAction.openFriendsRequests,
      'friend_accepted' => DeeplinkAction.openFriends,
      'game_ended' => DeeplinkAction.openProfile,
      'challenge_received' => DeeplinkAction.openHome,
      _ => null,
    };
    if (action == null) return;

    if (action == DeeplinkAction.openFriendsRequests) {
      friendsSubTab.value = 1;
    } else if (action == DeeplinkAction.openFriends) {
      friendsSubTab.value = 0;
    }

    if (_controller.hasListener) {
      _controller.add(action);
    } else {
      _pending = action;
    }
  }

  /// Appelé par HomePage dans initState pour traiter un deeplink pré-arrivée.
  DeeplinkAction? consumePending() {
    final a = _pending;
    _pending = null;
    return a;
  }

  void dispose() {
    _controller.close();
    friendsSubTab.dispose();
  }
}
