import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user_level.dart';
import '../models/auth_session_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<String> sendOtp(String phone);
  Future<AuthSessionModel> verifyOtp(String phone, String code);
  Future<AuthSessionModel> completeProfile({
    required String token,
    required String fullName,
    required String username,
    required UserLevel level,
  });
  Future<bool> checkUsername(String username);
  Future<UserModel> getMe(String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<String> sendOtp(String phone) async {
    try {
      final response = await dio.post(ApiEndpoints.authPhone, data: {'phone': phone});
      return response.data['devOtp'] as String;
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<AuthSessionModel> verifyOtp(String phone, String code) async {
    try {
      final response = await dio.post(
        ApiEndpoints.authVerifyOtp,
        data: {'phone': phone, 'code': code},
      );
      return AuthSessionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<AuthSessionModel> completeProfile({
    required String token,
    required String fullName,
    required String username,
    required UserLevel level,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.authCompleteProfile,
        data: {
          'fullName': fullName,
          'username': username,
          'level': level.apiValue,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return AuthSessionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<bool> checkUsername(String username) async {
    try {
      final response = await dio.get(
        ApiEndpoints.authCheckUsername,
        queryParameters: {'u': username},
      );
      return (response.data as Map<String, dynamic>)['available'] as bool;
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  @override
  Future<UserModel> getMe(String token) async {
    try {
      final response = await dio.get(
        ApiEndpoints.me,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  /// Convertit une [DioException] en [NetworkException] ou [ServerException].
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
