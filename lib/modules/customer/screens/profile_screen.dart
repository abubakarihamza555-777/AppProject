import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../localization/language_provider.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../auth/controllers/auth_controller.dart';

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
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authController = context.read<AuthController>();
    final user = authController.currentUser;
    if (user != null) {
      _nameController.text = user.fullName;
      _phoneController.text = user.phone;
      _addressController.text = user.address ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      // Update profile logic here
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      final authController = context.read<AuthController>();
      await authController.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final authController = Provider.of<AuthController>(context);
    final user = authController.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('profile')),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
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
                        user?.fullName.initials ?? 'U',
                        style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_isEditing)
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
              
              // Name
              CustomTextField(
                label: languageProvider.translate('name'),
                controller: _nameController,
                readOnly: !_isEditing,
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              
              // Email
              TextFormField(
                initialValue: user?.email,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: languageProvider.translate('email'),
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              
              // Phone
              CustomTextField(
                label: languageProvider.translate('phone'),
                controller: _phoneController,
                readOnly: !_isEditing,
                isPhone: true,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 16),
              
              // Address
              CustomTextField(
                label: languageProvider.translate('address'),
                controller: _addressController,
                readOnly: !_isEditing,
                maxLines: 2,
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 24),
              
              if (_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: languageProvider.translate('cancel'),
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                          });
                          _loadUserData();
                        },
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: languageProvider.translate('save'),
                        onPressed: _saveProfile,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                CustomButton(
                  text: languageProvider.translate('logout'),
                  onPressed: _logout,
                  isOutlined: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
