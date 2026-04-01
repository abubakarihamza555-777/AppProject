 class SupabaseConstants {
  // Supabase credentials (anon key is safe for client apps)
  static const String supabaseUrl = 'https://iecigbcbnvcismasubvw.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImllY2lnYmNibnZjaXNtYXN1YnZ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUwMzgxNjksImV4cCI6MjA5MDYxNDE2OX0.RAznQO3hmgobV48C18ky7I2HL9_-qdPQtUeQQkqjsqg';
  
  // Tables
  static const String usersTable = 'users';
  static const String vendorsTable = 'vendors';
  static const String ordersTable = 'orders';
  static const String waterRequestsTable = 'water_requests';
  static const String paymentsTable = 'payments';
  static const String chatMessagesTable = 'chat_messages';
  static const String earningsTable = 'earnings';
  static const String notificationsTable = 'notifications';
}
