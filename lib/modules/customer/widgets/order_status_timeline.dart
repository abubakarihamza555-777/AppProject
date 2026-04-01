import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../localization/language_provider.dart';

class OrderStatusTimeline extends StatelessWidget {
  final String currentStatus;
  
  const OrderStatusTimeline({
    super.key,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    final statuses = [
      {'key': 'pending', 'label': languageProvider.translate('pending'), 'icon': Icons.pending},
      {'key': 'confirmed', 'label': languageProvider.translate('confirmed'), 'icon': Icons.check_circle},
      {'key': 'preparing', 'label': languageProvider.translate('preparing'), 'icon': Icons.precision_manufacturing},
      {'key': 'delivered', 'label': languageProvider.translate('delivered'), 'icon': Icons.delivery_dining},
    ];
    
    int currentIndex = statuses.indexWhere((s) => s['key'] == currentStatus);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: List.generate(statuses.length, (index) {
                final status = statuses[index];
                final isCompleted = index <= currentIndex;
                
                return Expanded(
                  child: Column(
                    children: [
                      // Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                        ),
                        child: Icon(
                          status['icon'] as IconData,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Label
                      Text(
                        status['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                          color: isCompleted ? Theme.of(context).primaryColor : Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }),
            ),
            // Progress Line
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(statuses.length - 1, (index) {
                  final isCompleted = index < currentIndex;
                  return Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
