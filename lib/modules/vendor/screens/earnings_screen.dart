import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../localization/language_provider.dart';
import '../../../core/utils/helpers.dart';
import '../services/earnings_service.dart';
import '../widgets/earnings_chart.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final EarningsService _earningsService = EarningsService();
  bool _isLoading = true;
  double _totalEarnings = 0;
  double _pendingEarnings = 0;
  Map<String, double> _weeklyEarnings = {};
  String _selectedPeriod = 'weekly';

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _totalEarnings = await _earningsService.getTotalEarnings('temp_vendor_id');
      _pendingEarnings = await _earningsService.getPendingEarnings('temp_vendor_id');
      _weeklyEarnings = await _earningsService.getEarningsByPeriod('temp_vendor_id', _selectedPeriod);
    } catch (e) {
      print('Error loading earnings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('earnings')),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Total Earnings Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColorDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          languageProvider.translate('total_earnings'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Helpers.formatPrice(_totalEarnings),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${languageProvider.translate('pending')}: ${Helpers.formatPrice(_pendingEarnings)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Period Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _PeriodButton(
                        label: languageProvider.translate('weekly'),
                        isSelected: _selectedPeriod == 'weekly',
                        onTap: () {
                          setState(() {
                            _selectedPeriod = 'weekly';
                          });
                          _loadEarnings();
                        },
                      ),
                      _PeriodButton(
                        label: languageProvider.translate('monthly'),
                        isSelected: _selectedPeriod == 'monthly',
                        onTap: () {
                          setState(() {
                            _selectedPeriod = 'monthly';
                          });
                          _loadEarnings();
                        },
                      ),
                      _PeriodButton(
                        label: languageProvider.translate('yearly'),
                        isSelected: _selectedPeriod == 'yearly',
                        onTap: () {
                          setState(() {
                            _selectedPeriod = 'yearly';
                          });
                          _loadEarnings();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Earnings Chart
                  EarningsChart(
                    data: _weeklyEarnings,
                    period: _selectedPeriod,
                  ),
                  const SizedBox(height: 24),

                  // Withdraw Button
                  CustomButton(
                    text: languageProvider.translate('withdraw'),
                    onPressed: () => _showWithdrawDialog(context),
                  ),
                ],
              ),
            ),
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.translate('request_withdrawal')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${languageProvider.translate('available_balance')}: ${Helpers.formatPrice(_totalEarnings)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: languageProvider.translate('amount'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixText: 'TZS ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount <= _totalEarnings) {
                final success = await _earningsService.requestWithdrawal(
                  'temp_vendor_id',
                  amount,
                );
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Withdrawal request submitted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(languageProvider.translate('submit')),
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
} 
