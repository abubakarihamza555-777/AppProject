import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> showSystemNotification(String title, String body) async {
    // This would integrate with your notification system
    // For now, just print the notification
    print('Notification: $title - $body');
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // This would show a local notification
    print('Local Notification: $title - $body');
  }
}
