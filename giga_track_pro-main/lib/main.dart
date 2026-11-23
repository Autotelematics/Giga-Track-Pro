
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackerapp/providers/all_devices_on_map_provider.dart';
import 'package:trackerapp/providers/auth_provider.dart';
import 'package:trackerapp/providers/device_commands_provider.dart';
import 'package:trackerapp/providers/device_live_tracking_provider.dart';
import 'package:trackerapp/providers/device_maintenance_provider.dart';
import 'package:trackerapp/providers/device_reports_view_provider.dart';
import 'package:trackerapp/providers/device_send_command_provider.dart';
import 'package:trackerapp/providers/expense_record_provider.dart';
import 'package:trackerapp/providers/fuel_report_provider.dart';
import 'package:trackerapp/providers/get_alert_provider.dart';
import 'package:trackerapp/providers/get_device_history_provider.dart';
import 'package:trackerapp/providers/get_device_report_provider.dart';
import 'package:trackerapp/providers/get_devices_list_provider.dart';
import 'package:trackerapp/providers/user_login_provider.dart';
import 'package:trackerapp/repository/get_devices_list_repository.dart';
import 'package:trackerapp/services/local_notification.dart';
import 'package:trackerapp/services/play_sounds.dart';
import 'package:trackerapp/utils/routes/routes.dart';
import 'package:trackerapp/utils/routes/routes_name.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundMessageHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('📬 Background message received: ${message.notification?.title}');
    if (message.notification != null) {
      final SharedPreferences sp = await SharedPreferences.getInstance();
      final playAlertSounds = sp.getBool('playAlertSounds') ?? true;
      if (playAlertSounds) {
        PlaySounds.playFromMessage(message);
      }
    }
  } catch (e) {
    debugPrint('❌ Background message error: $e');
  }
}

Future<void> _initializeFirebase() async {
  try {
    debugPrint('🔥 Initializing Firebase...');

    final FirebaseOptions firebaseOptions;

    if (Platform.isAndroid) {
      firebaseOptions = const FirebaseOptions(
        apiKey: "AIzaSyBd7u3Jl_979xmMn3-9NtTcPKqFce5smkY",
        appId: "1:339329536042:android:8ac8f1b8430d7f4cabb353",
        messagingSenderId: "339329536042",
        projectId: "autotel-2f5a1",
      );
    } else if (Platform.isIOS) {
      firebaseOptions = const FirebaseOptions(
        apiKey: "AIzaSyByXVejFx0oYq-U5I37HaBqoeq9dcaV-bk",
        appId: "1:339329536042:ios:fc74d87d357b7ebbabb353",
        messagingSenderId: "339329536042",
        projectId: "autotel-2f5a1",
      );
    } else {
      throw UnsupportedError('Platform not supported for Firebase');
    }

    await Firebase.initializeApp(options: firebaseOptions);
    debugPrint('✅ Firebase initialized');
    await FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 Foreground message: ${message.notification?.title}');
      if (message.notification != null) {
        SharedPreferences.getInstance().then((sp) {
          final playAlertSounds = sp.getBool('playAlertSounds') ?? true;
          if (playAlertSounds) {
            PlaySounds.playFromMessage(message);
          }
        });
      }
    });

    debugPrint('✅ Firebase Messaging setup complete');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization warning: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  await LocalNotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VehicleTrackingProvider()),
        ChangeNotifierProvider(create: (_) => DeviceCommandsProvider()),
        ChangeNotifierProvider(create: (_) => SendDeviceCommandProvider()),
        ChangeNotifierProvider(create: (_) => AlertsProvider()),
        ChangeNotifierProvider(create: (_) => FuelReportProvider()),
        ChangeNotifierProvider(create: (_) => GetReportProvider()),
        ChangeNotifierProvider(create: (_) => ReportTypeProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseRecordProvider()),
        ChangeNotifierProvider(create: (_) => UserLoginProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DeviceMaintenanceProvider()),
        ChangeNotifierProvider(create: (_) => HistoryPlayRoutOnMapProvider()),
        ChangeNotifierProvider(
          create: (_) => GetDevicesListProvider(GetDevicesListRepository()),
        ),
        ChangeNotifierProvider(create: (_) => AllDevicesOnMapProvider()),
      ],
      child: MaterialApp(
        navigatorKey: MyApp.navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.grey,
          primaryColor: Colors.white,
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.transparent,
        ),
        builder: (context,child){
          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/images/login-page-background-3.jpg',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: child,
          );
        },
        initialRoute: RoutesName.splashSceen,
        onGenerateRoute: Routes.generateRoute,
      ),
    );
  }
}