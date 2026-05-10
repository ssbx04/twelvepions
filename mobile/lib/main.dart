import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/services/notification_service.dart';
import 'core/services/sound_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  await setupServiceLocator();
  await NotificationService().init();
  await SoundService.instance.init();

  runApp(const TwelvePionsApp());
}
