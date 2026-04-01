import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../localization/language_provider.dart';
import '../widgets/vendor_card.dart';
import '../../vendor/models/vendor_model.dart';
import '../../vendor/services/vendor_service.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  List<VendorModel> _vendors = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'rating'; // rating, deliveries, name

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final vendorService = VendorService();
      _vendors = await vendorService.getAllVendors();
    } catch (e) {
      print('Error loading vendors: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<VendorModel> get _filteredVendors {
    var vendors = _vendors.where((vendor) {
      return vendor.businessName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
    
    if (_sortBy == 'rating') {
      vendors.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortBy == 'deliveries') {
      vendors.sort((a, b) => b.totalDeliveries.compareTo(a.totalDeliveries));
    } else {
      vendors.sort((a, b) => a.businessName.compareTo(b.businessName));
    }
    
    return vendors;
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('vendors')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: languageProvider.translate('search_vendors'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Sort Options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SortChip(
                  label: languageProvider.translate('top_rated'),
                  isSelected: _sortBy == 'rating',
                  onTap: () {
                    setState(() {
                      _sortBy = 'rating';
                    });
                  },
                ),
                _SortChip(
                  label: languageProvider.translate('most_deliveries'),
                  isSelected: _sortBy == 'deliveries',
                  onTap: () {
                    setState(() {
                      _sortBy = 'deliveries';
                    });
                  },
                ),
                _SortChip(
                  label: languageProvider.translate('name'),
                  isSelected: _sortBy == 'name',
                  onTap: () {
                    setState(() {
                      _sortBy = 'name';
                    });
                  },
                ),
              ],
            ),
          ),
          
          // Vendor List
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : _filteredVendors.isEmpty
                    ? Center(
                        child: Text(languageProvider.translate('no_vendors')),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredVendors.length,
                        itemBuilder: (context, index) {
                          return VendorCard(
                            vendor: _filteredVendors[index],
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/customer/request-water',
                                arguments: _filteredVendors[index],
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.grey.shade100,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
} 
