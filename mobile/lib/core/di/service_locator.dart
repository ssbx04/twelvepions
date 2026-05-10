import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/check_username.dart';
import '../../features/auth/domain/usecases/complete_profile.dart';
import '../../features/auth/domain/usecases/send_otp.dart';
import '../../features/auth/domain/usecases/verify_otp.dart';
import '../../features/auth/domain/usecases/get_me.dart';
import '../../features/auth/presentation/blocs/complete_profile/complete_profile_bloc.dart';
import '../../features/auth/presentation/blocs/otp/otp_bloc.dart';
import '../../features/auth/presentation/blocs/phone/phone_bloc.dart';
import '../../features/game/presentation/blocs/game/game_bloc.dart';
import '../../features/home/data/datasources/home_remote_data_source.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_recent_games.dart';
import '../../features/home/presentation/blocs/home/home_bloc.dart';
import '../../features/friends/data/datasources/friends_remote_datasource.dart';
import '../../features/friends/presentation/blocs/friends_bloc.dart';
import '../../features/play/presentation/blocs/matchmaking/matchmaking_bloc.dart';
import '../constants/api_endpoints.dart';
import '../services/fcm_token_service.dart';
import '../services/websocket_service.dart';
import '../storage/auth_local_storage.dart';

/// Container global de dépendances (GetIt).
///
/// Appeler [setupServiceLocator] dans `main()` avant `runApp`.
final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ─── Externes ────────────────────────────────────────────────────────────

  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
      ),
    );
    return dio;
  });

  // ─── Core ────────────────────────────────────────────────────────────────

  sl.registerLazySingleton<AuthLocalStorage>(() => AuthLocalStorage(sl()));
  sl.registerLazySingleton<WebSocketService>(() => WebSocketService());
  sl.registerLazySingleton<FcmTokenService>(() => FcmTokenService(sl(), sl()));

  // ─── Auth ────────────────────────────────────────────────────────────────

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remote: sl(), local: sl()),
  );

  sl.registerLazySingleton<SendOtp>(() => SendOtp(sl()));
  sl.registerLazySingleton<VerifyOtp>(() => VerifyOtp(sl()));
  sl.registerLazySingleton<CompleteProfile>(() => CompleteProfile(sl()));
  sl.registerLazySingleton<CheckUsername>(() => CheckUsername(sl()));

  // BLoCs : factory = nouvelle instance à chaque page (état frais).
  sl.registerFactory<PhoneBloc>(() => PhoneBloc(sendOtp: sl()));
  sl.registerFactory<OtpBloc>(
    () => OtpBloc(verifyOtp: sl(), sendOtp: sl()),
  );
  sl.registerFactory<CompleteProfileBloc>(
    () => CompleteProfileBloc(
      checkUsername: sl(),
      completeProfile: sl(),
    ),
  );
  
  // ─── Home ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<GetMe>(() => GetMe(sl()));

  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(remote: sl(), local: sl()),
  );
  sl.registerLazySingleton<GetRecentGames>(() => GetRecentGames(sl()));

  sl.registerFactory<HomeBloc>(
    () => HomeBloc(
      getMe: sl(),
      getRecentGames: sl(),
      authLocal: sl(),
      wsService: sl(),
    ),
  );

  // ─── Friends ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<FriendsRemoteDataSource>(
    () => FriendsRemoteDataSource(sl(), sl()),
  );
  sl.registerFactory<FriendsBloc>(() => FriendsBloc(sl(), sl()));

  // ─── Play / Matchmaking ──────────────────────────────────────────────────
  sl.registerFactory<MatchmakingBloc>(
    () => MatchmakingBloc(wsService: sl()),
  );

  // ─── Game ────────────────────────────────────────────────────────────────
  sl.registerFactory<GameBloc>(
    () => GameBloc(wsService: sl()),
  );
}
