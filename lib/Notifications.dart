import 'package:burtonaletrail_app/TrophyCabinet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// Import your navigator key and the destination page.
import 'main.dart'; // Assumes navigatorKey is defined here.

class NotificationService {
  // Singleton pattern: a single instance throughout the app.
  static final NotificationService _instance = NotificationService._internal();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  factory NotificationService() => _instance;

  // Private constructor.
  NotificationService._internal();

  // Instance of FlutterLocalNotificationsPlugin.
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initializes the notifications for both Android and iOS.
  Future<void> initialize() async {
    // Android initialization settings.
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS (Darwin) initialization settings.
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      // Request permissions for alert, badge, and sound.
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {
        // Optionally handle notifications received while the app is in the foreground.
      },
    );

    // Combine both platform settings.
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin.
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        // When the user taps the notification, check the payload
        // and navigate to the appropriate page.
        if (notificationResponse.payload != null) {
          if (notificationResponse.payload == 'badge_unlock') {
            // Navigate to the TeamCreatedPage using the global navigator key.
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => TrophyCabinetScreen(),
              ),
            );
          }
        }
      },
    );
  }

  /// Shows a local notification with the provided details.
  Future<void> showNotification({
    int id = 0,
    String title = 'Team Created!',
    String body = 'Your team was created successfully.',
    String payload = 'badge_unlock',
  }) async {
    // Android notification details.
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'team_channel', // Channel ID
      'Team Notifications', // Channel Name
      channelDescription: 'Notification channel for team creation status',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    // iOS notification details.
    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();

    // Combine platform-specific notification details.
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
}
