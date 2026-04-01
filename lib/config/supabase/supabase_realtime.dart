import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class SupabaseRealtime {
  final SupabaseClient _client = SupabaseConfig.client;
  
  Stream<List<Map<String, dynamic>>> listenToTable(
    String tableName, {
    String? filterField,
    String? filterValue,
  }) {
    final stream = _client.from(tableName).stream(primaryKey: ['id']);
    final filtered = (filterField != null && filterValue != null)
        ? stream.eq(filterField, filterValue)
        : stream;
    return filtered.map((event) => event);
  }
  
  Stream<Map<String, dynamic>> listenToOrder(String orderId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((event) => event.first);
  }
}
