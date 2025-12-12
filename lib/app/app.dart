import 'package:eClassify/firebase_options.dart';
import 'package:eClassify/main.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/hive_keys.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/security/device_security_service.dart';
import 'package:eClassify/utils/security/secure_storage_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// List of Hive box names that need to be initialized
final List<String> _hiveBoxes = [
  HiveKeys.userDetailsBox,
  HiveKeys.translationsBox,
  HiveKeys.authBox,
  HiveKeys.languageBox,
  HiveKeys.themeBox,
  HiveKeys.svgBox,
  HiveKeys.jwtToken,
  HiveKeys.historyBox,
];

/// Initializes the application with all necessary configurations
Future<void> initApp() async {
  try {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Configure Google Maps for Android
    _configureGoogleMaps();

    // Set up error handling for release mode
    if (kReleaseMode) {
      _setupErrorHandling();
    }

    // Initialize Firebase
    await _initializeFirebase();

    // Initialize Mobile Ads
    await MobileAds.instance.initialize();

    // Initialize Hive and open boxes
    await _initializeHive();

    // Initialize secure storage for sensitive data
    await SecureStorageService.init();

    // Migrate JWT from Hive to SecureStorage (one-time migration)
    await _migrateJWTToSecureStorage();

    // Load JWT from secure storage into cache
    await HiveUtils.getJWTAsync();

    // Check device security (root/jailbreak detection)
    final isCompromised = await DeviceSecurityService.isDeviceCompromised();
    if (isCompromised && kReleaseMode) {
      // Block app execution on compromised devices in production
      debugPrint('❌ SECURITY: Device is rooted/jailbroken - blocking app');
      return runApp(const _CompromisedDeviceScreen());
    }

    // Configure system UI and launch app
    await _configureSystemUI();

    Constant.savePath = await getApplicationDocumentsDirectory().then(
      (dir) => dir.path,
    );

    runApp(const EntryPoint());
  } catch (e, stackTrace) {
    debugPrint('Error initializing app: $e\n$stackTrace');
    rethrow;
  }
}

/// Configures Google Maps for Android platform
void _configureGoogleMaps() {
  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = false;
  }
}

/// Sets up error handling for release mode
void _setupErrorHandling() {
  ErrorWidget.builder = (FlutterErrorDetails flutterErrorDetails) {
    return SomethingWentWrong();
  };
}

/// Initializes Firebase with appropriate options
Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();
  }

  await FirebaseAppCheck.instance.activate(
    appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
    androidProvider: AndroidProvider.playIntegrity,
  );
}

/// Initializes Hive and opens all required boxes
Future<void> _initializeHive() async {
  await Hive.initFlutter();
  for (final boxName in _hiveBoxes) {
    await Hive.openBox(boxName);
  }
}

/// Migrates JWT token from Hive to SecureStorage (one-time migration)
Future<void> _migrateJWTToSecureStorage() async {
  try {
    // Check if JWT exists in Hive
    final hiveJWT = Hive.box(HiveKeys.userDetailsBox).get(HiveKeys.jwtToken);

    if (hiveJWT != null && hiveJWT.toString().isNotEmpty) {
      // Check if already migrated to SecureStorage
      final secureJWT = await SecureStorageService.getJWT();

      if (secureJWT == null || secureJWT.isEmpty) {
        // Migrate from Hive to SecureStorage
        await SecureStorageService.setJWT(hiveJWT.toString());
        if (kDebugMode) {
          debugPrint('✅ JWT migrated from Hive to SecureStorage');
        }
      }

      // Remove JWT from Hive for security
      await Hive.box(HiveKeys.userDetailsBox).delete(HiveKeys.jwtToken);
      if (kDebugMode) {
        debugPrint('✅ JWT removed from Hive');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ JWT migration error: $e');
    }
  }
}

/// Configures system UI and launches the app
Future<void> _configureSystemUI() async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
}

/// Screen shown when device is compromised (rooted/jailbroken)
class _CompromisedDeviceScreen extends StatelessWidget {
  const _CompromisedDeviceScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Security icon
                Icon(
                  Icons.security,
                  size: 100,
                  color: Colors.red.shade700,
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Security Alert',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Message
                Text(
                  'This app cannot run on rooted or jailbroken devices for security reasons.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Explanation
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why is this happening?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rooted or jailbroken devices have compromised security that could expose your personal data and payment information to malicious apps.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Exit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Exit the app
                      SystemNavigator.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Exit App',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
