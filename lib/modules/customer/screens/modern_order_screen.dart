import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../controllers/home_controller.dart';

class ModernOrderScreen extends StatefulWidget {
  const ModernOrderScreen({super.key});

  @override
  State<ModernOrderScreen> createState() => _ModernOrderScreenState();
}

class _ModernOrderScreenState extends State<ModernOrderScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _houseController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _notesController = TextEditingController();
  final _quantityController = TextEditingController();
  
  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _selectedQuantity = 40;
  String? _selectedVendorId;
  Map<String, dynamic>? _selectedVendor;
  bool _useAlternativeAddress = false;
  
  // Vehicle type icons and colors
  final Map<String, Map<String, dynamic>> _vehicleTypes = {
    'towable': {
      'icon': Icons.agriculture,
      'color': Colors.green,
      'name': 'Towable Browser',
      'capacity': '400-2000L'
    },
    'medium_truck': {
      'icon': Icons.local_shipping,
      'color': Colors.blue,
      'name': 'Medium Truck',
      'capacity': '3000-5000L'
    },
    'heavy_truck': {
      'icon': Icons.airport_shuttle,
      'color': Colors.orange,
      'name': 'Heavy Duty Truck',
      'capacity': '8000-16000L'
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    _loadVendors();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
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
  }

  bool _isVendorCapacitySufficient(Map<String, dynamic> vendor, int requiredLiters) {
    final vehicleType = vendor['vehicle_type'] as String;
    final capacities = {
      'towable': [400, 2000],
      'medium_truck': [3000, 5000],
      'heavy_truck': [8000, 16000],
    };
    
    final capacityRange = capacities[vehicleType] ?? [0, 0];
    return requiredLiters >= capacityRange[0] && requiredLiters <= capacityRange[1];
  }

  List<Map<String, dynamic>> _getFilteredVendors() {
    final homeController = Provider.of<HomeController>(context, listen: false);
    final vendors = homeController.availableVendors;
    
    return vendors.where((vendor) {
      return _isVendorCapacitySufficient(vendor, _selectedQuantity);
    }).toList();
  }

  Widget _buildModernHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Oda Maji Yako',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Pata maji safi na salama kwa haraka',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantitySection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.water_drop, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Kiasi cha Maji',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Modern quantity selector
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
                        Text(
                          'Lita Unazohitaji',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '$_selectedQuantity L',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (_selectedQuantity > 10) {
                                  _selectedQuantity -= 10;
                                  _selectedVendorId = null;
                                  _selectedVendor = null;
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: const Icon(Icons.remove, color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              hintText: '$_selectedQuantity',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (value) {
                              final quantity = int.tryParse(value);
                              if (quantity != null && quantity > 0) {
                                setState(() {
                                  _selectedQuantity = quantity;
                                  _selectedVendorId = null;
                                  _selectedVendor = null;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedQuantity += 10;
                                _selectedVendorId = null;
                                _selectedVendor = null;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: const Icon(Icons.add, color: Colors.green),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Quick quantity buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [20, 40, 100, 200, 500, 1000].map((quantity) {
                  final isSelected = _selectedQuantity == quantity;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedQuantity = quantity;
                        _selectedVendorId = null;
                        _selectedVendor = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade600 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        '${quantity}L',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Price display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bei ya Kiasi',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      'TSh ${(_selectedQuantity * 100).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVendorSection() {
    final filteredVendors = _getFilteredVendors();
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
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
                    child: Icon(Icons.delivery_dining, color: Colors.orange.shade700),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Wenye Huduma Wenye Uwezo',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              if (filteredVendors.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Hakuna Mtoa Huduma',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hakuna vendor anayeweza kubeba $_selectedQuantity lita kwa sasa. Tafadhali badilisha kiasi.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: filteredVendors.map((vendor) {
                    final vehicleType = vendor['vehicle_type'] as String;
                    final vehicleInfo = _vehicleTypes[vehicleType] ?? _vehicleTypes['medium_truck']!;
                    final isSelected = _selectedVendorId == vendor['id'];
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedVendorId = vendor['id'];
                          _selectedVendor = vendor;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? vehicleInfo['color'].withValues(alpha: 0.1) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? vehicleInfo['color'] : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: vehicleInfo['color'].withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    vehicleInfo['icon'],
                                    color: vehicleInfo['color'],
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vendor['business_name'] ?? 'Unknown Vendor',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      Text(
                                        vendor['users']['full_name'] ?? 'Vendor Name',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: vehicleInfo['color'],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildVendorInfoChip(
                                    vehicleInfo['icon'],
                                    vehicleInfo['name'],
                                    vehicleInfo['color'],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildVendorInfoChip(
                                    Icons.water_drop,
                                    vehicleInfo['capacity'],
                                    vehicleInfo['color'],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildVendorInfoChip(
                                    Icons.star,
                                    '${vendor['rating'] ?? 0.0} ★',
                                    Colors.amber,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildVendorInfoChip(
                                    Icons.local_shipping,
                                    '${vendor['total_deliveries'] ?? 0} orders',
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVendorInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
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
                    child: Icon(Icons.location_on, color: Colors.green.shade700),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Mahali pa Kufikishia',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Address selection
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        'Tumia anwani yangu iliyosajiliwa',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Inatumia anwani ya kawaida ya kupelekea',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      trailing: Radio<bool>(
                        value: false,
                        groupValue: _useAlternativeAddress,
                        onChanged: (value) {
                          setState(() {
                            _useAlternativeAddress = value!;
                          });
                        },
                        fillColor: WidgetStateProperty.all(Colors.green.shade600),
                      ),
                      onTap: () {
                        setState(() {
                          _useAlternativeAddress = false;
                        });
                      },
                    ),
                    
                    ListTile(
                      title: Text(
                        'Tumia anwani nyingine',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Toa mahali mbadala pa kufikishia',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      trailing: Radio<bool>(
                        value: true,
                        groupValue: _useAlternativeAddress,
                        onChanged: (value) {
                          setState(() {
                            _useAlternativeAddress = value!;
                          });
                        },
                        fillColor: WidgetStateProperty.all(Colors.green.shade600),
                      ),
                      onTap: () {
                        setState(() {
                          _useAlternativeAddress = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              if (_useAlternativeAddress) ...[
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Jina la Mtaa',
                  controller: _streetController,
                  prefixIcon: Icons.location_on_outlined,
                  hintText: 'Mfano: Mtaa wa Kisutu - Main Road',
                  validator: (value) {
                    if (_useAlternativeAddress && (value == null || value.isEmpty)) {
                      return 'Tafadhali jaza jina la mtaa';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 12),
                
                CustomTextField(
                  label: 'Mahali Pa Kujulikana',
                  controller: _landmarkController,
                  prefixIcon: Icons.flag_outlined,
                  hintText: 'Mfano: Karibu na Tanesco pole',
                  validator: (value) {
                    if (_useAlternativeAddress && (value == null || value.isEmpty)) {
                      return 'Tafadhali jaza mahali pa kujulikana';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 12),
                
                CustomTextField(
                  label: 'Namba ya Jengo/Nyumba',
                  controller: _houseController,
                  prefixIcon: Icons.home_outlined,
                  hintText: 'Mfano: House No. 45',
                  validator: (value) {
                    if (_useAlternativeAddress && (value == null || value.isEmpty)) {
                      return 'Tafadhali jaza namba ya jengo';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 12),
                
                CustomTextField(
                  label: 'Maelezo kwa Mtoa Huduma (Hiari)',
                  controller: _notesController,
                  prefixIcon: Icons.note_outlined,
                  hintText: 'Mfano: Lori inaweza kusimama barabarani, nitaishiwa hapa',
                  maxLines: 3,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final totalPrice = _selectedQuantity * 100;
    final deliveryFee = (totalPrice * 0.1).round();
    final finalTotal = totalPrice + deliveryFee;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MUHTASARI WA ODA',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildSummaryRow('Kiasi cha Maji', '$_selectedQuantity Lita'),
              _buildSummaryRow('Bei ya Maji', 'TSh ${totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'),
              _buildSummaryRow('Gharama ya Usafirishaji (10%)', 'TSh ${deliveryFee.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'),
              const Divider(color: Colors.white),
              _buildSummaryRow('JUMLA', 'TSh ${finalTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}', isBold: true),
              
              if (_selectedVendor != null) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  'MTOA HUDUMA',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                _buildSummaryRow('Jina', _selectedVendor!['business_name']),
                _buildSummaryRow('Aina ya Gari', _vehicleTypes[_selectedVendor!['vehicle_type']]?['name'] ?? 'Unknown'),
              ],
              
              const SizedBox(height: 24),
              
              CustomButton(
                text: 'WEKA ODA SASA',
                onPressed: _selectedVendor != null ? _handlePlaceOrder : null,
                backgroundColor: Colors.white,
                textColor: Colors.blue.shade700,
              ),
            ],
          ),
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
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePlaceOrder() async {
    if (_selectedVendor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tafadhali chagua mtoa huduma',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.blue.shade600),
            const SizedBox(height: 16),
            Text(
              'Inaweka oda yako...',
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
      ),
    );

    // Simulate order placement
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.pop(context); // Close loading dialog
    }
    
    // Show success dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'ODA IMEWEKWA!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Order #: WTR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: Inatafuta vendor...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              if (mounted) {
                Navigator.pop(context); // Go back to home
              }
            },
            child: Text(
              'Sawa',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // TODO: Navigate to order tracking
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Fuatilia Oda',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildModernHeader(),
              _buildQuantitySection(),
              _buildVendorSection(),
              _buildLocationSection(),
              _buildOrderSummary(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
