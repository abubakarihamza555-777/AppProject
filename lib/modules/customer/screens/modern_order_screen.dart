import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../localization/language_provider.dart';
import '../controllers/home_controller.dart';
import '../controllers/customer_profile_controller.dart';
import '../services/order_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/order_model.dart';
import '../../../shared/services/location_service.dart';

class ModernOrderScreen extends StatefulWidget {
  const ModernOrderScreen({super.key});

  @override
  State<ModernOrderScreen> createState() => _ModernOrderScreenState();
}

class _ModernOrderScreenState extends State<ModernOrderScreen>
    with TickerProviderStateMixin {
  // ==================== CONTROLLERS ====================
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _houseController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _notesController = TextEditingController();
  final _quantityController = TextEditingController();

  // ==================== SERVICES ====================
  late final OrderService _orderService;

  // ==================== STATE VARIABLES ====================
  int _selectedQuantity = 40;
  String? _selectedVendorId;
  Map<String, dynamic>? _selectedVendor;
  bool _useAlternativeAddress = false;
  bool _isPlacingOrder = false;
  final String _selectedPaymentMethod = 'cash';
  String? _customerId;
  bool _isLoadingVendors = true;
  bool _isLoadingProfile = true;

  // ==================== LOCATION DATA ====================
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _wards = [];
  int? _selectedDistrictId;
  int? _selectedWardId;
  String _savedStreetName = '';
  String _savedHouseNumber = '';
  String _savedLandmark = '';
  bool _savedTruckAccess = true;
  String _customerDistrictName = '';
  String _customerWardName = '';

  // ==================== ANIMATIONS ====================
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ==================== VEHICLE TYPES ====================
  final Map<String, Map<String, dynamic>> _vehicleTypes = {
    'towable': {
      'icon': Icons.agriculture,
      'color': Colors.green,
      'name': 'Towable Browser',
      'name_sw': 'Towable Browser',
      'capacity': '400-2000L',
      'min': 400,
      'max': 2000,
      'description': 'Inafaa kwa nyumba ndogo',
    },
    'medium_truck': {
      'icon': Icons.local_shipping,
      'color': Colors.blue,
      'name': 'Medium Truck',
      'name_sw': 'Lori la Kati',
      'capacity': '3000-5000L',
      'min': 3000,
      'max': 5000,
      'description': 'Inafaa kwa majengo ya ghorofa',
    },
    'heavy_truck': {
      'icon': Icons.airport_shuttle,
      'color': Colors.orange,
      'name': 'Heavy Duty Truck',
      'name_sw': 'Lori Kubwa',
      'capacity': '8000-16000L',
      'min': 8000,
      'max': 16000,
      'description': 'Inafaa kwa viwanda na makubwa',
    },
  };

  // ==================== LIFECYCLE ====================
  @override
  void initState() {
    super.initState();
    _orderService = OrderService();
    _setupAnimations();
    _initializeScreen();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _quantityController.text = _selectedQuantity.toString();
  }

  Future<void> _initializeScreen() async {
    await _loadCustomerData();
    await _loadLocationData();
    await _loadVendors();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _streetController.dispose();
    _houseController.dispose();
    _landmarkController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // ==================== DATA LOADING ====================
  Future<void> _loadCustomerData() async {
    setState(() => _isLoadingProfile = true);

    try {
      final authController = AuthController();
      await authController.initialize();
      final user = authController.currentUser;

      if (user != null) {
        _customerId = user.id;

        // Load saved address from profile
        final profileController = context.read<CustomerProfileController>();
        await profileController.loadCustomerProfile();
        final profile = profileController.profileData;

        if (profile.isNotEmpty) {
          _selectedDistrictId = profile['district_id'];
          _selectedWardId = profile['ward_id'];
          _savedStreetName = profile['street_name'] ?? '';
          _savedHouseNumber = profile['house_number'] ?? '';
          _savedLandmark = profile['landmark'] ?? '';
          _savedTruckAccess = profile['is_truck_accessible'] ?? true;

          // Get district and ward names
          _customerDistrictName = await _getDistrictName(_selectedDistrictId);
          _customerWardName = await _getWardName(_selectedWardId);

          // Pre-fill if using saved address
          _streetController.text = _savedStreetName;
          _houseController.text = _savedHouseNumber;
          _landmarkController.text = _savedLandmark;
        }
      } else {
        _showSnackBar('Please login to place an order', Colors.red);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
        });
      }
    } catch (e) {
      print('Error loading customer data: $e');
    } finally {
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<String> _getDistrictName(int? districtId) async {
    if (districtId == null) return '';
    final districts = await LocationService.getDistricts();
    final district = districts.firstWhere(
      (d) => d['id'] == districtId,
      orElse: () => {'name': ''},
    );
    return district['name'] as String;
  }

  Future<String> _getWardName(int? wardId) async {
    if (wardId == null) return '';
    if (_selectedDistrictId == null) return '';
    final wards = await LocationService.getWards(_selectedDistrictId!);
    final ward = wards.firstWhere(
      (w) => w['id'] == wardId,
      orElse: () => {'name': ''},
    );
    return ward['name'] as String;
  }

  Future<void> _loadLocationData() async {
    try {
      _districts = await LocationService.getDistricts();
      if (_selectedDistrictId != null) {
        _wards = await LocationService.getWards(_selectedDistrictId!);
      }
      setState(() {});
    } catch (e) {
      print('Error loading locations: $e');
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

  Future<void> _loadVendors() async {
    setState(() => _isLoadingVendors = true);
    try {
      final homeController = context.read<HomeController>();
      // Pass customer's district and ward to filter vendors
      await homeController.loadVendorsByLocation(
        districtId: _selectedDistrictId,
        wardId: _selectedWardId,
      );
      setState(() {});
    } catch (e) {
      print('Error loading vendors: $e');
      _showSnackBar('Error loading vendors. Please try again.', Colors.red);
    } finally {
      setState(() => _isLoadingVendors = false);
    }
  }

  // ==================== CALCULATIONS ====================
  int _calculateWaterCost() {
    return _selectedQuantity * 100; // 100 TZS per liter
  }

  int _calculateDeliveryFee() {
    final fee = (_calculateWaterCost() * 0.1).round();
    return fee < 500 ? 500 : fee;
  }

  int _calculateTotalPrice() {
    return _calculateWaterCost() + _calculateDeliveryFee();
  }

  String _getDeliveryAddress() {
    if (_useAlternativeAddress) {
      String address = '';
      if (_streetController.text.isNotEmpty) address += _streetController.text;
      if (_houseController.text.isNotEmpty) {
        address += address.isNotEmpty
            ? ', House ${_houseController.text}'
            : 'House ${_houseController.text}';
      }
      if (_landmarkController.text.isNotEmpty) {
        address += address.isNotEmpty
            ? ' (Near ${_landmarkController.text})'
            : 'Near ${_landmarkController.text}';
      }
      if (_notesController.text.isNotEmpty) {
        address += address.isNotEmpty
            ? ' - ${_notesController.text}'
            : _notesController.text;
      }
      return address.isNotEmpty ? address : 'Address not specified';
    } else {
      String address = _savedStreetName;
      if (_savedHouseNumber.isNotEmpty) {
        address += address.isNotEmpty
            ? ', House $_savedHouseNumber'
            : 'House $_savedHouseNumber';
      }
      if (_savedLandmark.isNotEmpty) {
        address += address.isNotEmpty
            ? ' (Near $_savedLandmark)'
            : 'Near $_savedLandmark';
      }
      return address.isNotEmpty ? address : 'Default delivery address';
    }
  }

  // ==================== VENDOR FILTERING ====================
  List<Map<String, dynamic>> _getFilteredVendors() {
    final homeController = Provider.of<HomeController>(context, listen: false);
    final vendors = homeController.availableVendors;

    if (vendors.isEmpty) return [];

    return vendors.where((vendor) {
      final vehicleType = vendor['vehicle_type'] as String? ?? 'medium_truck';
      final vehicleInfo = _vehicleTypes[vehicleType];
      if (vehicleInfo == null) return false;

      final minCapacity = vehicleInfo['min'] as int;
      final maxCapacity = vehicleInfo['max'] as int;
      final withinCapacity =
          _selectedQuantity >= minCapacity && _selectedQuantity <= maxCapacity;

      // Check if vendor serves this customer's district
      final serviceAreas = vendor['service_areas'] as List? ?? [];
      final servesDistrict = serviceAreas.isEmpty ||
          (_selectedDistrictId != null && serviceAreas.contains(_selectedDistrictId));

      // Check truck accessibility
      final truckAccess = _savedTruckAccess || vehicleType == 'towable';

      return withinCapacity && servesDistrict && truckAccess;
    }).toList();
  }

  // ==================== ORDER PLACEMENT ====================
  Future<void> _placeOrder() async {
    if (_selectedVendor == null) {
      _showSnackBar(_translate('please_select_vendor'), Colors.red);
      return;
    }

    if (_useAlternativeAddress && _streetController.text.isEmpty) {
      _showSnackBar(_translate('please_enter_street'), Colors.red);
      return;
    }

    if (_customerId == null) {
      _showSnackBar(_translate('please_login_to_order'), Colors.red);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
      });
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final totalPrice = _calculateTotalPrice().toDouble();
      final deliveryAddress = _getDeliveryAddress();

      final order = await _orderService.createOrder(
        customerId: _customerId!,
        vendorId: _selectedVendorId!,
        waterType: 'Fresh Water', // Single water type
        quantity: _selectedQuantity,
        totalPrice: totalPrice,
        deliveryAddress: deliveryAddress,
        paymentMethod: 'mobile_money', // Force mobile money
      );

      if (order != null && mounted) {
        _showSuccessDialog(order);
      } else if (mounted) {
        _showSnackBar(_translate('order_failed'), Colors.red);
      }
    } catch (e) {
      print('Order placement error: $e');
      if (mounted) {
        _showSnackBar('${_translate('error')}: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  void _showSuccessDialog(OrderModel order) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final isSwahili = languageProvider.currentLocale.languageCode == 'sw';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(Icons.check_circle,
                  color: Colors.green.shade600, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              isSwahili ? 'ODA IMEWEKWA!' : 'ORDER PLACED!',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              '${isSwahili ? 'Namba ya Oda' : 'Order #'}: ${order.id.substring(0, 8).toUpperCase()}',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              isSwahili
                  ? 'Utalipa kwa M-Pesa baada ya vendor kuthibitisha uwasilishaji'
                  : 'You will pay via M-Pesa after vendor confirms delivery',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.blue.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child:
                Text(isSwahili ? 'SAWA' : 'OK', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.orderTracking,
                  arguments: order.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isSwahili ? 'FUATILIA ODA' : 'TRACK ORDER',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3)),
    );
  }

  // ==================== LOCALIZATION ====================
  String _translate(String key) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final isSwahili = languageProvider.currentLocale.languageCode == 'sw';

    final translations = {
      'please_select_vendor':
          isSwahili ? 'Tafadhali chagua mtoa huduma' : 'Please select a vendor',
      'please_enter_street': isSwahili
          ? 'Tafadhali weka jina la mtaa'
          : 'Please enter street name',
      'please_login_to_order': isSwahili
          ? 'Tafadhali ingia ili kuweka oda'
          : 'Please login to place order',
      'order_failed': isSwahili
          ? 'Imeshindwa kuweka oda. Jaribu tena.'
          : 'Failed to place order. Please try again.',
      'error': isSwahili ? 'Hitilafu' : 'Error',
      'order_water': isSwahili ? 'Oda Maji Yako' : 'Order Your Water',
      'place_order': isSwahili ? 'WEKA ODA' : 'PLACE ORDER',
    };

    return translations[key] ?? key;
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  // ==================== UI BUILDING ====================
  @override
  Widget build(BuildContext context) {
    final isSwahili =
        Provider.of<LanguageProvider>(context).currentLocale.languageCode ==
            'sw';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _isPlacingOrder
          ? const LoadingIndicator(message: 'Placing your order...')
          : _isLoadingProfile
              ? const LoadingIndicator(message: 'Loading your profile...')
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeader(isSwahili),
                      const SizedBox(height: 8),
                      _buildQuantitySection(isSwahili),
                      _buildVendorSection(isSwahili),
                      _buildLocationSection(isSwahili),
                      _buildPaymentInfoSection(isSwahili),
                      _buildOrderSummary(isSwahili),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(bool isSwahili) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSwahili ? 'Oda Maji Yako' : 'Order Your Water',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isSwahili
                          ? 'Maji safi yafika mlangoni kwako'
                          : 'Clean water delivered to your door',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(25),
                ),
                child:
                    const Icon(Icons.water_drop, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Customer location display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  _customerDistrictName.isNotEmpty
                      ? '$_customerWardName, $_customerDistrictName'
                      : isSwahili ? 'Mahali haijachaguliwa' : 'Location not set',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySection(bool isSwahili) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.production_quantity_limits,
                      color: Colors.green.shade700),
                ),
                const SizedBox(width: 12),
                Text(
                  isSwahili ? 'Kiasi cha Maji (Lita)' : 'Water Quantity (Liters)',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Modern quantity slider with visual feedback
            Column(
              children: [
                // Animated quantity display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.blue.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _selectedQuantity.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},'),
                        style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        isSwahili ? 'Lita' : 'Liters',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Quantity slider
                Slider(
                  value: _selectedQuantity.toDouble(),
                  min: 10,
                  max: 20000,
                  divisions: 200,
                  label: '$_selectedQuantity L',
                  activeColor: Colors.blue.shade700,
                  inactiveColor: Colors.grey.shade300,
                  onChanged: (value) {
                    setState(() {
                      _selectedQuantity = value.round();
                      _selectedVendor = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Quick quantity chips
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [20, 40, 100, 200, 500, 1000, 2000, 5000, 10000]
                      .map((quantity) {
                    final isSelected = _selectedQuantity == quantity;
                    return FilterChip(
                      label: Text('${quantity}L'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedQuantity = quantity;
                            _selectedVendor = null;
                          });
                        }
                      },
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: Colors.blue.shade600,
                      labelStyle: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Custom quantity input
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isSwahili ? 'Kiasi maalum' : 'Custom quantity',
                          hintText: isSwahili ? 'Weka lita' : 'Enter liters',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          prefixIcon: const Icon(Icons.edit, size: 20),
                        ),
                        onFieldSubmitted: (value) {
                          final quantity = int.tryParse(value);
                          if (quantity != null && quantity >= 10 && quantity <= 20000) {
                            setState(() {
                              _selectedQuantity = quantity;
                              _selectedVendor = null;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        final quantity = int.tryParse(_quantityController.text);
                        if (quantity != null && quantity >= 10 && quantity <= 20000) {
                          setState(() {
                            _selectedQuantity = quantity;
                            _selectedVendor = null;
                          });
                        } else {
                          _showSnackBar(
                            isSwahili ? 'Weka kiasi sahihi (10-20000 Lita)' : 'Enter valid quantity (10-20000 Liters)',
                            Colors.red,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isSwahili ? 'Weka' : 'Set',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorSection(bool isSwahili) {
    final filteredVendors = _getFilteredVendors();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.delivery_dining,
                      color: Colors.orange.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isSwahili ? 'Wenye Huduma Karibu Nawe' : 'Vendors Near You',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_customerDistrictName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _customerDistrictName,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isSwahili
                  ? 'Wenye huduma wanaohudumia eneo lako'
                  : 'Vendors that serve your area',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingVendors)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filteredVendors.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.store_outlined,
                        color: Colors.orange.shade600, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      isSwahili
                          ? 'Hakuna Mtoa Huduma Katika Eneo Lako'
                          : 'No Vendors in Your Area',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSwahili
                          ? 'Jaribu kiasi kingine cha maji au wasiliana nasi'
                          : 'Try a different water quantity or contact us',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredVendors.length,
                itemBuilder: (context, index) {
                  final vendor = filteredVendors[index];
                  final vehicleType =
                      vendor['vehicle_type'] as String? ?? 'medium_truck';
                  final vehicleInfo = _vehicleTypes[vehicleType] ??
                      _vehicleTypes['medium_truck']!;
                  final isSelected = _selectedVendorId == vendor['id'];
                  final color = vehicleInfo['color'] as Color;

                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedVendorId = vendor['id'];
                      _selectedVendor = vendor;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(vehicleInfo['icon'] as IconData,
                                color: color, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vendor['business_name'] ?? 'Unknown Vendor',
                                  style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.star,
                                        size: 14, color: Colors.amber.shade700),
                                    const SizedBox(width: 4),
                                    Text('${vendor['rating'] ?? 0.0}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isSwahili
                                            ? vehicleInfo['name_sw'] as String
                                            : vehicleInfo['name'] as String,
                                        style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: color,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vehicleInfo['description'] as String,
                                  style: GoogleFonts.poppins(
                                      fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: color, size: 28),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(bool isSwahili) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.location_on, color: Colors.purple.shade700),
                ),
                const SizedBox(width: 12),
                Text(
                  isSwahili ? 'Mahali pa Kufikishia' : 'Delivery Location',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  RadioListTile<bool>(
                    title: Text(
                        isSwahili
                            ? 'Tumia anwani yangu'
                            : 'Use my saved address',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    subtitle: Text(
                        _savedStreetName.isNotEmpty
                            ? '$_savedStreetName, $_savedHouseNumber'
                            : isSwahili ? 'Hakuna anwani' : 'No address saved',
                        style: GoogleFonts.poppins(fontSize: 12)),
                    value: false,
                    groupValue: _useAlternativeAddress,
                    onChanged: (value) =>
                        setState(() => _useAlternativeAddress = value ?? false),
                    activeColor: Colors.blue,
                  ),
                  RadioListTile<bool>(
                    title: Text(
                        isSwahili
                            ? 'Tumia anwani nyingine'
                            : 'Use alternative address',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    subtitle: Text(
                        isSwahili
                            ? 'Toa mahali mbadala'
                            : 'Provide different location',
                        style: GoogleFonts.poppins(fontSize: 12)),
                    value: true,
                    groupValue: _useAlternativeAddress,
                    onChanged: (value) =>
                        setState(() => _useAlternativeAddress = value ?? false),
                    activeColor: Colors.blue,
                  ),
                ],
              ),
            ),
            if (_useAlternativeAddress) ...[
              const SizedBox(height: 16),
              CustomTextField(
                label: isSwahili ? 'Jina la Mtaa' : 'Street Name',
                controller: _streetController,
                prefixIcon: Icons.location_on_outlined,
                hintText: 'e.g., Mtaa wa Kisutu',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: isSwahili ? 'Namba ya Jengo/Nyumba' : 'House Number',
                controller: _houseController,
                prefixIcon: Icons.home_outlined,
                hintText: 'e.g., House No. 45',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: isSwahili ? 'Mahali pa Kujulikana' : 'Landmark',
                controller: _landmarkController,
                prefixIcon: Icons.flag_outlined,
                hintText: 'e.g., Near Tanesco Office',
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label:
                    isSwahili ? 'Maelezo kwa Mtoa Huduma' : 'Notes for Vendor',
                controller: _notesController,
                prefixIcon: Icons.note_outlined,
                hintText: 'e.g., Truck can park on main road',
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoSection(bool isSwahili) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.payment, color: Colors.teal.shade700),
                ),
                const SizedBox(width: 12),
                Text(
                  isSwahili ? 'Njia ya Malipo' : 'Payment Method',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/icons/mpesa.png',
                      height: 30,
                      width: 30,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.phone_android,
                            color: Colors.green, size: 30);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSwahili ? 'M-Pesa' : 'M-Pesa',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          isSwahili
                              ? 'Utalipa baada ya vendor kuthibitisha uwasilishaji'
                              : 'You will pay after vendor confirms delivery',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: Colors.green, size: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(bool isSwahili) {
    final waterCost = _calculateWaterCost();
    final deliveryFee = _calculateDeliveryFee();
    final total = waterCost + deliveryFee;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              isSwahili ? 'MUHTASARI WA ODA' : 'ORDER SUMMARY',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
                isSwahili ? 'Kiasi' : 'Quantity', '$_selectedQuantity L'),
            _buildSummaryRow(isSwahili ? 'Gharama ya Maji' : 'Water Cost',
                'TZS ${_formatPrice(waterCost)}'),
            _buildSummaryRow(
                isSwahili ? 'Gharama ya Usafirishaji' : 'Delivery Fee',
                'TZS ${_formatPrice(deliveryFee)}'),
            const Divider(color: Colors.white, height: 24),
            _buildSummaryRow(
                isSwahili ? 'JUMLA' : 'TOTAL', 'TZS ${_formatPrice(total)}',
                isBold: true),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isSwahili
                    ? 'Malipo kwa M-Pesa baada ya uwasilishaji'
                    : 'Payment via M-Pesa after delivery confirmation',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: isSwahili ? 'WEKA ODA SASA' : 'PLACE ORDER NOW',
              onPressed: _selectedVendor != null ? _placeOrder : null,
              backgroundColor: Colors.white,
              textColor: Colors.blue.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.9))),
          Text(value,
              style: GoogleFonts.poppins(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.white,
              )),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4)),
      ],
    );
  }
}