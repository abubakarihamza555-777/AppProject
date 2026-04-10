import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'order', 'payment', 'system', 'rating'

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      type: json['type'],
    );
  }
}

class NotificationService extends ChangeNotifier {
  static const String _notificationsKey = 'app_notifications';
  List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  List<NotificationModel> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();
  
  int get unreadCount => unreadNotifications.length;

  NotificationService() {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];
      
      _notifications = notificationsJson
          .map((json) => NotificationModel.fromJson(
                Map<String, dynamic>.from(
                  // Simple JSON parsing for stored notifications
                  Map<String, String>.fromEntries(
                    json.split(',').map((e) {
                      final parts = e.split(':');
                      return MapEntry(parts[0].trim(), parts[1].trim());
                    })
                  )
                )
              ))
          .toList();
      
      notifyListeners();
    } catch (e) {
      print('Error loading notifications: $e');
      _notifications = [];
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications
          .map((n) => n.toString())
          .toList();
      
      await prefs.setStringList(_notificationsKey, notificationsJson);
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
    );

    _notifications.insert(0, notification);
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = NotificationModel(
        id: _notifications[index].id,
        title: _notifications[index].title,
        message: _notifications[index].message,
        timestamp: _notifications[index].timestamp,
        isRead: true,
        type: _notifications[index].type,
      );
      
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => NotificationModel(
      id: n.id,
      title: n.title,
      message: n.message,
      timestamp: n.timestamp,
      isRead: true,
      type: n.type,
    )).toList();
    
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
    notifyListeners();
  }

  // Convenience methods for different notification types
  Future<void> showOrderNotification(String title, String message) {
    return addNotification(title: title, message: message, type: 'order');
  }

  Future<void> showPaymentNotification(String title, String message) {
    return addNotification(title: title, message: message, type: 'payment');
  }

  Future<void> showSystemNotification(String title, String message) {
    return addNotification(title: title, message: message, type: 'system');
  }

  Future<void> showRatingNotification(String title, String message) {
    return addNotification(title: title, message: message, type: 'rating');
  }
}
