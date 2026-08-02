import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../api/api_service.dart';
import '../services/token_storage_service.dart';

// Top-level background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('[FCM] Handling background message: ${message.messageId}');
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize(BuildContext? context) async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Request Notification Permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('[FCM] Permission status: ${settings.authorizationStatus}');
      }

      // 2. Set Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Initialize Local Notifications Plugin for Foreground Alerts
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings();

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (context != null && response.payload != null && response.payload!.isNotEmpty) {
            _handleNotificationTap(context, response.payload!);
          }
        },
      );

      // Create Android Notification Channel for lock-screen & system-bar banners with sound
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'Used for order updates and urgent store alerts.',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      // 4. Retrieve FCM Token & Register with Backend
      String? token = await _messaging.getToken();
      if (token != null) {
        await _registerTokenWithBackend(token);
      }

      // 5. Listen to Token Refresh Events
      _messaging.onTokenRefresh.listen((newToken) {
        _registerTokenWithBackend(newToken);
      });

      // 6. Handle Foreground Messages (In-App Banner & Local Notification)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('[FCM] Foreground message received: ${message.notification?.title}');
        }
        _showForegroundNotification(context, message);
      });

      // 7. Handle Background/Terminated Notification Taps
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (context != null) {
          _handleRemoteMessageTap(context, message);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Initialization error: $e');
      }
    }
  }

  Future<void> _registerTokenWithBackend(String fcmToken) async {
    try {
      final tokenStorage = TokenStorageService();
      final token = await tokenStorage.getToken();
      if (token == null || token.isEmpty) return;

      final platform = Platform.isIOS ? 'ios' : 'android';
      final apiService = ApiService();

      await apiService.post(
        '/notifications/token',
        data: {
          'fcmToken': fcmToken,
          'deviceType': 'MOBILE',
          'platform': platform,
        },
      );

      if (kDebugMode) {
        print('[FCM] Registered token with backend successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Token registration with backend failed: $e');
      }
    }
  }

  void _showForegroundNotification(BuildContext? context, RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Show Android/iOS Local Notification with sound & vibration
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Used for order updates and urgent store alerts.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
      ),
    );

    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: message.data['orderId'] ?? message.data['route'] ?? '',
    );

    // Show Material In-App Banner/Snackbar if context is available
    if (context != null && ScaffoldMessenger.of(context).mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title ?? 'Notification',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (notification.body != null)
                Text(notification.body!, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: message.data.containsKey('orderId')
              ? SnackBarAction(
                  label: 'VIEW',
                  textColor: Colors.amber,
                  onPressed: () {
                    final orderId = message.data['orderId'];
                    if (orderId != null) context.push('/orders/$orderId');
                  },
                )
              : null,
        ),
      );
    }
  }

  void _handleNotificationTap(BuildContext context, String payload) {
    if (payload.isNotEmpty) {
      context.push('/orders/$payload');
    } else {
      context.push('/notifications');
    }
  }

  void _handleRemoteMessageTap(BuildContext context, RemoteMessage message) {
    final orderId = message.data['orderId'];
    if (orderId != null) {
      context.push('/orders/$orderId');
    } else {
      context.push('/notifications');
    }
  }
}
