import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../localization/language_provider.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/customer_profile_controller.dart';
import '../../../shared/services/location_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  // Location selection for editing
  int? _selectedDistrictId;
  int? _selectedWardId;
  String _streetName = '';
  String _houseNumber = '';
  String _landmark = '';
  bool _isTruckAccessible = true;
  
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _wards = [];
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadLocationData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final controller = context.read<CustomerProfileController>();
    await controller.loadCustomerProfile();
    _updateControllers();
  }

  void _updateControllers() {
    final controller = context.read<CustomerProfileController>();
    final profile = controller.profileData;
    
    _nameController.text = profile['full_name'] ?? '';
    _phoneController.text = profile['phone'] ?? '';
    _addressController.text = profile['address'] ?? '';
    
    _selectedDistrictId = profile['district_id'];
    _selectedWardId = profile['ward_id'];
    _streetName = profile['street_name'] ?? '';
    _houseNumber = profile['house_number'] ?? '';
    _landmark = profile['landmark'] ?? '';
    _isTruckAccessible = profile['is_truck_accessible'] ?? true;
    
    if (_selectedDistrictId != null) {
      _loadWardsForDistrict(_selectedDistrictId!);
    }
  }

  Future<void> _loadLocationData() async {
    setState(() => _isLoadingLocation = true);
    try {
      _districts = await LocationService.getDistricts();
      setState(() {});
    } catch (e) {
      print('Error loading districts: $e');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _loadWardsForDistrict(int districtId) async {
    try {
      _wards = await LocationService.getWards(districtId);
      setState(() {});
    } catch (e) {
      print('Error loading wards: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final controller = context.read<CustomerProfileController>();
    
    // First save basic info
    final basicSuccess = await controller.updateBasicProfile(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
    );
    
    // Then save location details if changed
    if (_selectedDistrictId != null && _selectedWardId != null) {
      await controller.updateCustomerProfile(
        districtId: _selectedDistrictId!,
        wardId: _selectedWardId!,
        streetName: _streetName,
        houseNumber: _houseNumber,
        landmark: _landmark.isEmpty ? null : _landmark,
        isTruckAccessible: _isTruckAccessible,
      );
    }
    
    if (basicSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      controller.toggleEditing();
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final controller = Provider.of<CustomerProfileController>(context);
    final isSwahili = languageProvider.currentLocale.languageCode == 'sw';
    final profile = controller.profileData;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isSwahili ? 'Wasifu Wangu' : 'My Profile'),
        centerTitle: true,
        actions: [
          if (!controller.isEditing && profile.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: controller.toggleEditing,
            ),
        ],
      ),
      body: controller.isLoading
          ? const LoadingIndicator()
          : profile.isEmpty
              ? _buildEmptyState(isSwahili)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildProfileHeader(controller, isSwahili),
                        const SizedBox(height: 24),
                        _buildBasicInfoSection(controller, isSwahili),
                        const SizedBox(height: 24),
                        _buildLocationSection(controller, isSwahili),
                        const SizedBox(height: 24),
                        if (controller.isEditing) _buildActionButtons(isSwahili),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isSwahili) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            isSwahili ? 'Wasifu haujakamilika' : 'Profile not completed',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            isSwahili ? 'Tafadhali kamilisha wasifu wako' : 'Please complete your profile',
            style: GoogleFonts.poppins(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.customerProfileCompletion);
            },
            child: Text(isSwahili ? 'Kamilisha Wasifu' : 'Complete Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(CustomerProfileController controller, bool isSwahili) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              controller.fullName.initials,
              style: const TextStyle(fontSize: 40, color: Colors.white),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Photo upload coming soon')),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(CustomerProfileController controller, bool isSwahili) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSwahili ? 'Taarifa za Msingi' : 'Basic Information',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: isSwahili ? 'Jina Kamili' : 'Full Name',
            controller: _nameController,
            readOnly: !controller.isEditing,
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your name';
              return null;
            },
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: isSwahili ? 'Namba ya Simu' : 'Phone Number',
            controller: _phoneController,
            readOnly: !controller.isEditing,
            isPhone: true,
            prefixIcon: Icons.phone_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter phone number';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: controller.email,
            readOnly: true,
            decoration: InputDecoration(
              labelText: isSwahili ? 'Barua pepe' : 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(CustomerProfileController controller, bool isSwahili) {
    final hasLocation = controller.districtId != null && controller.wardId != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSwahili ? 'Anwani ya Kufikishia' : 'Delivery Address',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (!hasLocation && !controller.isEditing)
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.customerProfileCompletion);
                  },
                  child: Text(isSwahili ? 'Ongeza' : 'Add'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (!hasLocation && !controller.isEditing)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.location_off, size: 48, color: Colors.orange.shade700),
                  const SizedBox(height: 8),
                  Text(
                    isSwahili ? 'Hujatoa anwani yako' : 'No delivery address set',
                    style: GoogleFonts.poppins(color: Colors.orange.shade700),
                  ),
                ],
              ),
            )
          else if (!controller.isEditing)
            Column(
              children: [
                _buildReadOnlyLocationTile(Icons.location_city, 'District', _getDistrictName()),
                _buildReadOnlyLocationTile(Icons.place, 'Ward', _getWardName()),
                _buildReadOnlyLocationTile(Icons.streetview, 'Street', controller.streetName),
                _buildReadOnlyLocationTile(Icons.home, 'House', controller.houseNumber),
                if (controller.landmark.isNotEmpty)
                  _buildReadOnlyLocationTile(Icons.flag, 'Landmark', controller.landmark),
                _buildReadOnlyLocationTile(
                  Icons.local_shipping,
                  'Truck Access',
                  controller.isTruckAccessible ? 'Yes' : 'No',
                ),
              ],
            )
          else
            Column(
              children: [
                _buildEditableDistrictSelector(isSwahili),
                const SizedBox(height: 12),
                _buildEditableWardSelector(isSwahili),
                const SizedBox(height: 12),
                _buildEditableTextField(
                  isSwahili ? 'Jina la Mtaa' : 'Street Name',
                  _streetName,
                  (value) => _streetName = value,
                ),
                const SizedBox(height: 12),
                _buildEditableTextField(
                  isSwahili ? 'Namba ya Nyumba' : 'House Number',
                  _houseNumber,
                  (value) => _houseNumber = value,
                ),
                const SizedBox(height: 12),
                _buildEditableTextField(
                  isSwahili ? 'Mahali pa Kujulikana' : 'Landmark',
                  _landmark,
                  (value) => _landmark = value,
                ),
                const SizedBox(height: 12),
                _buildTruckAccessibilityToggle(isSwahili),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyLocationTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                Text(value.isNotEmpty ? value : 'Not set', style: GoogleFonts.poppins(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDistrictSelector(bool isSwahili) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isSwahili ? 'Wilaya' : 'District', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: _selectedDistrictId,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: isSwahili ? 'Chagua Wilaya' : 'Select District',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: _districts.map((d) {
            return DropdownMenuItem(value: d['id'] as int, child: Text(d['name']));
          }).toList(),
          onChanged: (value) async {
            setState(() {
              _selectedDistrictId = value;
              _selectedWardId = null;
              _wards = [];
            });
            if (value != null) await _loadWardsForDistrict(value);
          },
        ),
      ],
    );
  }

  Widget _buildEditableWardSelector(bool isSwahili) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isSwahili ? 'Kata' : 'Ward', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: _selectedWardId,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: isSwahili ? 'Chagua Kata' : 'Select Ward',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: _wards.map((w) {
            return DropdownMenuItem(value: w['id'] as int, child: Text(w['name']));
          }).toList(),
          onChanged: (value) => setState(() => _selectedWardId = value),
        ),
      ],
    );
  }

  Widget _buildEditableTextField(String label, String value, Function(String) onChanged) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildTruckAccessibilityToggle(bool isSwahili) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isSwahili ? 'Ufikiaji wa Lori' : 'Truck Accessibility', 
             style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isTruckAccessible = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isTruckAccessible ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isTruckAccessible ? Colors.green : Colors.grey.shade300,
                      width: _isTruckAccessible ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      isSwahili ? 'Ndiyo' : 'Yes',
                      style: TextStyle(
                        color: _isTruckAccessible ? Colors.green : Colors.grey,
                        fontWeight: _isTruckAccessible ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isTruckAccessible = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_isTruckAccessible ? Colors.red.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !_isTruckAccessible ? Colors.red : Colors.grey.shade300,
                      width: !_isTruckAccessible ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      isSwahili ? 'Hapana' : 'No',
                      style: TextStyle(
                        color: !_isTruckAccessible ? Colors.red : Colors.grey,
                        fontWeight: !_isTruckAccessible ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isSwahili) {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: isSwahili ? 'Ghairi' : 'Cancel',
            onPressed: () {
              context.read<CustomerProfileController>().toggleEditing();
              _updateControllers();
            },
            isOutlined: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomButton(
            text: isSwahili ? 'Hifadhi' : 'Save',
            onPressed: _saveProfile,
          ),
        ),
      ],
    );
  }

  String _getDistrictName() {
    final district = _districts.firstWhere(
      (d) => d['id'] == _selectedDistrictId,
      orElse: () => {'name': 'Unknown'},
    );
    return district['name'] as String;
  }

  String _getWardName() {
    final ward = _wards.firstWhere(
      (w) => w['id'] == _selectedWardId,
      orElse: () => {'name': 'Unknown'},
    );
    return ward['name'] as String;
  }
}
