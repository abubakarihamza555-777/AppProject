import 'package:flutter/material.dart';

class PaymentMonitoringScreen extends StatelessWidget {
  const PaymentMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Monitoring')),
      body: const Center(
        child: Text('Payment monitoring will appear here.'),
      ),
    );
  }
}
