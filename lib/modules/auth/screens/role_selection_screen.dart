import 'package:flutter/material.dart';
import '../../../config/routes/app_routes.dart';
import '../../../shared/widgets/custom_button.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.all(
                    constraints.maxWidth < 360 ? 16.0 : 24.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.05),
                      
                      // App Logo/Icon
                      Icon(
                        Icons.water_drop,
                        size: constraints.maxWidth < 360 ? 40 : 50,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(height: constraints.maxHeight * 0.02),
                      
                      // Welcome Title
                      Text(
                        'WELCOME TO DAR WATER APP',
                        style: TextStyle(
                          fontSize: constraints.maxWidth < 360 ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: constraints.maxHeight * 0.01),
                      
                      const Text(
                        'Chagua aina ya akaunti unayotaka',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: constraints.maxHeight * 0.04),
                      
                      // Customer Option
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade300),
                          color: Colors.blue.shade50,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.register,
                              arguments: {'role': 'customer'},
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(
                              constraints.maxWidth < 360 ? 12.0 : 16.0,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: constraints.maxWidth < 360 ? 30 : 35,
                                  color: Colors.blue.shade700,
                                ),
                                SizedBox(height: constraints.maxHeight * 0.01),
                                Text(
                                  'I AM A CUSTOMER',
                                  style: TextStyle(
                                    fontSize: constraints.maxWidth < 360 ? 14 : 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 2),
                                const Text(
                                  'Nataka kununua maji',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: constraints.maxHeight * 0.02),
                      
                      // Vendor Option
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                          color: Colors.green.shade50,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.register,
                              arguments: {'role': 'vendor'},
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(
                              constraints.maxWidth < 360 ? 12.0 : 16.0,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.local_shipping,
                                  size: constraints.maxWidth < 360 ? 30 : 35,
                                  color: Colors.green.shade700,
                                ),
                                SizedBox(height: constraints.maxHeight * 0.01),
                                Text(
                                  'I AM A VENDOR',
                                  style: TextStyle(
                                    fontSize: constraints.maxWidth < 360 ? 14 : 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 2),
                                const Text(
                                  'Nauza na kusafirisha maji',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: constraints.maxHeight * 0.03),
                      
                      // Already have account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Tayari una akaunti?',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, AppRoutes.login);
                            },
                            child: const Text(
                              'INGIA',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: constraints.maxHeight * 0.02),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
