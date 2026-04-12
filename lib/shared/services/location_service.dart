// lib/shared/services/location_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase/supabase_client.dart';

class LocationService {
  static final SupabaseClient _supabase = SupabaseConfig.client;
  
  static Future<List<Map<String, dynamic>>> getDistricts() async {
    try {
      final response = await _supabase
          .from('districts')
          .select()
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading districts: $e');
      // Return mock data for development if table doesn't exist
      return [
        {'id': 1, 'name': 'Ilala'},
        {'id': 2, 'name': 'Temeke'},
        {'id': 3, 'name': 'Kinondoni'},
        {'id': 4, 'name': 'Ubungo'},
        {'id': 5, 'name': 'Kigamboni'},
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
      // Return mock data for development
      final mockWards = {
        1: [
          {'id': 1, 'name': 'Kariakoo'}, 
          {'id': 2, 'name': 'Upanga'},
          {'id': 3, 'name': 'Ilala'},
          {'id': 4, 'name': 'Buguruni'},
        ],
        2: [
          {'id': 5, 'name': 'Tandika'}, 
          {'id': 6, 'name': "Chang'ombe"},
          {'id': 7, 'name': 'Mbagala'},
          {'id': 8, 'name': 'Azimio'},
        ],
        3: [
          {'id': 9, 'name': 'Mwananyamala'}, 
          {'id': 10, 'name': 'Mikocheni'},
          {'id': 11, 'name': 'Masaki'},
          {'id': 12, 'name': 'Oysterbay'},
        ],
        4: [
          {'id': 13, 'name': 'Ubungo'}, 
          {'id': 14, 'name': 'Sinza'},
          {'id': 15, 'name': 'Mabibo'},
        ],
        5: [
          {'id': 16, 'name': 'Kigamboni'}, 
          {'id': 17, 'name': 'Vijibweni'},
          {'id': 18, 'name': 'Kibada'},
        ],
      };
      return mockWards[districtId] ?? [];
    }
  }
}
