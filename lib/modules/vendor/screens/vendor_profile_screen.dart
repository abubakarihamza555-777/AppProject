import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../../localization/language_provider.dart';
import '../controllers/vendor_profile_controller.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessPhoneController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final controller = context.read<VendorProfileController>();
    await controller.loadVendorProfile();
    _updateControllers();
  }

  void _updateControllers() {
    final profile = context.read<VendorProfileController>().vendorProfile;
    if (profile != null) {
      _businessNameController.text = profile.businessName;
      _businessPhoneController.text = profile.businessPhone;
      _businessAddressController.text = profile.businessAddress;
    }
  }

  String _getVehicleTypeName(String? vehicleType) {
    switch (vehicleType) {
      case 'towable':
        return 'Towable Browser (400-2000L)';
      case 'medium_truck':
        return 'Medium Truck (3000-5000L)';
      case 'heavy_truck':
        return 'Heavy Duty Truck (8000-16000L)';
      default:
        return vehicleType ?? 'Not specified';
    }
  }

  String _formatServiceAreas(List<int> serviceAreas) {
    if (serviceAreas.isEmpty) return 'No service areas selected';
    
    // Map district IDs to names (you can expand this)
    final districtNames = {
      1: 'Ilala',
      2: 'Temeke',
      3: 'Kinondoni',
      4: 'Ubungo',
      5: 'Kigamboni',
    };
    
    final names = serviceAreas.map((id) => districtNames[id] ?? 'District $id').toList();
    return names.join(', ');
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final controller = context.read<VendorProfileController>();
      final success = await controller.updateProfile(
        businessName: _businessNameController.text.trim(),
        businessPhone: _businessPhoneController.text.trim(),
        businessAddress: _businessAddressController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        controller.toggleEditing();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final controller = Provider.of<VendorProfileController>(context);
    final profile = controller.vendorProfile;

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('vendor_profile')),
        centerTitle: true,
        actions: [
          if (!controller.isEditing && profile != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: controller.toggleEditing,
            ),
        ],
      ),
      body: controller.isLoading
          ? const LoadingIndicator()
          : profile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Vendor profile not found',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadProfile(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Profile Image
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  profile.businessName.initials,
                                  style: const TextStyle(
                                    fontSize: 40,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (controller.isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    radius: 18,
                                    child: IconButton(
                                      icon: const Icon(Icons.camera_alt, size: 16),
                                      color: Colors.white,
                                      onPressed: () {
                                        // TODO: Implement profile picture upload
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Profile picture upload coming soon'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Business Name
                        CustomTextField(
                          label: languageProvider.translate('business_name'),
                          controller: _businessNameController,
                          readOnly: !controller.isEditing,
                          prefixIcon: Icons.business,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter business name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Business Phone
                        CustomTextField(
                          label: languageProvider.translate('business_phone'),
                          controller: _businessPhoneController,
                          readOnly: !controller.isEditing,
                          isPhone: true,
                          prefixIcon: Icons.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter business phone';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Business Address
                        CustomTextField(
                          label: languageProvider.translate('business_address'),
                          controller: _businessAddressController,
                          readOnly: !controller.isEditing,
                          maxLines: 2,
                          prefixIcon: Icons.location_on,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter business address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Business License (Read-only from profile completion)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.document_scanner, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Business License',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      profile.businessLicense ?? 'Not provided',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Vehicle Type (Read-only from profile completion)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_car, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Vehicle Type',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      _getVehicleTypeName(profile.vehicleType),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Max Liters Per Trip (Read-only from profile completion)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.water_drop, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Max Capacity',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      '${profile.maxLitersPerTrip ?? 0} Liters',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Service Areas (Read-only from profile completion)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_city, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Service Areas',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      _formatServiceAreas(profile.serviceAreas),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Verification Status (Read-only from profile completion)
                        Card(
                          color: profile.isVerified 
                              ? Colors.green.shade50 
                              : Colors.orange.shade50,
                          child: ListTile(
                            leading: Icon(
                              profile.isVerified 
                                  ? Icons.verified 
                                  : Icons.pending,
                              color: profile.isVerified 
                                  ? Colors.green 
                                  : Colors.orange,
                            ),
                            title: Text(
                              profile.isVerified 
                                  ? 'Verified Vendor' 
                                  : 'Pending Verification',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              profile.isVerified 
                                  ? 'Your business is verified' 
                                  : 'Your profile is under review',
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Availability Toggle
                        Card(
                          child: SwitchListTile(
                            title: Text(languageProvider.translate('available_for_orders')),
                            subtitle: Text(
                              profile.isActive
                                  ? languageProvider.translate('accepting_orders')
                                  : languageProvider.translate('not_accepting_orders'),
                            ),
                            value: profile.isActive,
                            onChanged: controller.isEditing
                                ? (_) async {
                                    await controller.toggleAvailability();
                                    _loadProfile(); // Refresh after toggle
                                  }
                                : null,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        if (controller.isEditing) ...[
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: languageProvider.translate('cancel'),
                                  onPressed: () {
                                    controller.toggleEditing();
                                    _updateControllers();
                                  },
                                  isOutlined: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomButton(
                                  text: languageProvider.translate('save'),
                                  onPressed: _saveProfile,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }
}