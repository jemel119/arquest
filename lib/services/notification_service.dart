import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Top-level handler required by Firebase for background/terminated messages.
// Must be a top-level function, not a class method.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this fires.
  // No UI updates here — just log or process silently.
  debugPrint('Background message received: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Call this once after the user is signed in.
  Future<void> initialize({
    required String userId,
    required GlobalKey<ScaffoldMessengerState> messengerKey,
  }) async {
    // 1. Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Request permission (required on iOS and Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // 3. Get token and save to Firestore
    final token = await _fcm.getToken();
    if (token != null) await _saveToken(userId, token);

    // 4. Listen for token refresh and update Firestore
    _fcm.onTokenRefresh.listen((newToken) => _saveToken(userId, newToken));

    // 5. Foreground messages — show as in-app banner
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              '${notification.title ?? 'ARQuest'}: ${notification.body ?? ''}',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    // 6. Background tap — app was in background, user tapped notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped from background: ${message.data}');
      // Add navigation logic here based on message.data payload
    });

    // 7. Terminated tap — app was closed, user tapped notification to open it
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated via notification: ${initialMessage.data}');
      // Add navigation logic here based on initialMessage.data payload
    }
  }

  Future<void> _saveToken(String userId, String token) async {
    await _db
        .collection('users')
        .doc(userId)
        .update({'fcmToken': token});
  }
}