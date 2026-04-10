import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/notifications/notification_service.dart';
import '../../localization/language_provider.dart';

class NotificationIcon extends StatelessWidget {
  final VoidCallback onTap;
  final Color? color;
  final double? size;

  const NotificationIcon({
    super.key,
    required this.onTap,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, child) {
        final unreadCount = notificationService.unreadCount;
        
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color?.withValues(alpha: 0.1) ?? 
                     Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: color ?? Theme.of(context).colorScheme.primary,
                  size: size ?? 24,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('notifications')),
        actions: [
          Consumer<NotificationService>(
            builder: (context, notificationService, child) {
              if (notificationService.notifications.isNotEmpty) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'mark_all_read') {
                      notificationService.markAllAsRead();
                    } else if (value == 'clear_all') {
                      _showClearAllDialog(context, notificationService);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'mark_all_read',
                      child: Text(languageProvider.translate('mark_all_as_read')),
                    ),
                    PopupMenuItem(
                      value: 'clear_all',
                      child: Text(languageProvider.translate('clear_all')),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          if (notificationService.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notificationService.notifications.length,
            itemBuilder: (context, index) {
              final notification = notificationService.notifications[index];
              return NotificationTile(
                notification: notification,
                onTap: () {
                  notificationService.markAsRead(notification.id);
                },
                onDelete: () {
                  notificationService.deleteNotification(notification.id);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, NotificationService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              service.clearAll();
              Navigator.pop(context);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Notification icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead 
                            ? FontWeight.normal 
                            : FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Unread indicator and delete button
              Column(
                children: [
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(height: 8),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'rating':
        return Colors.orange;
      case 'system':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'rating':
        return Icons.star_outline;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
