import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/supabase/supabase_client.dart';
import 'config/routes/app_routes.dart';
import 'config/routes/route_generator.dart';
import 'localization/language_provider.dart';
import 'localization/languages.dart';
import 'core/theme/theme_provider.dart';
import 'modules/auth/controllers/auth_controller.dart';
import 'modules/customer/controllers/home_controller.dart';
import 'modules/customer/controllers/order_controller.dart';
import 'modules/vendor/controllers/vendor_profile_controller.dart';
import 'modules/vendor/controllers/vendor_dashboard_controller.dart';
import 'modules/vendor/controllers/vendor_order_controller.dart';
import 'core/notifications/notification_service.dart';
import 'core/services/profile_completion_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseConfig.initialize();
  
  // Load translations
  await Languages.loadTranslations();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(create: (_) => VendorProfileController()),
        ChangeNotifierProvider(create: (_) => VendorDashboardController()),
        ChangeNotifierProvider(create: (_) => VendorOrderController()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => ProfileCompletionService()),
      ],
      child: Consumer2<LanguageProvider, ThemeProvider>(
        builder: (context, languageProvider, themeProvider, child) {
          return MaterialApp(
            title: 'Water Delivery',
            debugShowCheckedModeBanner: false,
            locale: languageProvider.currentLocale,
            supportedLocales: const [
              Locale('en'),
              Locale('sw'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: RouteGenerator.generateRoute,
          );
        },
      ),
    );
  }
} 
