import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

const _allUsersTopic = 'all_users';

/// Lets HomeScreen know a notification tap wants it to jump to a
/// particular bottom-nav tab (e.g. Matches) once it's mounted.
class NotificationNavigation extends ChangeNotifier {
  NotificationNavigation._();
  static final instance = NotificationNavigation._();

  int? _requestedTabIndex;

  void requestTab(int index) {
    _requestedTabIndex = index;
    notifyListeners();
  }

  /// Called by HomeScreen to consume any pending request.
  int? consumeRequestedTab() {
    final index = _requestedTabIndex;
    _requestedTabIndex = null;
    return index;
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be re-initialized in the background isolate.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  debugPrint('Background message received: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channel = AndroidNotificationChannel(
    'kisela_default',
    'Kisela notifications',
    description: 'Matches and messages on Kisela',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Some devices never resolve this dialog cleanly (OEM quirks, or the
      // timing of the very first permission prompt after install). Never
      // let it hang the rest of notification setup indefinitely.
      await _messaging
          .requestPermission(alert: true, badge: true, sound: true)
          .timeout(const Duration(seconds: 15));

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          _handleNotificationTap(response.payload);
        },
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      await _messaging.subscribeToTopic(_allUsersTopic);

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleNotificationTap(message.data['type']);
      });

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage.data['type']);
      }
    } catch (e) {
      // Notifications just won't work this session - never let setup
      // failures affect the rest of the app.
      debugPrint('NotificationService.initialize failed: $e');
    }
  }

  void _handleNotificationTap(String? type) {
    if (type == 'match' || type == 'message') {
      NotificationNavigation.instance.requestTab(1);
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data['type'],
    );
  }

  /// Saves the current device's FCM token to the user's profile so Cloud
  /// Functions can target it, and keeps it fresh if it rotates.
  Future<void> syncTokenForUser(String uid) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(uid, token);
    }
    _messaging.onTokenRefresh.listen((newToken) => _saveToken(uid, newToken));
  }

  Future<void> _saveToken(String uid, String token) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }
}
