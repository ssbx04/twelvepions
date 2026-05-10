import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/game_summary_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<GameSummaryModel>> getRecentGames(String token, {int limit = 5});
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final Dio dio;

  HomeRemoteDataSourceImpl(this.dio);

  @override
  Future<List<GameSummaryModel>> getRecentGames(String token, {int limit = 5}) async {
    try {
      final response = await dio.get(
        ApiEndpoints.meGames,
        queryParameters: {'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => GameSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList();
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
