import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Private constructor
  NotificationService._();

  // Singleton instance
  static final NotificationService instance = NotificationService._();

  // Firebase Messaging instance
  final _messaging = FirebaseMessaging.instance;

  // Flutter Local Notifications plugin
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // Flag to ensure notifications are initialized only once
  bool _isFlutterLocalNotificationsInitialized = false;

  Future<void> initialize() async {
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request notification permissions
    await _requestPermission();

    // Set up message handlers
    await _setupMessageHandlers();

    // Get and log FCM token
    final token = await _messaging.getToken();
    print('FCM Token: $token');
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Log permission status
    print('Permission status: ${settings.authorizationStatus}');
  }

  Future<void> _setupMessageHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await showNotification(message);
    });

    // Handle when app is opened from a terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle notification tap when app is in background/terminated
      _handleNotificationTap(message);
    });
  }

  Future<void> setupFlutterLocalNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) return;

    // Android notification channel setup
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    // Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Initialize flutter local notifications
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
    // Ensure local notifications are set up
    await setupFlutterLocalNotifications();

    final notification = message.notification;
    final android = message.notification?.android;

    // Only show if notification exists
    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: android.smallIcon,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Navigate to specific screen based on notification data
    // For example:
    // if (message.data['type'] == 'chat') {
    //   Navigator.pushNamed(context, '/chat', arguments: message.data);
    // }
  }

  void _onNotificationTap(NotificationResponse details) {
    // Handle notification tap when app is in foreground
    // Similar to _handleNotificationTap, but for foreground state
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize notifications for background messages
  await NotificationService.instance.setupFlutterLocalNotifications();
  await NotificationService.instance.showNotification(message);
}
