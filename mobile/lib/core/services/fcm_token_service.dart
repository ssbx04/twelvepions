import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../storage/auth_local_storage.dart';

/// Upload le token FCM au backend après chaque auth réussie.
class FcmTokenService {
  final Dio _dio;
  final AuthLocalStorage _storage;

  FcmTokenService(this._dio, this._storage);

  Future<void> init() async {
    await _requestPermission();
    await uploadToken();
    FirebaseMessaging.instance.onTokenRefresh.listen((_) => uploadToken());
  }

  Future<void> uploadToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      final jwt = await _storage.readJwt();
      if (jwt == null) return;
      await _dio.post(
        '/me/fcm-token',
        data: {'token': token},
        options: Options(headers: {'Authorization': 'Bearer $jwt'}),
      );
    } catch (_) {}
  }

  Future<void> _requestPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }
}
