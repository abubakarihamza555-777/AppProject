// lib/shared/services/location_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase/supabase_client.dart';

class LocationService {
  static final SupabaseClient _supabase = SupabaseConfig.client;
  
  // List of allowed district IDs (only Ilala and Temeke)
  static const List<int> allowedDistrictIds = [1, 2]; // 1=Ilala, 2=Temeke
  
  // Get districts - FILTERED to only Ilala and Temeke
  static Future<List<Map<String, dynamic>>> getDistricts() async {
    try {
      final response = await _supabase
          .from('districts')
          .select()
          .inFilter('id', allowedDistrictIds)  // FILTER: Only IDs 1 and 2
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading districts: $e');
      // Return only Ilala and Temeke for development
      return [
        {'id': 1, 'name': 'Ilala'},
        {'id': 2, 'name': 'Temeke'},
      ];
    }
  }
  
  static Future<List<Map<String, dynamic>>> getWards(int districtId) async {
    try {
      final response = await _supabase
          .from('wards')
          .select()
          .eq('district_id', districtId)
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading wards: $e');
      // Return mock wards for Ilala and Temeke
      final mockWards = {
        1: [ // Ilala wards
          {'id': 1, 'name': 'Kariakoo'}, 
          {'id': 2, 'name': 'Upanga'},
          {'id': 3, 'name': 'Ilala'},
          {'id': 4, 'name': 'Buguruni'},
          {'id': 5, 'name': 'Gerezani'},
          {'id': 6, 'name': 'Kisutu'},
          {'id': 7, 'name': 'Kivukoni'},
          {'id': 8, 'name': 'Mchafukoge'},
          {'id': 9, 'name': 'Pugu'},
          {'id': 10, 'name': 'Tabata'},
        ],
        2: [ // Temeke wards
          {'id': 11, 'name': 'Tandika'}, 
          {'id': 12, 'name': "Chang'ombe"},
          {'id': 13, 'name': 'Mbagala'},
          {'id': 14, 'name': 'Azimio'},
          {'id': 15, 'name': 'Keko'},
          {'id': 16, 'name': 'Mtoni'},
          {'id': 17, 'name': 'Sandali'},
          {'id': 18, 'name': 'Temeke'},
          {'id': 19, 'name': 'Toangoma'},
          {'id': 20, 'name': 'Yombo Vituka'},
        ],
      };
      return mockWards[districtId] ?? [];
    }
  }
}
