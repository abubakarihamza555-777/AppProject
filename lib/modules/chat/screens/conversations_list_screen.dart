import 'package:flutter/material.dart';
import '../../../config/routes/app_routes.dart';

class ConversationsListScreen extends StatelessWidget {
  const ConversationsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('Support'),
            subtitle: const Text('Tap to open chat'),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.chat,
                arguments: {
                  'conversationId': 'support',
                  'receiverId': 'support',
                  'receiverName': 'Support',
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
