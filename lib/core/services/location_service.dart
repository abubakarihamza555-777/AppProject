import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  static Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        hasPermission = await requestLocationPermission();
        if (!hasPermission) return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  static Future<List<Placemark>?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      return await placemarkFromCoordinates(lat, lng);
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }

  static Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      return locations.isNotEmpty ? locations.first : null;
    } catch (e) {
      print('Error getting coordinates: $e');
      return null;
    }
  }

  // District and Ward data for Dar es Salaam
  static const Map<int, Map<String, dynamic>> districts = {
    1: {'name': 'Ilala', 'wards': [
      {'id': 101, 'name': 'Kariakoo'},
      {'id': 102, 'name': 'Upanga'},
      {'id': 103, 'name': 'Chang\'ombe'},
      {'id': 104, 'name': 'Gongo la Mboto'},
      {'id': 105, 'name': 'Ilala'},
      {'id': 106, 'name': 'Jangwani'},
      {'id': 107, 'name': 'Kigogo'},
      {'id': 108, 'name': 'Kimanga'},
      {'id': 109, 'name': 'Kinondoni'},
      {'id': 110, 'name': 'Mchikichini'},
      {'id': 111, 'name': 'Mwembe Makumbi'},
      {'id': 112, 'name': 'Tabata'},
      {'id': 113, 'name': 'Temeke'},
      {'id': 114, 'name': 'Ukonga'},
      {'id': 115, 'name': 'Vingunguti'},
    ]},
    2: {'name': 'Kinondoni', 'wards': [
      {'id': 201, 'name': 'Hananasif'},
      {'id': 202, 'name': 'Kawe'},
      {'id': 203, 'name': 'Kigogo'},
      {'id': 204, 'name': 'Kimara'},
      {'id': 205, 'name': 'Kinondoni'},
      {'id': 206, 'name': 'Kisutu'},
      {'id': 207, 'name': 'Magomeni'},
      {'id': 208, 'name': 'Makumbusho'},
      {'id': 209, 'name': 'Manzese'},
      {'id': 210, 'name': 'Mabibo'},
      {'id': 211, 'name': 'Mikocheni'},
      {'id': 212, 'name': 'Msasani'},
      {'id': 213, 'name': 'Mwenge'},
      {'id': 214, 'name': 'Ndumbani'},
      {'id': 215, 'name': 'Ubungo'},
      {'id': 216, 'name': 'Wazo'},
    ]},
    3: {'name': 'Temeke', 'wards': [
      {'id': 301, 'name': 'Chang\'ombe'},
      {'id': 302, 'name': 'Kisutu'},
      {'id': 303, 'name': 'Mbagala'},
      {'id': 304, 'name': 'Mtoni'},
      {'id': 305, 'name': 'Temeke'},
      {'id': 306, 'name': 'Tandika'},
      {'id': 307, 'name': 'Toangoma'},
      {'id': 308, 'name': 'Yombo'},
      {'id': 309, 'name': 'Buza'},
      {'id': 310, 'name': 'Azimio'},
    ]},
    4: {'name': 'Ubungo', 'wards': [
      {'id': 401, 'name': 'Kimara'},
      {'id': 402, 'name': 'Kisongo'},
      {'id': 403, 'name': 'Mabibo'},
      {'id': 404, 'name': 'Makuburi'},
      {'id': 405, 'name': 'Mbezi'},
      {'id': 406, 'name': 'Mwenge'},
      {'id': 407, 'name': 'Ubungo'},
    ]},
    5: {'name': 'Kigamboni', 'wards': [
      {'id': 501, 'name': 'Ferry'},
      {'id': 502, 'name': 'Kigamboni'},
      {'id': 503, 'name': 'Mjimwema'},
      {'id': 504, 'name': 'Somangila'},
      {'id': 505, 'name': 'Vijibweni'},
    ]},
  };

  static List<Map<String, dynamic>> getDistricts() {
    return districts.entries.map((entry) => {
      'id': entry.key,
      'name': entry.value['name'],
    }).toList();
  }

  static List<Map<String, dynamic>> getWards(int districtId) {
    final district = districts[districtId];
    if (district == null) return [];
    return (district['wards'] as List<Map<String, dynamic>>);
  }

  static List<Map<String, dynamic>> getWardsByDistrict(int districtId) {
    return getWards(districtId);
  }

  // Legacy methods for backward compatibility
  static List<String> getDistrictNames() {
    return districts.values.map((d) => d['name'] as String).toList();
  }

  static List<String> getWardNamesByDistrictName(String districtName) {
    final district = districts.values.firstWhere(
      (d) => d['name'] == districtName,
      orElse: () => {'wards': <Map<String, dynamic>>[]},
    );
    return (district['wards'] as List<Map<String, dynamic>>)
        .map((w) => w['name'] as String)
        .toList();
  }
}
