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
  static const Map<String, List<String>> districtWards = {
    'Ilala': [
      'Kariakoo', 'Upanga', 'Chang\'ombe', 'Gongo la Mboto', 
      'Ilala', 'Jangwani', 'Kigogo', 'Kimanga', 'Kinondoni',
      'Mchikichini', 'Mwembe Makumbi', 'Tabata', 'Temeke',
      'Ukonga', 'Vingunguti'
    ],
    'Kinondoni': [
      'Hananasif', 'Kawe', 'Kigogo', 'Kimanga', 'Kinondoni',
      'Kisutu', 'Makumbusho', 'Manzese', 'Mikocheni', 'Mwananyamala',
      'Ndugumbi', 'Oysterbay', 'Regent Estate', 'Sinza', 'Tandale',
      'Ubungo', 'Wazo'
    ],
    'Temeke': [
      'Buguruni', 'Chang\'ombe', 'Changombe', 'Keko', 'Kibada',
      'Kijitonyama', 'Mbagala', 'Mbagala Kuu', 'Miburani', 'Tandika',
      'Temeke', 'Toangoma', 'Yombo Vituka'
    ],
    'Ubungo': [
      'Kimara', 'Kisongo', 'Mabibo', 'Makuburi', 'Mbezi',
      'Mwenge', 'Ubungo'
    ],
    'Kigamboni': [
      'Ferry', 'Kigamboni', 'Mjimwema', 'Somangila', 'Vijibweni'
    ]
  };

  static List<String> getDistricts() {
    return districtWards.keys.toList();
  }

  static List<String> getWards(String district) {
    return districtWards[district] ?? [];
  }

  static List<String> getWardsByDistrict(String district) {
    return districtWards[district] ?? [];
  }
}
