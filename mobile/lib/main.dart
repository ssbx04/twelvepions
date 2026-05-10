import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/services/deeplink_service.dart';
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

  // App en arrière-plan : l'utilisateur tape la notification.
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    sl<DeeplinkService>().handle(message.data);
  });

  // App complètement fermée : récupérer la notification qui a ouvert l'app.
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    sl<DeeplinkService>().handle(initialMessage.data);
  }

  runApp(const TwelvePionsApp());
}
