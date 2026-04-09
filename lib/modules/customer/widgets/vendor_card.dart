import 'package:flutter/material.dart';

class VendorCard extends StatelessWidget {
  final Map<String, dynamic> vendor;
  final VoidCallback onTap;

  const VendorCard({
    super.key,
    required this.vendor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final businessName = vendor['business_name'] ?? 'Unknown Business';
    final rating = (vendor['rating'] ?? 0.0).toDouble();
    final totalDeliveries = vendor['total_deliveries'] ?? 0;
    final profileImage = vendor['users']?['profile_image'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vendor Header
              Row(
                children: [
                  // Vendor Logo
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    backgroundImage: profileImage != null
                        ? NetworkImage(profileImage!)
                        : null,
                    child: profileImage == null
                        ? Text(
                            businessName.initials,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),

                  // Vendor Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          businessName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.local_shipping, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('$totalDeliveries deliveries'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Service Areas
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.green.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Service Areas: ${_getServiceAreasDisplay()}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Vehicle Type
              Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    color: Colors.blue.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Vehicle: ${_getVehicleTypeDisplay()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getServiceAreasDisplay() {
    final serviceAreas = vendor['service_areas'] ?? [];
    if (serviceAreas.isEmpty) return 'Not specified';
    
    // Helper location data
    final districts = [
      {'id': 1, 'name': 'Ilala'},
      {'id': 2, 'name': 'Temeke'},
    ];
    
    List<String> areaNames = [];
    for (var area in serviceAreas.take(3)) {
      if (area is int) {
        final district = districts.firstWhere(
          (d) => d['id'] == area,
          orElse: () => {'name': 'District $area'},
        );
        areaNames.add(district['name'].toString());
      } else if (area is Map) {
        areaNames.add('Ward ${area['ward_id']}');
      }
    }
    
    if (serviceAreas.length > 3) {
      return '${areaNames.join(', ')} +${serviceAreas.length - 3} more';
    }
    
    return areaNames.join(', ');
  }

  String _getVehicleTypeDisplay() {
    final vehicleType = vendor['vehicle_type'];
    switch (vehicleType) {
      case 'towable':
        return 'Towable Browser';
      case 'medium_truck':
        return 'Medium Truck';
      case 'heavy_truck':
        return 'Heavy Duty Truck';
      default:
        return 'Standard Vehicle';
    }
  }
}
