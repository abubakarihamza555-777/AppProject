Resolving dependencies...
Downloading packages...
  archive 3.6.1 (4.0.9 available)
  connectivity_plus 5.0.2 (7.1.0 available)
  connectivity_plus_platform_interface 1.2.4 (2.1.0 available)
  fl_chart 0.66.2 (1.2.0 available)
  flutter_lints 3.0.2 (6.0.0 available)
  flutter_local_notifications 17.2.4 (21.0.0 available)
  flutter_local_notifications_linux 4.0.1 (8.0.0 available)
  flutter_local_notifications_platform_interface 7.2.0 (11.0.0 available)
+ flutter_otp_text_field 1.5.1+1
  geocoding 2.2.2 (4.0.0 available)
  geocoding_android 3.3.1 (5.0.1 available)
  geocoding_ios 2.3.0 (3.1.0 available)
  geocoding_platform_interface 3.2.0 (5.0.0 available)
  geolocator 10.1.1 (14.0.2 available)
  geolocator_android 4.6.2 (5.0.2 available)
  geolocator_web 2.2.1 (4.1.3 available)
  google_fonts 6.3.3 (8.0.2 available)
  google_maps_flutter_android 2.19.5 (2.19.6 available)
  image 4.3.0 (4.8.0 available)
  image_picker_android 0.8.13+15 (0.8.13+16 available)
  js 0.6.7 (0.7.2 available)
  lints 3.0.0 (6.1.0 available)
+ local_auth 2.3.0 (3.0.1 available)
+ local_auth_android 1.0.56 (2.0.7 available)
+ local_auth_darwin 1.6.1 (2.0.3 available)
+ local_auth_platform_interface 1.1.0
+ local_auth_windows 1.0.11 (2.0.1 available)
  lottie 2.7.0 (3.3.2 available)
  meta 1.17.0 (1.18.2 available)
  path_provider_android 2.2.23 (2.3.1 available)
  test_api 0.7.10 (0.7.11 available)
  timezone 0.9.4 (0.11.0 available)
  vector_math 2.2.0 (2.3.0 available)
Changed 6 dependencies!
31 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Running Gradle task 'assembleRelease'...                        

FAILURE: Build failed with an exception.

* What went wrong:
A problem occurred configuring project ':local_auth_android'.
> Could not resolve all artifacts for configuration 'classpath'.
   > Could not download gradle-8.12.1.jar (com.android.tools.build:gradle:8.12.1)
      > Could not get resource 'https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle/8.12.1/gradle-8.12.1.jar'.
         > Could not GET 'https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle/8.12.1/gradle-8.12.1.jar'.
            > The server may not support the client's requested TLS protocol versions: (TLSv1.2, TLSv1.3). You may need to configure the client to allow other protocols to be used. For more on this, please refer to https://docs.gradle.org/8.14/userguide/build_environment.html#sec:gradle_system_properties in the Gradle documentation.
               > Remote host terminated the handshake
   > Could not download gradle-settings-api-8.12.1.jar (com.android.tools.build:gradle-settings-api:8.12.1)
      > Could not get resource 'https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle-settings-api/8.12.1/gradle-settings-api-8.12.1.jar'.
         > Could not GET 'https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle-settings-api/8.12.1/gradle-settings-api-8.12.1.jar'.
            > The server may not support the client's requested TLS protocol versions: (TLSv1.2, TLSv1.3). You may need to configure the client to allow other protocols to be used. For more on this, please refer to https://docs.gradle.org/8.14/userguide/build_environment.html#sec:gradle_system_properties in the Gradle documentation.
               > Remote host terminated the handshake
   > Could not download lint-model-31.12.1.jar (com.android.tools.lint:lint-model:31.12.1)
      > Could not get resource 'https://dl.google.com/dl/android/maven2/com/android/tools/lint/lint-model/31.12.1/lint-model-31.12.1.jar'.
         > Could not GET 'https://dl.google.com/dl/android/maven2/com/android/tools/lint/lint-model/31.12.1/lint-model-31.12.1.jar'.
            > The server may not support the client's requested TLS protocol versions: (TLSv1.2, TLSv1.3). You may need to configure the client to allow other protocols to be used. For more on this, please refer to https://docs.gradle.org/8.14/userguide/build_environment.html#sec:gradle_system_properties in the Gradle documentation.
               > Remote host terminated the handshake
   > Could not download builder-8.12.1.jar (com.android.tools.build:builder:8.12.1)
      > Could not get resource 'https://dl.google.com/dl/android/maven2/com/android/tools/build/builder/8.12.1/builder-8.12.1.jar'.
         > Could not GET 'https://dl.google.com/dl/android/maven2/com/android/tools/build/builder/8.12.1/builder-8.12.1.jar'.
            > The server may not support the client's requested TLS protocol versions: (TLSv1.2, TLSv1.3). You may need to configure the client to allow other protocols to be used. For more on this, please refer to https://docs.gradle.org/8.14/userguide/build_environment.html#sec:gradle_system_properties in the Gradle documentation.
               > Remote host terminated the handshake
> Failed to notify project evaluation listener.
   > java.lang.NullPointerException (no error message)
   > Configuration with name 'implementation' not found.
   > Configuration with name 'implementation' not found.
   > java.lang.NullPointerException (no error message)

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 7m 12s
Running Gradle task 'assembleRelease'...                          446.4s
[!] Gradle threw an error while downloading artifacts from the network.
Retrying Gradle Build: #1, wait time: 100ms
Running Gradle task 'assembleRelease'...                        
lib/modules/auth/screens/login_screen.dart:519:5: Error: 'switch' can't be used as an identifier because it's a keyword.
Try renaming this to be an identifier that isn't a keyword.
    switch (user?.role) {
    ^^^^^^
lib/modules/auth/screens/login_screen.dart:519:17: Error: Expected ')' before this.
    switch (user?.role) {
                ^^
lib/modules/auth/screens/login_screen.dart:554:3: Error: Expected a declaration, but got '}'.
  }
  ^
lib/modules/auth/screens/login_screen.dart:828:1: Error: Expected a declaration, but got '}'.
}
^
lib/modules/vendor/screens/premium_vendor_dashboard.dart:11:8: Error: Error when reading 'lib/shared/widgets/notification_screen.dart': The system cannot find the file specified
import '../../../shared/widgets/notification_screen.dart';
       ^
lib/modules/vendor/controllers/vendor_profile_controller.dart:92:15: Error: Expected a class member, but got '.'.
              .eq('user_id', userId)
              ^
lib/modules/vendor/controllers/vendor_profile_controller.dart:92:19: Error: Expected an identifier, but got ''user_id''.
Try inserting an identifier before ''user_id''.
              .eq('user_id', userId)
                  ^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:93:15: Error: Expected '{' before this.
              .maybeSingle();
              ^
lib/modules/vendor/controllers/vendor_profile_controller.dart:93:15: Error: Expected a class member, but got '.'.
              .maybeSingle();
              ^
lib/modules/vendor/controllers/vendor_profile_controller.dart:95:11: Error: Expected a class member, but got 'if'.
          if (response != null) {
          ^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:95:14: Error: Expected an identifier, but got '('.
Try inserting an identifier before '('.
          if (response != null) {
             ^
lib/modules/vendor/controllers/vendor_profile_controller.dart:95:24: Error: Expected ')' before this.
          if (response != null) {
                       ^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:99:7: Error: Expected a declaration, but got '}'.
      }
      ^
lib/modules/vendor/controllers/vendor_profile_controller.dart:100:5: Error: Expected a declaration, but got '}'.
    } catch (e) {
    ^
lib/modules/vendor/controllers/vendor_profile_controller.dart:100:7: Error: 'catch' can't be used as an identifier because it's a keyword.
Try renaming this to be an identifier that isn't a keyword.
    } catch (e) {
      ^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:103:7: Error: 'finally' can't be used as an identifier because it's a keyword.
Try renaming this to be an identifier that isn't a keyword.
    } finally {
      ^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:103:7: Error: A function declaration needs an explicit list of parameters.
Try adding a parameter list to the function declaration.
    } finally {
      ^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:106:3: Error: Expected a declaration, but got '}'.
  }
  ^
lib/modules/vendor/controllers/vendor_profile_controller.dart:300:1: Error: Expected a declaration, but got '}'.
}
^
lib/modules/vendor/controllers/vendor_order_controller.dart:55:16: Error: 'loadOrders' is already declared in this scope.
  Future<void> loadOrders(String vendorId) async {
               ^^^^^^^^^^
lib/modules/vendor/controllers/vendor_order_controller.dart:40:16: Context: Previous declaration of 'loadOrders'.
  Future<void> loadOrders() async {
               ^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:64:16: Error: 'loadVendorProfile' is already declared in this scope.
  Future<void> loadVendorProfile(String? vendorId) async {
               ^^^^^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:38:16: Context: Previous declaration of 'loadVendorProfile'.
  Future<void> loadVendorProfile() async {
               ^^^^^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_order_controller.dart:15:3: Error: Type 'StreamSubscription' not found.
  StreamSubscription? _orderSubscription;
  ^^^^^^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:6:7: Error: The non-abstract class 'VendorProfileController' is missing implementations for these members:
 - VendorProfileController.maybeSingle
Try to either
 - provide an implementation,
 - inherit an implementation from a superclass or mixin,
 - mark the class as abstract, or
 - provide a 'noSuchMethod' implementation.
class VendorProfileController extends ChangeNotifier {
      ^^^^^^^^^^^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:93:16: Context: 'VendorProfileController.maybeSingle' is defined here.
              .maybeSingle();
               ^^^^^^^^^^^
lib/modules/auth/screens/login_screen.dart:516:38: Error: Undefined name 'context'.
    final profileCompletionService = context.read<ProfileCompletionService>();
                                     ^^^^^^^
lib/modules/auth/screens/login_screen.dart:517:33: Error: Undefined name 'context'.
    final notificationService = context.read<NotificationService>();
                                ^^^^^^^
lib/config/routes/route_generator.dart:50:22: Error: Member not found: 'customerRegister'.
      case AppRoutes.customerRegister:
                     ^^^^^^^^^^^^^^^^
lib/config/routes/route_generator.dart:52:22: Error: Member not found: 'vendorRegister'.
      case AppRoutes.vendorRegister:
                     ^^^^^^^^^^^^^^
lib/modules/auth/screens/splash_screen.dart:128:53: Error: The argument type 'double' can't be assigned to the parameter type 'int'.
                      color: Colors.white.withAlpha(0.9),
                                                    ^
lib/modules/auth/screens/login_screen.dart:520:7: Error: 'case' can't be used as an identifier because it's a keyword.
Try renaming this to be an identifier that isn't a keyword.
      case 'customer':
      ^^^^
lib/modules/auth/screens/login_screen.dart:520:7: Error: Expected ';' after this.
      case 'customer':
      ^^^^
lib/modules/auth/screens/login_screen.dart:520:7: Error: Undefined name 'case'.
      case 'customer':
      ^^^^
lib/modules/auth/screens/login_screen.dart:520:12: Error: Expected ';' after this.
      case 'customer':
           ^^^^^^^^^^
lib/modules/auth/screens/login_screen.dart:520:22: Error: Expected an identifier, but got ':'.
Try inserting an identifier before ':'.
      case 'customer':
                     ^
lib/modules/auth/screens/login_screen.dart:520:22: Error: Unexpected token ';'.
      case 'customer':
                     ^
lib/modules/auth/screens/login_screen.dart:524:13: Error: Undefined name 'context'.
            context, 
            ^^^^^^^
lib/modules/auth/screens/login_screen.dart:531:42: Error: Undefined name 'context'.
          Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
                                         ^^^^^^^
lib/modules/auth/screens/login_screen.dart:534:7: Error: 'case' can't be used as an identifier because it's a keyword.
Try renaming this to be an identifier that isn't a keyword.
      case 'vendor':
      ^^^^
lib/modules/auth/screens/login_screen.dart:534:7: Error: Expected ';' after this.
      case 'vendor':
      ^^^^
lib/modules/auth/screens/login_screen.dart:534:7: Error: Undefined name 'case'.
      case 'vendor':
      ^^^^
lib/modules/auth/screens/login_screen.dart:534:12: Error: Expected ';' after this.
      case 'vendor':
           ^^^^^^^^
lib/modules/auth/screens/login_screen.dart:534:20: Error: Expected an identifier, but got ':'.
Try inserting an identifier before ':'.
      case 'vendor':
                   ^
lib/modules/auth/screens/login_screen.dart:534:20: Error: Unexpected token ';'.
      case 'vendor':
                   ^
lib/modules/auth/screens/login_screen.dart:538:13: Error: Undefined name 'context'.
            context, 
            ^^^^^^^
lib/modules/auth/screens/login_screen.dart:545:42: Error: Undefined name 'context'.
          Navigator.pushReplacementNamed(context, AppRoutes.vendorDashboard);
                                         ^^^^^^^
lib/modules/auth/screens/login_screen.dart:548:7: Error: 'case' can't be used as an identifier because it's a keyword.
Try renaming this to be an identifier that isn't a keyword.
      case 'admin':
      ^^^^
lib/modules/auth/screens/login_screen.dart:548:7: Error: Expected ';' after this.
      case 'admin':
      ^^^^
lib/modules/auth/screens/login_screen.dart:548:7: Error: Undefined name 'case'.
      case 'admin':
      ^^^^
lib/modules/auth/screens/login_screen.dart:548:12: Error: Expected ';' after this.
      case 'admin':
           ^^^^^^^
lib/modules/auth/screens/login_screen.dart:548:19: Error: Expected an identifier, but got ':'.
Try inserting an identifier before ':'.
      case 'admin':
                  ^
lib/modules/auth/screens/login_screen.dart:548:19: Error: Unexpected token ';'.
      case 'admin':
                  ^
lib/modules/auth/screens/login_screen.dart:549:40: Error: Undefined name 'context'.
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
                                       ^^^^^^^
lib/modules/auth/screens/login_screen.dart:551:7: Error: 'default' can't be used as an identifier because it's a keyword.
Try renaming this to be an identifier that isn't a keyword.
      default:
      ^^^^^^^
lib/modules/auth/screens/login_screen.dart:551:7: Error: Expected ';' after this.
      default:
      ^^^^^^^
lib/modules/auth/screens/login_screen.dart:551:7: Error: Undefined name 'default'.
      default:
      ^^^^^^^
lib/modules/auth/screens/login_screen.dart:551:14: Error: Expected an identifier, but got ':'.
Try inserting an identifier before ':'.
      default:
             ^
lib/modules/auth/screens/login_screen.dart:551:14: Error: Unexpected token ';'.
      default:
             ^
lib/modules/auth/screens/login_screen.dart:552:40: Error: Undefined name 'context'.
        Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
                                       ^^^^^^^
lib/modules/auth/screens/login_screen.dart:745:24: Error: Undefined name '_formKey'.
                  key: _formKey,
                       ^^^^^^^^
lib/modules/auth/screens/login_screen.dart:751:37: Error: Undefined name '_email'.
                        controller: _email,
                                    ^^^^^^
lib/modules/auth/screens/login_screen.dart:766:37: Error: Undefined name '_password'.
                        controller: _password,
                                    ^^^^^^^^^
lib/modules/auth/screens/login_screen.dart:782:36: Error: Undefined name '_isLoading'.
                        onPressed: _isLoading || auth.isLoading 
                                   ^^^^^^^^^^
lib/modules/auth/screens/login_screen.dart:784:31: Error: Undefined name '_submit'.
                            : _submit,
                              ^^^^^^^
lib/modules/auth/screens/login_screen.dart:785:36: Error: Undefined name '_isLoading'.
                        isLoading: _isLoading || auth.isLoading,
                                   ^^^^^^^^^^
lib/modules/vendor/screens/vendor_profile_screen.dart:61:40: Error: The method 'updateProfile' isn't defined for the type 'VendorProfileController'.
 - 'VendorProfileController' is from 'package:water_delivery_app/modules/vendor/controllers/vendor_profile_controller.dart' ('lib/modules/vendor/controllers/vendor_profile_controller.dart').
Try correcting the name to the name of an existing method, or defining a method named 'updateProfile'.
      final success = await controller.updateProfile(
                                       ^^^^^^^^^^^^^
lib/modules/vendor/screens/vendor_profile_screen.dart:74:20: Error: The method 'toggleEditing' isn't defined for the type 'VendorProfileController'.
 - 'VendorProfileController' is from 'package:water_delivery_app/modules/vendor/controllers/vendor_profile_controller.dart' ('lib/modules/vendor/controllers/vendor_profile_controller.dart').
Try correcting the name to the name of an existing method, or defining a method named 'toggleEditing'.
        controller.toggleEditing();
                   ^^^^^^^^^^^^^
lib/modules/vendor/screens/vendor_profile_screen.dart:91:37: Error: The getter 'toggleEditing' isn't defined for the type 'VendorProfileController'.
 - 'VendorProfileController' is from 'package:water_delivery_app/modules/vendor/controllers/vendor_profile_controller.dart' ('lib/modules/vendor/controllers/vendor_profile_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'toggleEditing'.
              onPressed: controller.toggleEditing,
                                    ^^^^^^^^^^^^^
lib/modules/vendor/screens/vendor_profile_screen.dart:190:87: Error: The getter 'vehicleType' isn't defined for the type 'VendorModel'.
 - 'VendorModel' is from 'package:water_delivery_app/modules/vendor/models/vendor_model.dart' ('lib/modules/vendor/models/vendor_model.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'vehicleType'.
                          initialValue: _getVehicleTypeName(controller.vendorProfile?.vehicleType),
                                                                                      ^^^^^^^^^^^
lib/modules/vendor/screens/vendor_profile_screen.dart:206:70: Error: The getter 'maxLitersPerTrip' isn't defined for the type 'VendorModel'.
 - 'VendorModel' is from 'package:water_delivery_app/modules/vendor/models/vendor_model.dart' ('lib/modules/vendor/models/vendor_model.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'maxLitersPerTrip'.
                          initialValue: '${controller.vendorProfile?.maxLitersPerTrip ?? 0} L',
                                                                     ^^^^^^^^^^^^^^^^
lib/modules/vendor/screens/vendor_profile_screen.dart:260:48: Error: The method 'toggleAvailability' isn't defined for the type 'VendorProfileController'.
 - 'VendorProfileController' is from 'package:water_delivery_app/modules/vendor/controllers/vendor_profile_controller.dart' ('lib/modules/vendor/controllers/vendor_profile_controller.dart').
Try correcting the name to the name of an existing method, or defining a method named 'toggleAvailability'.
                              await controller.toggleAvailability();
                                               ^^^^^^^^^^^^^^^^^^
lib/modules/vendor/screens/vendor_profile_screen.dart:274:48: Error: The method 'toggleEditing' isn't defined for the type 'VendorProfileController'.
 - 'VendorProfileController' is from 'package:water_delivery_app/modules/vendor/controllers/vendor_profile_controller.dart' ('lib/modules/vendor/controllers/vendor_profile_controller.dart').
Try correcting the name to the name of an existing method, or defining a method named 'toggleEditing'.
                                    controller.toggleEditing();
                                               ^^^^^^^^^^^^^
lib/modules/auth/services/auth_service.dart:257:9: Error: The getter 'Provider' isn't defined for the type 'AuthService'.
 - 'AuthService' is from 'package:water_delivery_app/modules/auth/services/auth_service.dart' ('lib/modules/auth/services/auth_service.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'Provider'.
        Provider.google,
        ^^^^^^^^
lib/modules/auth/services/auth_service.dart:261:20: Error: The getter 'user' isn't defined for the type 'bool'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'user'.
      if (response.user != null) {
                   ^^^^
lib/modules/auth/services/auth_service.dart:263:24: Error: The getter 'user' isn't defined for the type 'bool'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'user'.
          id: response.user!.id,
                       ^^^^
lib/modules/auth/services/auth_service.dart:264:27: Error: The getter 'user' isn't defined for the type 'bool'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'user'.
          email: response.user!.email ?? '',
                          ^^^^
lib/modules/auth/services/auth_service.dart:265:30: Error: The getter 'user' isn't defined for the type 'bool'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'user'.
          fullName: response.user!.userMetadata?['full_name'] ?? 'Google User',
                             ^^^^
lib/modules/auth/services/auth_service.dart:266:27: Error: The getter 'user' isn't defined for the type 'bool'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'user'.
          phone: response.user!.phone ?? '',
                          ^^^^
lib/modules/auth/services/auth_service.dart:267:26: Error: The getter 'user' isn't defined for the type 'bool'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'user'.
          role: response.user!.userMetadata?['role'] ?? 'customer',
                         ^^^^
lib/modules/auth/services/auth_service.dart:281:9: Error: The getter 'Provider' isn't defined for the type 'AuthService'.
 - 'AuthService' is from 'package:water_delivery_app/modules/auth/services/auth_service.dart' ('lib/modules/auth/services/auth_service.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'Provider'.
        Provider.facebook,
        ^^^^^^^^
lib/modules/auth/services/auth_service.dart:285:20: Error: The getter 'user' isn't defined for the type 'bool'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'user'.
      if (response.user != null) {
                   ^^^^
lib/modules/auth/services/auth_service.dart:287:24: Error: The getter 'user' isn't defined for the type 'bool'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'user'.
          id: response.user!.id,
                       ^^^^
lib/modules/auth/services/auth_service.dart:288:27: Error: The getter 'user' isn't defined for the type 'bool'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'user'.
          email: response.user!.email ?? '',
                          ^^^^
lib/modules/auth/services/auth_service.dart:289:30: Error: The getter 'user' isn't defined for the type 'bool'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'user'.
          fullName: response.user!.userMetadata?['full_name'] ?? 'Facebook User',
                             ^^^^
lib/modules/auth/services/auth_service.dart:290:27: Error: The getter 'user' isn't defined for the type 'bool'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'user'.
          phone: response.user!.phone ?? '',
                          ^^^^
lib/modules/auth/services/auth_service.dart:291:26: Error: The getter 'user' isn't defined for the type 'bool'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'user'.
          role: response.user!.userMetadata?['role'] ?? 'customer',
                         ^^^^
lib/modules/auth/services/auth_service.dart:305:9: Error: The getter 'Provider' isn't defined for the type 'AuthService'.
 - 'AuthService' is from 'package:water_delivery_app/modules/auth/services/auth_service.dart' ('lib/modules/auth/services/auth_service.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'Provider'.
        Provider.apple,
        ^^^^^^^^
lib/modules/auth/services/auth_service.dart:309:20: Error: The getter 'user' isn't defined for the type 'bool'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'user'.
      if (response.user != null) {
                   ^^^^
lib/modules/auth/services/auth_service.dart:311:24: Error: The getter 'user' isn't defined for the type 'bool'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'user'.
          id: response.user!.id,
                       ^^^^
lib/modules/auth/services/auth_service.dart:312:27: Error: The getter 'user' isn't defined for the type 'bool'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'user'.
          email: response.user!.email ?? '',
                          ^^^^
lib/modules/auth/services/auth_service.dart:313:30: Error: The getter 'user' isn't defined for the type 'bool'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'user'.
          fullName: response.user!.userMetadata?['full_name'] ?? 'Apple User',
                             ^^^^
lib/modules/auth/services/auth_service.dart:314:27: Error: The getter 'user' isn't defined for the type 'bool'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'user'.
          phone: response.user!.phone ?? '',
                          ^^^^
lib/modules/auth/services/auth_service.dart:315:26: Error: The getter 'user' isn't defined for the type 'bool'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'user'.
          role: response.user!.userMetadata?['role'] ?? 'customer',
                         ^^^^
lib/modules/vendor/services/vendor_service.dart:296:44: Error: A value of type 'PostgrestFilterBuilder<dynamic>' can't be assigned to a variable of type 'bool'.
 - 'PostgrestFilterBuilder' is from 'package:postgrest/src/postgrest_builder.dart' ('../../AppData/Local/Pub/Cache/hosted/pub.dev/postgrest-2.6.0/lib/src/postgrest_builder.dart').
          .update({'is_active': !_supabase.rpc('get_vendor_status', params: {'vendor_id': vendorId})})
                                           ^
lib/modules/vendor/services/vendor_service.dart:342:22: Error: The getter 'maxLitersPerTrip' isn't defined for the type 'VendorModel'.
 - 'VendorModel' is from 'package:water_delivery_app/modules/vendor/models/vendor_model.dart' ('lib/modules/vendor/models/vendor_model.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'maxLitersPerTrip'.
      return (vendor.maxLitersPerTrip ?? 0) - totalDelivered;
                     ^^^^^^^^^^^^^^^^
lib/modules/vendor/services/earnings_service.dart:90:52: Error: The getter 'week' isn't defined for the type 'DateTime'.
 - 'DateTime' is from 'dart:core'.
Try correcting the name to the name of an existing getter, or defining a getter or field named 'week'.
        return '${startOfWeek.year}-W${startOfWeek.week.toString().padLeft(2, '0')}';
                                                   ^^^^
lib/modules/vendor/controllers/vendor_order_controller.dart:15:3: Error: 'StreamSubscription' isn't a type.
  StreamSubscription? _orderSubscription;
  ^^^^^^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_order_controller.dart:127:42: Error: The method 'getOrderById' isn't defined for the type 'VendorService'.
 - 'VendorService' is from 'package:water_delivery_app/modules/vendor/services/vendor_service.dart' ('lib/modules/vendor/services/vendor_service.dart').
Try correcting the name to the name of an existing method, or defining a method named 'getOrderById'.
      final order = await _vendorService.getOrderById(orderId);
                                         ^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_order_controller.dart:158:19: Error: 'new' can only be used as a constructor reference.
        if (event.new != null && event.old == null) {
                  ^^^
lib/modules/vendor/controllers/vendor_order_controller.dart:159:43: Error: 'new' can only be used as a constructor reference.
          _showNewOrderNotification(event.new! as Map<String, dynamic>);
                                          ^^^
lib/modules/vendor/controllers/vendor_order_controller.dart:155:12: Error: The method 'inFilter' isn't defined for the type 'SupabaseStreamBuilder'.
 - 'SupabaseStreamBuilder' is from 'package:supabase/src/supabase_stream_builder.dart' ('../../AppData/Local/Pub/Cache/hosted/pub.dev/supabase-2.10.4/lib/src/supabase_stream_builder.dart').
Try correcting the name to the name of an existing method, or defining a method named 'inFilter'.
          .inFilter('status', ['pending', 'placed'])
           ^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:101:7: Error: Setter not found: '_errorMessage'.
      _errorMessage = e.toString();
      ^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:121:22: Error: Undefined name 'supabase'.
      final userId = supabase.auth.currentUser?.id;
                     ^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:139:37: Error: Undefined name 'supabase'.
      final existingProfile = await supabase
                                    ^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:149:24: Error: Undefined name 'supabase'.
        result = await supabase
                       ^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:167:24: Error: Undefined name 'supabase'.
        result = await supabase
                       ^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:174:7: Error: Setter not found: '_profileData'.
      _profileData = Map<String, dynamic>.from(result);
      ^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:177:64: Error: Undefined name '_profileData'.
      int completionPercentage = calculateCompletionPercentage(_profileData);
                                                               ^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:177:34: Error: Method not found: 'calculateCompletionPercentage'.
      int completionPercentage = calculateCompletionPercentage(_profileData);
                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:187:7: Error: Setter not found: '_errorMessage'.
      _errorMessage = e.toString();
      ^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:204:9: Error: Undefined name '_vendorProfile'.
    if (_vendorProfile == null) return false;
        ^^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:215:57: Error: Undefined name '_vendorProfile'.
      final updated = await _vendorService.updateVendor(_vendorProfile!.id, data);
                                                        ^^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:215:29: Error: Undefined name '_vendorService'.
      final updated = await _vendorService.updateVendor(_vendorProfile!.id, data);
                            ^^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:217:9: Error: Setter not found: '_vendorProfile'.
        _vendorProfile = updated;
        ^^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:230:9: Error: Undefined name '_vendorProfile'.
    if (_vendorProfile == null) return false;
        ^^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:235:69: Error: Undefined name '_vendorProfile'.
      final success = await _vendorService.toggleVendorAvailability(_vendorProfile!.id);
                                                                    ^^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:235:29: Error: Undefined name '_vendorService'.
      final success = await _vendorService.toggleVendorAvailability(_vendorProfile!.id);
                            ^^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:236:22: Error: Undefined name '_vendorProfile'.
      if (success && _vendorProfile != null) {
                     ^^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:237:26: Error: Undefined name '_vendorProfile'.
        _vendorProfile = _vendorProfile!.copyWith(isActive: !_vendorProfile!.isActive);
                         ^^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:237:62: Error: Undefined name '_vendorProfile'.
        _vendorProfile = _vendorProfile!.copyWith(isActive: !_vendorProfile!.isActive);
                                                             ^^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:237:9: Error: Setter not found: '_vendorProfile'.
        _vendorProfile = _vendorProfile!.copyWith(isActive: !_vendorProfile!.isActive);
        ^^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:287:19: Error: Undefined name '_isEditing'.
    _isEditing = !_isEditing;
                  ^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:287:5: Error: Setter not found: '_isEditing'.
    _isEditing = !_isEditing;
    ^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:288:5: Error: Method not found: 'notifyListeners'.
    notifyListeners();
    ^^^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:292:5: Error: Setter not found: '_errorMessage'.
    _errorMessage = '';
    ^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:293:5: Error: Method not found: 'notifyListeners'.
    notifyListeners();
    ^^^^^^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:297:5: Error: Setter not found: '_isLoading'.
    _isLoading = value;
    ^^^^^^^^^^
lib/modules/vendor/controllers/vendor_profile_controller.dart:298:5: Error: Method not found: 'notifyListeners'.
    notifyListeners();
  