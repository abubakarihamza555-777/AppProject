import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  static final supabase = Supabase.instance.client;
  
  // Simplified districts for Dar es Salaam
  static const List<Map<String, dynamic>> districts = [
    {
      'id': 1,
      'name': 'Ilala',
      'wards': [
        {'id': 1, 'name': 'Kariakoo'},
        {'id': 2, 'name': 'Upanga'},
      ],
    },
    {
      'id': 2,
      'name': 'Temeke',
      'wards': [
        {'id': 3, 'name': 'Tandika'},
        {'id': 4, 'name': 'Chang\'ombe'},
      ],
    },
  ];
  
  // Get all districts
  static List<Map<String, dynamic>> getDistricts() {
    return districts;
  }
  
  // Get wards by district ID
  static List<Map<String, dynamic>> getWardsByDistrict(int districtId) {
    final district = districts.firstWhere(
      (d) => d['id'] == districtId,
      orElse: () => {},
    );
    return List<Map<String, dynamic>>.from(district['wards'] ?? []);
  }
  
  // Get district name by ID
  static String getDistrictName(int districtId) {
    final district = districts.firstWhere(
      (d) => d['id'] == districtId,
      orElse: () => {'name': 'Unknown'},
    );
    return district['name'];
  }
  
  // Get ward name by ID
  static String getWardName(int wardId) {
    for (var district in districts) {
      final wards = List<Map<String, dynamic>>.from(district['wards']);
      final ward = wards.firstWhere(
        (w) => w['id'] == wardId,
        orElse: () => {'name': 'Unknown'},
      );
      if (ward['name'] != 'Unknown') {
        return ward['name'];
      }
    }
    return 'Unknown';
  }
  
  // Initialize districts and wards in database
  static Future<void> initializeLocations() async {
    try {
      // Check if districts already exist
      final existingDistricts = await supabase
          .from('districts')
          .select('id, name');
      
      if (existingDistricts.isEmpty) {
        // Insert districts
        for (var district in districts) {
          await supabase.from('districts').insert({
            'id': district['id'],
            'name': district['name'],
            'created_at': DateTime.now().toIso8601String(),
          });
          
          // Insert wards for this district
          final wards = List<Map<String, dynamic>>.from(district['wards']);
          for (var ward in wards) {
            await supabase.from('wards').insert({
              'id': ward['id'],
              'name': ward['name'],
              'district_id': district['id'],
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }
      }
    } catch (e) {
      print('Error initializing locations: $e');
    }
  }
  
  // Format address for display
  static String formatAddress({
    required int districtId,
    required int wardId,
    String? streetName,
    String? houseNumber,
    String? landmark,
  }) {
    final districtName = getDistrictName(districtId);
    final wardName = getWardName(wardId);
    
    List<String> addressParts = [];
    
    if (houseNumber != null && houseNumber.isNotEmpty) {
      addressParts.add(houseNumber);
    }
    
    if (streetName != null && streetName.isNotEmpty) {
      addressParts.add(streetName);
    }
    
    addressParts.add('$wardName, $districtName');
    addressParts.add('Dar es Salaam, Tanzania');
    
    if (landmark != null && landmark.isNotEmpty) {
      addressParts.add('Near: $landmark');
    }
    
    return addressParts.join(', ');
  }
  
  // Validate if district and ward combination is valid
  static bool isValidLocation(int districtId, int wardId) {
    final wards = getWardsByDistrict(districtId);
    return wards.any((ward) => ward['id'] == wardId);
  }
  
  // Get location for dropdown display
  static String getLocationDisplay(int districtId, int wardId) {
    final districtName = getDistrictName(districtId);
    final wardName = getWardName(wardId);
    return '$wardName, $districtName';
  }
}

class LocationSelector extends StatefulWidget {
  final int? initialDistrictId;
  final int? initialWardId;
  final Function(int districtId, int wardId) onLocationChanged;
  final bool enabled;
  
  const LocationSelector({
    super.key,
    this.initialDistrictId,
    this.initialWardId,
    required this.onLocationChanged,
    this.enabled = true,
  });

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  int? _selectedDistrictId;
  int? _selectedWardId;
  List<Map<String, dynamic>> _wards = [];
  
  @override
  void initState() {
    super.initState();
    _selectedDistrictId = widget.initialDistrictId;
    _selectedWardId = widget.initialWardId;
    
    if (_selectedDistrictId != null) {
      _wards = LocationService.getWardsByDistrict(_selectedDistrictId!);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // District Dropdown
        DropdownButtonFormField<int>(
          initialValue: _selectedDistrictId,
          decoration: InputDecoration(
            labelText: 'District',
            border: const OutlineInputBorder(),
            enabled: widget.enabled,
          ),
          items: LocationService.getDistricts().map((district) {
            return DropdownMenuItem<int>(
              value: district['id'],
              child: Text(district['name']),
            );
          }).toList(),
          onChanged: widget.enabled ? (districtId) {
            setState(() {
              _selectedDistrictId = districtId;
              _selectedWardId = null;
              _wards = districtId != null 
                  ? LocationService.getWardsByDistrict(districtId)
                  : [];
            });
            
            if (districtId != null && _selectedWardId != null) {
              widget.onLocationChanged(districtId, _selectedWardId!);
            }
          } : null,
        ),
        
        const SizedBox(height: 16),
        
        // Ward Dropdown
        DropdownButtonFormField<int>(
          initialValue: _selectedWardId,
          decoration: InputDecoration(
            labelText: 'Ward',
            border: const OutlineInputBorder(),
            enabled: widget.enabled && _wards.isNotEmpty,
          ),
          items: _wards.map((ward) {
            return DropdownMenuItem<int>(
              value: ward['id'],
              child: Text(ward['name']),
            );
          }).toList(),
          onChanged: widget.enabled && _wards.isNotEmpty ? (wardId) {
            setState(() {
              _selectedWardId = wardId;
            });
            
            if (_selectedDistrictId != null && wardId != null) {
              widget.onLocationChanged(_selectedDistrictId!, wardId);
            }
          } : null,
        ),
      ],
    );
  }
}
