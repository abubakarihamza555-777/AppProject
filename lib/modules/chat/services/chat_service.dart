import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase/supabase_client.dart';
import '../../../config/supabase/supabase_tables.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final SupabaseClient _supabase = SupabaseConfig.client;
  
  // Send message
  Future<ChatMessageModel?> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String message,
    String messageType = 'text',
  }) async {
    try {
      final messageData = {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': message,
        'message_type': messageType,
        'is_read': false,
        'sent_at': DateTime.now().toIso8601String(),
      };
      
      final response = await _supabase
          .from(SupabaseTables.chatMessages)
          .insert(messageData)
          .select()
          .single();
      
      return ChatMessageModel.fromJson(response);
    } catch (e) {
      print('Send message error: $e');
      rethrow;
    }
  }
  
  // Get conversation messages
  Future<List<ChatMessageModel>> getConversationMessages(String conversationId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.chatMessages)
          .select()
          .eq('conversation_id', conversationId)
          .order('sent_at', ascending: true);
      
      return response.map((json) => ChatMessageModel.fromJson(json)).toList();
    } catch (e) {
      print('Get messages error: $e');
      return [];
    }
  }
  
  // Listen to new messages in realtime
  Stream<ChatMessageModel> listenToMessages(String conversationId) {
    return _supabase
        .from(SupabaseTables.chatMessages)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .map((event) => ChatMessageModel.fromJson(event.first));
  }
  
  // Mark message as read
  Future<void> markAsRead(String messageId) async {
    try {
      await _supabase
          .from(SupabaseTables.chatMessages)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId);
    } catch (e) {
      print('Mark as read error: $e');
    }
  }
  
  // Mark all messages as read in conversation
  Future<void> markAllAsRead(String conversationId, String userId) async {
    try {
      await _supabase
          .from(SupabaseTables.chatMessages)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('conversation_id', conversationId)
          .eq('receiver_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('Mark all as read error: $e');
    }
  }
  
  // Create or get conversation
  Future<String> getOrCreateConversation(String userId1, String userId2) async {
    try {
      // Check if conversation exists
      final existing = await _supabase
          .from('conversations')
          .select()
          .or('and(user1_id.eq.$userId1,user2_id.eq.$userId2),and(user1_id.eq.$userId2,user2_id.eq.$userId1)')
          .maybeSingle();
      
      if (existing != null) {
        return existing['id'] as String;
      }
      
      // Create new conversation
      final newConversation = {
        'user1_id': userId1,
        'user2_id': userId2,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      final response = await _supabase
          .from('conversations')
          .insert(newConversation)
          .select()
          .single();
      
      return response['id'] as String;
    } catch (e) {
      print('Get/create conversation error: $e');
      rethrow;
    }
  }
}
