import 'dart:convert';
import 'package:flutter/services.dart';

class Languages {
  static Map<String, Map<String, String>> translations = {};
  
  static Future<void> loadTranslations() async {
    // Load English translations
    try {
      final enJson = await rootBundle.loadString('assets/translations/en.json');
      final enMap = json.decode(enJson) as Map<String, dynamic>;
      translations['en'] = enMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      print('Error loading English translations: $e');
      translations['en'] = {};
    }
    
    // Load Swahili translations
    try {
      final swJson = await rootBundle.loadString('assets/translations/sw.json');
      final swMap = json.decode(swJson) as Map<String, dynamic>;
      translations['sw'] = swMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      print('Error loading Swahili translations: $e');
      translations['sw'] = {};
    }
  }
  
  static String getTranslation(String key, String languageCode) {
    return translations[languageCode]?[key] ?? key;
  }
} 
