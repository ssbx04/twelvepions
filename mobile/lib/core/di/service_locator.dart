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
import '../../features/home/presentation/blocs/home/home_bloc.dart';
import '../constants/api_endpoints.dart';
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
  sl.registerFactory<HomeBloc>(() => HomeBloc(getMe: sl()));
}
