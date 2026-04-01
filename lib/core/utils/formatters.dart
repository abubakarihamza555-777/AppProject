import 'package:intl/intl.dart';

class Formatters {
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'sw_TZ',
      symbol: 'TZS ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
  
  static String formatPhoneNumber(String phone) {
    if (phone.startsWith('0')) {
      return '255${phone.substring(1)}';
    }
    if (phone.startsWith('255')) {
      return phone;
    }
    return '255$phone';
  }
  
  static String formatOrderId(String orderId) {
    return '#${orderId.substring(0, 8).toUpperCase()}';
  }
  
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  static String titleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
} 
