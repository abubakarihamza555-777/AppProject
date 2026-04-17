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
  String _selectedWaterType = 'Standard Purified Water';
  String _selectedPaymentMethod = 'cash';
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

  // ==================== ANIMATIONS ====================
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ==================== WATER TYPES ====================
  final List<Map<String, dynamic>> _waterTypes = [
    {
      'name': 'Standard Purified Water',
      'price_per_liter': 100,
      'icon': Icons.water_drop,
      'color': 0xFF2196F3
    },
    {
      'name': 'Mineral Water',
      'price_per_liter': 150,
      'icon': Icons.water,
      'color': 0xFF4CAF50
    },
    {
      'name': 'Spring Water',
      'price_per_liter': 200,
      'icon': Icons.cleaning_services,
      'color': 0xFF00BCD4
    },
    {
      'name': 'Premium Alkaline',
      'price_per_liter': 250,
      'icon': Icons.spa,
      'color': 0xFF9C27B0
    },
  ];

  // ==================== VEHICLE TYPES ====================
  final Map<String, Map<String, dynamic>> _vehicleTypes = {
    'towable': {
      'icon': Icons.agriculture,
      'color': Colors.green,
      'name': 'Towable Browser',
      'capacity': '400-2000L',
      'min': 400,
      'max': 2000,
    },
    'medium_truck': {
      'icon': Icons.local_shipping,
      'color': Colors.blue,
      'name': 'Medium Truck',
      'capacity': '3000-5000L',
      'min': 3000,
      'max': 5000,
    },
    'heavy_truck': {
      'icon': Icons.airport_shuttle,
      'color': Colors.orange,
      'name': 'Heavy Duty Truck',
      'capacity': '8000-16000L',
      'min': 8000,
      'max': 16000,
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
  double _getWaterPricePerLiter() {
    final waterType = _waterTypes.firstWhere(
      (wt) => wt['name'] == _selectedWaterType,
      orElse: () => _waterTypes[0],
    );
    return (waterType['price_per_liter'] as num).toDouble();
  }

  int _calculateWaterCost() {
    return (_selectedQuantity * _getWaterPricePerLiter()).round();
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

      // Also check truck accessibility
      final truckAccess = _savedTruckAccess || vehicleType == 'towable';

      return withinCapacity && truckAccess;
    }).toList();
  }

  // ==================== ORDER PLACEMENT ====================
  Future<void> _placeOrder() async {
    // Validate
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
        waterType: _selectedWaterType,
        quantity: _selectedQuantity,
        totalPrice: totalPrice,
        deliveryAddress: deliveryAddress,
        paymentMethod: _selectedPaymentMethod,
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
                  ? 'Utapata taarifa kwa simu yako'
                  : 'You will receive SMS confirmation',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey.shade500),
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
                      _buildWaterTypeSection(isSwahili),
                      _buildQuantitySection(isSwahili),
                      _buildVendorSection(isSwahili),
                      _buildLocationSection(isSwahili),
                      _buildPaymentSection(isSwahili),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                        fontSize: 24,
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
        ],
      ),
    );
  }

  Widget _buildWaterTypeSection(bool isSwahili) {
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
                    color: Colors.cyan.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.water_drop, color: Colors.cyan.shade700),
                ),
                const SizedBox(width: 12),
                Text(
                  isSwahili ? 'Aina ya Maji' : 'Water Type',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _waterTypes.length,
                itemBuilder: (context, index) {
                  final type = _waterTypes[index];
                  final isSelected = _selectedWaterType == type['name'];
                  final color = Color(type['color'] as int);
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedWaterType = type['name']),
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(type['icon'] as IconData,
                              color: isSelected ? color : Colors.grey,
                              size: 28),
                          const SizedBox(height: 8),
                          Text(
                            type['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? color : Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'TZS ${type['price_per_liter']}/L',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: isSelected ? color : Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySection(bool isSwahili) {
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
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.production_quantity_limits,
                      color: Colors.green.shade700),
                ),
                const SizedBox(width: 12),
                Text(
                  isSwahili ? 'Kiasi cha Maji' : 'Quantity',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isSwahili ? 'Lita Unazohitaji' : 'Liters Needed',
                          style:
                              GoogleFonts.poppins(color: Colors.grey.shade600)),
                      Text('$_selectedQuantity L',
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child:
                            _buildQuantityButton(Icons.remove, Colors.red, () {
                          setState(() {
                            if (_selectedQuantity > 10) {
                              _selectedQuantity -= 10;
                              _selectedVendor = null;
                            }
                          });
                        }),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (value) {
                            final quantity = int.tryParse(value);
                            if (quantity != null &&
                                quantity >= 10 &&
                                quantity <= 20000) {
                              setState(() {
                                _selectedQuantity = quantity;
                                _selectedVendor = null;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child:
                            _buildQuantityButton(Icons.add, Colors.green, () {
                          setState(() {
                            if (_selectedQuantity < 20000) {
                              _selectedQuantity += 10;
                              _selectedVendor = null;
                            }
                          });
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [20, 40, 100, 200, 500, 1000, 2000, 5000]
                        .map((quantity) {
                      final isSelected = _selectedQuantity == quantity;
                      return FilterChip(
                        label: Text('${quantity}L'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedQuantity = quantity;
                              _quantityController.text = quantity.toString();
                              _selectedVendor = null;
                            });
                          }
                        },
                        backgroundColor: Colors.grey.shade100,
                        selectedColor: Colors.blue.shade600,
                        labelStyle: GoogleFonts.poppins(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 28),
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
                Text(
                  isSwahili ? 'Chagua Mtoa Huduma' : 'Select Vendor',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
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
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade600, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      isSwahili ? 'Hakuna Mtoa Huduma' : 'No Vendors Available',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSwahili
                          ? 'Jaribu kiasi kingine cha maji'
                          : 'Try a different water quantity',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey.shade600),
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
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(vehicleInfo['icon'] as IconData,
                                color: color, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vendor['business_name'] ?? 'Unknown Vendor',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 12, color: Colors.amber),
                                    const SizedBox(width: 2),
                                    Text('${vendor['rating'] ?? 0.0}',
                                        style:
                                            GoogleFonts.poppins(fontSize: 10)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        vehicleInfo['name'] as String,
                                        style: GoogleFonts.poppins(
                                            fontSize: 10, color: color),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: color, size: 24),
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
                            ? _savedStreetName
                            : 'No saved address',
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

  Widget _buildPaymentSection(bool isSwahili) {
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentOption(
                    icon: Icons.money,
                    title: isSwahili ? 'Pesa' : 'Cash',
                    subtitle: isSwahili ? 'Lipa unapopokea' : 'Pay on delivery',
                    isSelected: _selectedPaymentMethod == 'cash',
                    onTap: () =>
                        setState(() => _selectedPaymentMethod = 'cash'),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPaymentOption(
                    icon: Icons.phone_android,
                    title: isSwahili ? 'M-Pesa' : 'Mobile Money',
                    subtitle: isSwahili ? 'Lipa kwa simu' : 'Pay via mobile',
                    isSelected: _selectedPaymentMethod == 'mobile',
                    onTap: () =>
                        setState(() => _selectedPaymentMethod = 'mobile'),
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(title,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : Colors.grey.shade700)),
            Text(subtitle,
                style: GoogleFonts.poppins(
                    fontSize: 10, color: Colors.grey.shade500)),
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
                isSwahili ? 'Aina ya Maji' : 'Water Type', _selectedWaterType),
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
