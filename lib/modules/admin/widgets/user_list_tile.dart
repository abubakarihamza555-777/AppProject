import 'package:flutter/material.dart';
import '../../../modules/auth/models/user_model.dart';

class UserListTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onSuspend;
  final VoidCallback? onActivate;
  final VoidCallback? onViewDetails;

  const UserListTile({
    super.key,
    required this.user,
    this.onSuspend,
    this.onActivate,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(user.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.isActive ? 'Active' : 'Suspended',
                style: TextStyle(
                  fontSize: 12,
                  color: _getStatusColor(),
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user.isActive && onSuspend != null)
              IconButton(
                icon: const Icon(Icons.block, color: Colors.red),
                onPressed: onSuspend,
              ),
            if (!user.isActive && onActivate != null)
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: onActivate,
              ),
            if (onViewDetails != null)
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: onViewDetails,
              ),
          ],
        ),
        onTap: onViewDetails,
      ),
    );
  }

  Color _getRoleColor() {
    switch (user.role) {
      case 'admin':
        return Colors.red;
      case 'vendor':
        return Colors.orange;
      case 'customer':
      default:
        return Colors.blue;
    }
  }

  Color _getStatusColor() {
    return user.isActive ? Colors.green : Colors.red;
  }
} 
