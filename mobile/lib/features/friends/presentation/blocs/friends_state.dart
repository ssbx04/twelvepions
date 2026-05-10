part of 'friends_bloc.dart';

enum FriendsStatus { initial, loading, loaded, error }

class FriendsState extends Equatable {
  final FriendsStatus status;
  final List<Friend> friends;
  final List<FriendRequest> requests;
  final List<UserSearchResult> searchResults;
  final String searchQuery;
  final bool isSearching;
  final String? errorMessage;

  const FriendsState({
    this.status = FriendsStatus.initial,
    this.friends = const [],
    this.requests = const [],
    this.searchResults = const [],
    this.searchQuery = '',
    this.isSearching = false,
    this.errorMessage,
  });

  FriendsState copyWith({
    FriendsStatus? status,
    List<Friend>? friends,
    List<FriendRequest>? requests,
    List<UserSearchResult>? searchResults,
    String? searchQuery,
    bool? isSearching,
    String? errorMessage,
  }) =>
      FriendsState(
        status: status ?? this.status,
        friends: friends ?? this.friends,
        requests: requests ?? this.requests,
        searchResults: searchResults ?? this.searchResults,
        searchQuery: searchQuery ?? this.searchQuery,
        isSearching: isSearching ?? this.isSearching,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props => [status, friends, requests, searchResults, searchQuery, isSearching, errorMessage];
}
