import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Afficher les notifications FCM en foreground via flutter_local_notifications.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? '12 Pions';
      final body = message.notification?.body ?? '';
      if (body.isNotEmpty) showFcmNotification(title, body);
    });
  }

  Future<void> showFcmNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'fcm_channel_id',
      'Notifications 12 Pions',
      channelDescription: 'Défis, demandes d\'ami et résultats de partie',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _notificationsPlugin.show(1, title, body, notificationDetails);
  }

  Future<void> showOtpNotification(String otp) async {
    const androidDetails = AndroidNotificationDetails(
      'otp_channel_id',
      'OTP Notifications',
      channelDescription: 'Notifications pour les codes OTP locaux',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      0,
      '12 Pions',
      'Votre code OTP est $otp',
      notificationDetails,
      payload: 'otp',
    );
  }
}
