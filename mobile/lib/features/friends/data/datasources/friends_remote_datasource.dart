import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/auth_local_storage.dart';
import '../models/friend_models.dart';

class FriendsRemoteDataSource {
  final Dio dio;
  final AuthLocalStorage storage;
  FriendsRemoteDataSource(this.dio, this.storage);

  Future<Options> _authOptions() async {
    final token = await storage.readJwt();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<FriendModel>> getFriends() async {
    try {
      final res = await dio.get(ApiEndpoints.friends, options: await _authOptions());
      return (res.data as List).map((e) => FriendModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  Future<List<FriendRequestModel>> getRequests() async {
    try {
      final res = await dio.get(ApiEndpoints.friendsRequests, options: await _authOptions());
      return (res.data as List).map((e) => FriendRequestModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  Future<void> sendRequest(String targetId) async {
    try {
      await dio.post(ApiEndpoints.friendsRequest, queryParameters: {'targetId': targetId}, options: await _authOptions());
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      await dio.post(ApiEndpoints.friendsAccept, queryParameters: {'requestId': requestId}, options: await _authOptions());
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  Future<void> removeOrDecline(String targetId) async {
    try {
      await dio.delete(ApiEndpoints.friends, queryParameters: {'targetId': targetId}, options: await _authOptions());
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  Future<List<UserSearchResultModel>> getSuggestions() async {
    try {
      final res = await dio.get(ApiEndpoints.friendsSuggestions, options: await _authOptions());
      return (res.data as List).map((e) => UserSearchResultModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  Future<List<UserSearchResultModel>> searchUsers(String query) async {
    try {
      final res = await dio.get(ApiEndpoints.usersSearch, queryParameters: {'q': query}, options: await _authOptions());
      return (res.data as List).map((e) => UserSearchResultModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  Exception _toException(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NetworkException();
    }
    final body = e.response?.data;
    final status = e.response?.statusCode;
    if (body is Map && body.containsKey('error')) {
      return ServerException(
        code: body['error'] as String,
        message: body['message'] as String? ?? 'Erreur',
        statusCode: status,
      );
    }
    return ServerException(
      code: 'unknown',
      message: e.message ?? 'Erreur inattendue',
      statusCode: status,
    );
  }
}
