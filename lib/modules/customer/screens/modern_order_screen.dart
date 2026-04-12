// lib/modules/customer/screens/modern_order_screen.dart
// FULLY RESPONSIVE - Works on all screen sizes (phones, tablets, foldables)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../localization/language_provider.dart';
import '../controllers/home_controller.dart';
import '../services/order_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/order_model.dart';

class ModernOrderScreen extends StatefulWidget {
  const ModernOrderScreen({super.key});

  @override
  State<ModernOrderScreen> createState() => _ModernOrderScreenState();
}

class _ModernOrderScreenState extends State<ModernOrderScreen>
    with TickerProviderStateMixin {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _houseController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _notesController = TextEditingController();
  final _quantityController = TextEditingController();
  
  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Order data
  int _selectedQuantity = 40;
  String? _selectedVendorId;
  Map<String, dynamic>? _selectedVendor;
  bool _useAlternativeAddress = false;
  bool _isPlacingOrder = false;
  String _selectedWaterType = 'Standard Purified Water';
  int _currentStep = 0;
  
  // Services
  final OrderService _orderService = OrderService();
  
  // Responsive variables
  late bool _isTablet;
  late bool _isSmallPhone;
  late double _screenWidth;
  late double _screenHeight;
  late EdgeInsets _screenPadding;
  
  // Water types
  final List<Map<String, dynamic>> _waterTypes = [
    {'name': 'Standard Purified Water', 'price_per_liter': 100, 'icon': Icons.water_drop, 'color': 0xFF2196F3},
    {'name': 'Mineral Water', 'price_per_liter': 150, 'icon': Icons.water, 'color': 0xFF4CAF50},
    {'name': 'Spring Water', 'price_per_liter': 200, 'icon': Icons.cleaning_services, 'color': 0xFF00BCD4},
    {'name': 'Premium Alkaline', 'price_per_liter': 250, 'icon': Icons.spa, 'color': 0xFF9C27B0},
  ];
  
  // Vehicle types
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

  // Step configuration
  final List<Map<String, dynamic>> _steps = [
    {'icon': Icons.water_drop, 'title': 'Water Type', 'color': 0xFF2196F3},
    {'icon': Icons.production_quantity_limits, 'title': 'Quantity', 'color': 0xFF4CAF50},
    {'icon': Icons.delivery_dining, 'title': 'Vendor', 'color': 0xFFFF9800},
    {'icon': Icons.location_on, 'title': 'Location', 'color': 0xFF9C27B0},
    {'icon': Icons.receipt, 'title': 'Summary', 'color': 0xFFF44336},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadVendors();
    _quantityController.text = _selectedQuantity.toString();
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

  Future<void> _loadVendors() async {
    final homeController = Provider.of<HomeController>(context, listen: false);
    await homeController.loadVendorsByLocation();
    setState(() {});
  }

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
      if (_houseController.text.isNotEmpty) address += ', House ${_houseController.text}';
      if (_landmarkController.text.isNotEmpty) address += ', Near ${_landmarkController.text}';
      if (_notesController.text.isNotEmpty) address += ' (${_notesController.text})';
      return address.isNotEmpty ? address : 'Address not specified';
    } else {
      final authController = context.read<AuthController>();
      return authController.currentUser?.address ?? 'Default delivery address';
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedVendor == null) {
      _showSnackBar(_translate('please_select_vendor'), Colors.red);
      return;
    }

    if (_useAlternativeAddress && _streetController.text.isEmpty) {
      _showSnackBar(_translate('please_enter_street'), Colors.red);
      return;
    }

    final authController = context.read<AuthController>();
    final customerId = authController.currentUser?.id;
    
    if (customerId == null) {
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
        customerId: customerId,
        vendorId: _selectedVendorId!,
        waterType: _selectedWaterType,
        quantity: _selectedQuantity,
        totalPrice: totalPrice,
        deliveryAddress: deliveryAddress,
        paymentMethod: 'cash',
      );

      if (order != null && mounted) {
        _showSuccessDialog(order);
      } else if (mounted) {
        _showSnackBar(_translate('order_failed'), Colors.red);
      }
    } catch (e) {
      if (mounted) _showSnackBar('${_translate('error')}: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  void _showSuccessDialog(OrderModel order) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
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
              child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              isSwahili ? 'ODA IMEWEKWA!' : 'ORDER PLACED!',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              '${isSwahili ? 'Namba ya Oda' : 'Order #'}: ${order.id.substring(0, 8).toUpperCase()}',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(isSwahili ? 'SAWA' : 'OK', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.orderTracking, arguments: order.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isSwahili ? 'FUATILIA ODA' : 'TRACK ORDER', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 3)),
    );
  }

  String _translate(String key) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isSwahili = languageProvider.currentLocale.languageCode == 'sw';
    
    final translations = {
      'please_select_vendor': isSwahili ? 'Tafadhali chagua mtoa huduma' : 'Please select a vendor',
      'please_enter_street': isSwahili ? 'Tafadhali weka jina la mtaa' : 'Please enter street name',
      'please_login_to_order': isSwahili ? 'Tafadhali ingia ili kuweka oda' : 'Please login to place order',
      'order_failed': isSwahili ? 'Imeshindwa kuweka oda. Jaribu tena.' : 'Failed to place order. Please try again.',
      'error': isSwahili ? 'Hitilafu' : 'Error',
      'order_water': isSwahili ? 'Oda Maji Yako' : 'Order Your Water',
      'quantity': isSwahili ? 'Kiasi' : 'Quantity',
      'liters': isSwahili ? 'Lita' : 'Liters',
      'water_type': isSwahili ? 'Aina ya Maji' : 'Water Type',
      'delivery_location': isSwahili ? 'Mahali pa Kufikishia' : 'Delivery Location',
      'order_summary': isSwahili ? 'Muhtasari wa Oda' : 'Order Summary',
      'water_cost': isSwahili ? 'Gharama ya Maji' : 'Water Cost',
      'delivery_fee': isSwahili ? 'Gharama ya Usafirishaji' : 'Delivery Fee',
      'total': isSwahili ? 'JUMLA' : 'TOTAL',
      'place_order': isSwahili ? 'WEKA ODA' : 'PLACE ORDER',
      'select_vendor': isSwahili ? 'Chagua Mtoa Huduma' : 'Select Vendor',
      'alternative_address': isSwahili ? 'Tumia anwani nyingine' : 'Use alternative address',
      'saved_address': isSwahili ? 'Tumia anwani yangu iliyosajiliwa' : 'Use my saved address',
      'street_name': isSwahili ? 'Jina la Mtaa' : 'Street Name',
      'house_number': isSwahili ? 'Namba ya Jengo/Nyumba' : 'House/Building Number',
      'landmark': isSwahili ? 'Mahali pa Kujulikana' : 'Landmark',
      'notes': isSwahili ? 'Maelezo kwa Mtoa Huduma' : 'Notes for Vendor',
      'next': isSwahili ? 'ENDAYE' : 'NEXT',
      'back': isSwahili ? 'RUDI' : 'BACK',
      'continue_to_payment': isSwahili ? 'ENDAYE KWA MALIPO' : 'CONTINUE TO PAYMENT',
      'select_water_type': isSwahili ? 'Chagua Aina ya Maji' : 'Select Water Type',
      'select_quantity': isSwahili ? 'Chagua Kiasi' : 'Select Quantity',
      'select_vendor_title': isSwahili ? 'Chagua Mtoa Huduma' : 'Select Vendor',
      'delivery_address': isSwahili ? 'Anwani ya Kufikishia' : 'Delivery Address',
      'review_order': isSwahili ? 'Kagua Oda Yako' : 'Review Your Order',
      'get_clean_water_delivered': isSwahili ? 'Pata maji safi yaliyotolewa' : 'Get clean water delivered',
    };
    
    return translations[key] ?? key;
  }

  List<Map<String, dynamic>> _getFilteredVendors() {
    final homeController = Provider.of<HomeController>(context, listen: false);
    final vendors = homeController.availableVendors;
    
    return vendors.where((vendor) {
      final vehicleType = vendor['vehicle_type'] as String? ?? 'medium_truck';
      final vehicleInfo = _vehicleTypes[vehicleType];
      if (vehicleInfo == null) return false;
      
      final minCapacity = vehicleInfo['min'] as int;
      final maxCapacity = vehicleInfo['max'] as int;
      return _selectedQuantity >= minCapacity && _selectedQuantity <= maxCapacity;
    }).toList();
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // ==================== RESPONSIVE UI BUILDING METHODS ====================

  @override
  Widget build(BuildContext context) {
    // Calculate responsive values
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;
    _isTablet = _screenWidth >= 600;
    _isSmallPhone = _screenWidth < 380;
    _screenPadding = EdgeInsets.symmetric(
      horizontal: _isTablet ? 32 : (_isSmallPhone ? 12 : 16),
      vertical: _isTablet ? 24 : 16,
    );
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isPlacingOrder
          ? const LoadingIndicator(message: 'Placing your order...')
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          _buildResponsiveHeader(),
                          _buildResponsiveStepper(),
                          Expanded(
                            child: Container(
                              padding: _screenPadding,
                              child: _buildCurrentStepContent(),
                            ),
                          ),
                          _buildResponsiveNavigationButtons(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildResponsiveHeader() {
    return Container(
      width: double.infinity,
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
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _isTablet ? 32 : 20,
            vertical: _isTablet ? 24 : 16,
          ),
          child: Row(
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
                      _translate('order_water'),
                      style: GoogleFonts.poppins(
                        fontSize: _isTablet ? 28 : (_isSmallPhone ? 20 : 24),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _translate('get_clean_water_delivered'),
                      style: GoogleFonts.poppins(
                        fontSize: _isTablet ? 14 : 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Water drop animation
              Container(
                width: _isTablet ? 60 : 50,
                height: _isTablet ? 60 : 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.water_drop,
                  color: Colors.white,
                  size: _isTablet ? 32 : 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveStepper() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isTablet ? 32 : 16,
        vertical: _isTablet ? 20 : 12,
      ),
      child: _isTablet
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_steps.length, (index) {
                return Expanded(
                  child: _buildStepIndicator(index),
                );
              }),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_steps.length, (index) {
                  return _buildStepIndicator(index);
                }),
              ),
            ),
    );
  }

  Widget _buildStepIndicator(int index) {
    final isActive = _currentStep >= index;
    final isCompleted = _currentStep > index;
    final step = _steps[index];
    final color = Color(step['color'] as int);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: _isTablet ? 56 : (_isSmallPhone ? 40 : 48),
            height: _isTablet ? 56 : (_isSmallPhone ? 40 : 48),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? color : Colors.grey.shade200,
              border: Border.all(
                color: isActive ? color : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? Icon(Icons.check, color: Colors.white, size: _isTablet ? 28 : 24)
                  : Icon(
                      step['icon'] as IconData,
                      color: isActive ? Colors.white : Colors.grey.shade400,
                      size: _isTablet ? 28 : 24,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          if (!_isSmallPhone || _isTablet)
            Text(
              step['title'] as String,
              style: GoogleFonts.poppins(
                fontSize: _isTablet ? 12 : 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? color : Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildWaterTypeStep();
      case 1:
        return _buildQuantityStep();
      case 2:
        return _buildVendorStep();
      case 3:
        return _buildLocationStep();
      case 4:
        return _buildOrderSummaryStep();
      default:
        return _buildWaterTypeStep();
    }
  }

  Widget _buildWaterTypeStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _translate('select_water_type'),
            style: GoogleFonts.poppins(
              fontSize: _isTablet ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the quality of water you prefer',
            style: GoogleFonts.poppins(
              fontSize: _isTablet ? 14 : 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = _isTablet 
                  ? (constraints.maxWidth > 800 ? 4 : 3)
                  : (constraints.maxWidth > 500 ? 2 : 1);
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: _waterTypes.length,
                itemBuilder: (context, index) {
                  final type = _waterTypes[index];
                  final isSelected = _selectedWaterType == type['name'];
                  final color = Color(type['color'] as int);
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedWaterType = type['name']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [color, color.withValues(alpha: 0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            type['icon'] as IconData,
                            color: isSelected ? Colors.white : color,
                            size: _isTablet ? 48 : 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            type['name'],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: _isTablet ? 14 : 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'TZS ${type['price_per_liter']}/L',
                            style: GoogleFonts.poppins(
                              fontSize: _isTablet ? 12 : 10,
                              color: isSelected ? Colors.white.withValues(alpha: 0.9) : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _translate('select_quantity'),
            style: GoogleFonts.poppins(
              fontSize: _isTablet ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How many liters of water do you need?',
            style: GoogleFonts.poppins(
              fontSize: _isTablet ? 14 : 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(_isTablet ? 24 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                // Quantity display
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _selectedQuantity.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                        style: GoogleFonts.poppins(
                          fontSize: _isTablet ? 56 : 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        _translate('liters'),
                        style: GoogleFonts.poppins(
                          fontSize: _isTablet ? 18 : 14,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Quantity controls
                Row(
                  children: [
                    Expanded(
                      child: _buildQuantityButton(
                        icon: Icons.remove,
                        color: Colors.red,
                        onTap: () {
                          setState(() {
                            if (_selectedQuantity > 10) {
                              _selectedQuantity -= 10;
                              _quantityController.text = _selectedQuantity.toString();
                              _selectedVendor = null;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: _isTablet ? 24 : 20, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onChanged: (value) {
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
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildQuantityButton(
                        icon: Icons.add,
                        color: Colors.green,
                        onTap: () {
                          setState(() {
                            if (_selectedQuantity < 20000) {
                              _selectedQuantity += 10;
                              _quantityController.text = _selectedQuantity.toString();
                              _selectedVendor = null;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Quick quantity chips
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [20, 40, 100, 200, 500, 1000, 2000, 5000, 10000].map((quantity) {
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
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                      shape: const StadiumBorder(side: BorderSide.none),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: _isTablet ? 32 : 28),
      ),
    );
  }

  Widget _buildVendorStep() {
    final filteredVendors = _getFilteredVendors();
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _translate('select_vendor_title'),
            style: GoogleFonts.poppins(
              fontSize: _isTablet ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a water delivery vendor near you',
            style: GoogleFonts.poppins(
              fontSize: _isTablet ? 14 : 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          if (filteredVendors.isEmpty)
            Container(
              padding: EdgeInsets.all(_isTablet ? 40 : 30),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.orange.shade600, size: _isTablet ? 64 : 48),
                  const SizedBox(height: 16),
                  Text(
                    'No vendors available for $_selectedQuantity L',
                    style: GoogleFonts.poppins(
                      fontSize: _isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try a different quantity or check back later',
                    style: GoogleFonts.poppins(
                      fontSize: _isTablet ? 14 : 12,
                      color: Colors.grey.shade600,
                    ),
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
                final vehicleType = vendor['vehicle_type'] as String? ?? 'medium_truck';
                final vehicleInfo = _vehicleTypes[vehicleType] ?? _vehicleTypes['medium_truck']!;
                final isSelected = _selectedVendorId == vendor['id'];
                final color = vehicleInfo['color'] as Color;
                
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedVendorId = vendor['id'];
                    _selectedVendor = vendor;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(_isTablet ? 20 : 16),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(vehicleInfo['icon'] as IconData, color: color, size: _isTablet ? 32 : 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vendor['business_name'] ?? 'Unknown Vendor',
                                style: GoogleFonts.poppins(
                                  fontSize: _isTablet ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 14, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${vendor['rating'] ?? 0.0}',
                                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      vehicleInfo['name'] as String,
                                      style: GoogleFonts.poppins(fontSize: 10, color: color),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Capacity: ${vehicleInfo['capacity']}',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: color, size: _isTablet ? 32 : 28),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _translate('delivery_address'),
            style: GoogleFonts.poppins(
              fontSize: _isTablet ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Where should we deliver your water?',
            style: GoogleFonts.poppins(
              fontSize: _isTablet ? 14 : 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(_isTablet ? 24 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                _buildAddressOption(
                  title: _translate('saved_address'),
                  subtitle: 'Use your registered address',
                  value: false,
                  groupValue: _useAlternativeAddress,
                  onChanged: (value) => setState(() => _useAlternativeAddress = value ?? false),
                ),
                _buildAddressOption(
                  title: _translate('alternative_address'),
                  subtitle: 'Provide a different delivery location',
                  value: true,
                  groupValue: _useAlternativeAddress,
                  onChanged: (value) => setState(() => _useAlternativeAddress = value ?? false),
                ),
                if (_useAlternativeAddress) ...[
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: _translate('street_name'),
                    controller: _streetController,
                    prefixIcon: Icons.location_on_outlined,
                    hintText: 'e.g., Mtaa wa Kisutu',
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: _translate('house_number'),
                    controller: _houseController,
                    prefixIcon: Icons.home_outlined,
                    hintText: 'e.g., House No. 45',
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: _translate('landmark'),
                    controller: _landmarkController,
                    prefixIcon: Icons.flag_outlined,
                    hintText: 'e.g., Near Tanesco Office',
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: _translate('notes'),
                    controller: _notesController,
                    prefixIcon: Icons.note_outlined,
                    hintText: 'e.g., Truck can park on the main road',
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressOption({
    required String title,
    required String subtitle,
    required bool value,
    required bool groupValue,
    required Function(bool?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: groupValue == value ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: groupValue == value ? Colors.blue : Colors.grey.shade200,
          width: groupValue == value ? 2 : 1,
        ),
      ),
      child: RadioListTile<bool>(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12)),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: Colors.blue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildOrderSummaryStep() {
    final waterCost = _calculateWaterCost();
    final deliveryFee = _calculateDeliveryFee();
    final finalTotal = waterCost + deliveryFee;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _translate('review_order'),
            style: GoogleFonts.poppins(
              fontSize: _isTablet ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review your order details before placing',
            style: GoogleFonts.poppins(
              fontSize: _isTablet ? 14 : 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(_isTablet ? 24 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                _buildSummaryItem(
                  icon: Icons.water_drop,
                  title: 'Water Type',
                  value: _selectedWaterType,
                  color: 0xFF2196F3,
                ),
                _buildSummaryItem(
                  icon: Icons.production_quantity_limits,
                  title: 'Quantity',
                  value: '$_selectedQuantity Liters',
                  color: 0xFF4CAF50,
                ),
                if (_selectedVendor != null)
                  _buildSummaryItem(
                    icon: Icons.business,
                    title: 'Vendor',
                    value: _selectedVendor!['business_name'] ?? 'Unknown',
                    color: 0xFFFF9800,
                  ),
                _buildSummaryItem(
                  icon: Icons.location_on,
                  title: 'Delivery Address',
                  value: _getDeliveryAddress(),
                  color: 0xFF9C27B0,
                  isLongText: true,
                ),
                const Divider(height: 32),
                _buildPriceRow('Water Cost', 'TZS ${_formatPrice(waterCost)}'),
                _buildPriceRow('Delivery Fee', 'TZS ${_formatPrice(deliveryFee)}'),
                const Divider(height: 24, thickness: 2),
                _buildPriceRow('TOTAL AMOUNT', 'TZS ${_formatPrice(finalTotal)}', isBold: true, isTotal: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
    required int color,
    bool isLongText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Color(color), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: isLongText ? 12 : 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: isLongText ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.blue.shade700 : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.blue.shade700 : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveNavigationButtons() {
    final isLastStep = _currentStep == _steps.length - 1;
    
    return Container(
      padding: EdgeInsets.all(_isTablet ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep--),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: _isTablet ? 16 : 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: Text(
                    _translate('back'),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  if (isLastStep) {
                    _placeOrder();
                  } else {
                    setState(() => _currentStep++);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastStep ? Colors.green.shade600 : Colors.blue.shade600,
                  padding: EdgeInsets.symmetric(vertical: _isTablet ? 16 : 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  isLastStep ? _translate('place_order') : _translate('next'),
                  style: GoogleFonts.poppins(
                    fontSize: _isTablet ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
