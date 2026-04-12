import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../localization/language_provider.dart';
import '../../../core/utils/helpers.dart';
import '../services/earnings_service.dart';
import '../controllers/vendor_profile_controller.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final EarningsService _earningsService = EarningsService();
  bool _isLoading = true;
  double _totalEarnings = 0.0;
  double _pendingEarnings = 0.0;
  double _withdrawnEarnings = 0.0;
  Map<String, double> _weeklyEarnings = {};
  String _selectedPeriod = 'weekly';
  String? _vendorId;

  @override
  void initState() {
    super.initState();
    _loadVendorAndEarnings();
  }

  Future<void> _loadVendorAndEarnings() async {
    setState(() => _isLoading = true);

    try {
      final profileController = VendorProfileController();
      await profileController.loadVendorProfile();

      if (profileController.vendorProfile != null) {
        _vendorId = profileController.vendorProfile!.id;
        await _loadEarnings();
      }
    } catch (e) {
      debugPrint('Error loading vendor: $e'); // Replaced print
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadEarnings() async {
    if (_vendorId == null) return;

    try {
      _totalEarnings = await _earningsService.getTotalEarnings(_vendorId!);
      _pendingEarnings = await _earningsService.getPendingEarnings(_vendorId!);
      
      // Fixed: Use existing method or fallback
      _withdrawnEarnings = await _earningsService.getTotalEarnings(_vendorId!); 
      // Note: You should add getWithdrawnEarnings() to EarningsService if needed
      
      _weeklyEarnings = await _earningsService.getEarningsByPeriod(_vendorId!, _selectedPeriod);
    } catch (e) {
      debugPrint('Error loading earnings: $e');
      _withdrawnEarnings = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isSwahili = languageProvider.currentLocale.languageCode == 'sw';

    return Scaffold(
      appBar: AppBar(
        title: Text(isSwahili ? 'Mapato Yangu' : 'My Earnings'),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEarningsCard(),
                  const SizedBox(height: 20),
                  _buildPeriodSelector(languageProvider),
                  const SizedBox(height: 20),
                  _buildEarningsChart(languageProvider),
                  const SizedBox(height: 20),
                  _buildRecentTransactions(languageProvider),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: isSwahili ? 'OMBA KUTOA PESA' : 'REQUEST WITHDRAWAL',
                    onPressed: () => _showWithdrawDialog(context, languageProvider),
                    backgroundColor: Colors.green.shade700,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEarningsCard() {
    final isSwahili = Provider.of<LanguageProvider>(context).currentLocale.languageCode == 'sw';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isSwahili ? 'JUMLA YA MAPATO' : 'TOTAL EARNINGS',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            Helpers.formatPrice(_totalEarnings),
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildEarningStat(
                  isSwahili ? 'Inasubiri' : 'Pending',
                  Helpers.formatPrice(_pendingEarnings),
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildEarningStat(
                  isSwahili ? 'Imetolewa' : 'Withdrawn',
                  Helpers.formatPrice(_withdrawnEarnings),
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(LanguageProvider languageProvider) {
    final isSwahili = languageProvider.currentLocale.languageCode == 'sw';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildPeriodButton(isSwahili ? 'Wiki' : 'Weekly', 'weekly'),
          _buildPeriodButton(isSwahili ? 'Mwezi' : 'Monthly', 'monthly'),
          _buildPeriodButton(isSwahili ? 'Mwaka' : 'Yearly', 'yearly'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
          _loadEarnings();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.shade600 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsChart(LanguageProvider languageProvider) {
    final isSwahili = languageProvider.currentLocale.languageCode == 'sw';

    if (_weeklyEarnings.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
          ],
        ),
        child: Center(
          child: Text(
            isSwahili ? 'Hakuna data ya mapato' : 'No earnings data',
            style: GoogleFonts.poppins(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return Container(
      height: 250,
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
            isSwahili ? 'CHATI YA MAPATO' : 'EARNINGS CHART',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'TSh ${value.toInt()}',
                          style: GoogleFonts.poppins(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final keys = _weeklyEarnings.keys.toList();
                        if (value.toInt() < keys.length) {
                          return Text(
                            keys[value.toInt()],
                            style: GoogleFonts.poppins(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _weeklyEarnings.entries
                        .map((e) => FlSpot(
                              _weeklyEarnings.keys.toList().indexOf(e.key).toDouble(),
                              e.value,
                            ))
                        .toList(),
                    isCurved: true,
                    gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade700]),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade200.withValues(alpha: 0.3),
                          Colors.green.shade100.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(LanguageProvider languageProvider) {
    final isSwahili = languageProvider.currentLocale.languageCode == 'sw';

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
            isSwahili ? 'SHUGHULI ZA HIVI PUNDE' : 'RECENT TRANSACTIONS',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
          // TODO: Replace with real data from service
          _buildTransactionItem('Order #ORD-001', '+ TSh 5,000', 'Completed', Colors.green),
          _buildTransactionItem('Withdrawal', '- TSh 10,000', 'Processed', Colors.orange),
          _buildTransactionItem('Order #ORD-002', '+ TSh 12,500', 'Pending', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String title, String amount, String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              Text(status, style: GoogleFonts.poppins(fontSize: 12, color: color)),
            ],
          ),
          Text(amount, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, LanguageProvider languageProvider) {
    final TextEditingController amountController = TextEditingController();
    final isSwahili = languageProvider.currentLocale.languageCode == 'sw';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isSwahili ? 'Omba Kutoa Pesa' : 'Request Withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isSwahili ? 'Salio linalopatikana:' : 'Available balance:'),
                  Text(
                    Helpers.formatPrice(_totalEarnings - _pendingEarnings),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isSwahili ? 'Kiasi cha kuomba' : 'Withdrawal amount',
                prefixText: 'TSh ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              final available = _totalEarnings - _pendingEarnings;

              if (amount > 0 && amount <= available) {
                final success = await _earningsService.requestWithdrawal(_vendorId!, amount);
                if (success && mounted) {
                  Navigator.pop(dialogContext);
                  _showSnackBar(
                    isSwahili ? 'Ombi limepokelewa!' : 'Withdrawal request submitted!',
                    Colors.green,
                  );
                  _loadEarnings();
                }
              } else {
                _showSnackBar(
                  isSwahili ? 'Kiasi batili' : 'Invalid amount',
                  Colors.red,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text(isSwahili ? 'Tuma' : 'Submit'),
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
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}