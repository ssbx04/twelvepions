import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/services/notification_service.dart';
import 'core/services/sound_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // UI : barre de statut transparente, pas de bouton de retour Android.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  await setupServiceLocator();
  await NotificationService().init();
  await SoundService.instance.init();

  runApp(const TwelvePionsApp());
}
