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

  Future<void> _loadProfile() async {
    final controller = context.read<VendorProfileController>();
    await controller.loadVendorProfile(); // Use real vendor ID from controller
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

  // Helper method to get vehicle type name
  String _getVehicleTypeName(String? vehicleType) {
    switch (vehicleType) {
      case 'towable':
        return 'Towable Browser';
      case 'medium_truck':
        return 'Medium Truck';
      case 'heavy_truck':
        return 'Heavy Truck';
      default:
        return 'Unknown';
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final controller = context.read<VendorProfileController>();
      final success = await controller.updateProfile(
        businessName: _businessNameController.text,
        businessPhone: _businessPhoneController.text,
        businessAddress: _businessAddressController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        controller.toggleEditing();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final controller = Provider.of<VendorProfileController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('vendor_profile')),
        actions: [
          if (!controller.isEditing && controller.vendorProfile != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: controller.toggleEditing,
            ),
        ],
      ),
      body: controller.isLoading
          ? const LoadingIndicator()
          : controller.vendorProfile == null
              ? Center(
                  child: Text(languageProvider.translate('profile_not_found')),
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
                                  controller.vendorProfile!.businessName.initials,
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
                                        // Change profile picture
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
                        ),
                        const SizedBox(height: 16),

                        // Business Phone
                        CustomTextField(
                          label: languageProvider.translate('business_phone'),
                          controller: _businessPhoneController,
                          readOnly: !controller.isEditing,
                          isPhone: true,
                          prefixIcon: Icons.phone,
                        ),
                        const SizedBox(height: 16),

                        // Business Address
                        CustomTextField(
                          label: languageProvider.translate('business_address'),
                          controller: _businessAddressController,
                          readOnly: !controller.isEditing,
                          maxLines: 2,
                          prefixIcon: Icons.location_on,
                        ),
                        const SizedBox(height: 16),

                        // Business License (Read-only)
                        TextFormField(
                          initialValue: controller.vendorProfile!.businessLicense ?? 'Not provided',
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: languageProvider.translate('business_license'),
                            prefixIcon: const Icon(Icons.document_scanner),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Vehicle Type (Read-only)
                        TextFormField(
                          initialValue: _getVehicleTypeName(controller.vendorProfile?.vehicleType),
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Vehicle Type',
                            prefixIcon: const Icon(Icons.directions_car),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Max Liters Per Trip (Read-only)
                        TextFormField(
                          initialValue: '${controller.vendorProfile?.maxLitersPerTrip ?? 0} L',
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Max Liters Per Trip',
                            prefixIcon: const Icon(Icons.water_drop),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Verification Status
                        Card(
                          color: controller.vendorProfile?.isVerified == true 
                              ? Colors.green.shade50 
                              : Colors.orange.shade50,
                          child: ListTile(
                            leading: Icon(
                              controller.vendorProfile?.isVerified == true 
                                  ? Icons.verified 
                                  : Icons.pending,
                              color: controller.vendorProfile?.isVerified == true 
                                  ? Colors.green 
                                  : Colors.orange,
                            ),
                            title: Text(
                              controller.vendorProfile?.isVerified == true 
                                  ? 'Verified Vendor' 
                                  : 'Pending Verification',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              controller.vendorProfile?.isVerified == true 
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
                              controller.vendorProfile!.isActive
                                  ? languageProvider.translate('accepting_orders')
                                  : languageProvider.translate('not_accepting_orders'),
                            ),
                            value: controller.vendorProfile!.isActive,
                            onChanged: (_) async {
                              await controller.toggleAvailability();
                            },
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
