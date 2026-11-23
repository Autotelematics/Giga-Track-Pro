import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackerapp/models/events_intitial_data.dart';
import 'package:trackerapp/models/event_on_map_model.dart';
import 'package:trackerapp/utils/routes/routes_name.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/view/alert_list.dart';
import 'package:trackerapp/view/all_devices_on_map.dart';
import 'package:trackerapp/view/contact_us_screen.dart';
import 'package:trackerapp/view/dashboard.dart';
import 'package:trackerapp/view/devices_list_dashboard.dart';
import 'package:trackerapp/view/settings.dart';
import 'package:trackerapp/services/local_notification.dart';

// ✅ REMOVED: int navBarIndex = 0; (was global, caused bug after logout)

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final _tts = FlutterTts();
  final _dashboardKey = GlobalKey<DashboardState>();
  late final List<Widget> _screens;
  SharedPreferences? _prefs;

  // ✅ FIXED: Now instance variable — resets to 0 on every new HomePage instance
  int navBarIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _screens = [
      // ✅ Pass _onTabChange callback so Dashboard can switch tabs without global variable
      Dashboard(key: _dashboardKey, onTabChange: _onTabChange),
      const DevicesListDashboard(),
      const DevicesOnMap(),
      EventsAlertsPage(
        EventsInitialData(
          deviceID: '',
          eventType: '',
          fromDate: '',
          toDate: '',
          pageNumber: '',
        ),
      ),
      const SettingScreen(),
      const ContactUsScreen(),
    ];
    _initServices();
  }

  Future<void> _initServices() async {
    _prefs = await SharedPreferences.getInstance();
    _tts
      ..setLanguage("en-US")
      ..setSpeechRate(0.5)
      ..setVolume(1.0)
      ..setPitch(1.0);
    _initFirebase();
  }

  void _initFirebase() {
    FirebaseMessaging.instance.getToken();
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleOpenedApp(message);
      }
    });
    FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedApp);
  }

  Future<void> _handleMessage(RemoteMessage? message) async {
    if (message?.notification == null) return;
    LocalNotificationService.showFromRemoteMessage(message!);
    if (_prefs?.getBool('playAlertSounds') == true) {
      await _speak(message);
    }
  }

  Future<void> _handleOpenedApp(RemoteMessage message) async {
    if (message.notification != null &&
        _prefs?.getBool('playAlertSounds') == true) {
      await _speak(message);
    }

    final Map<String, dynamic> combinedData =
        Map<String, dynamic>.from(message.data);
    if (message.notification?.title != null) {
      combinedData['title'] = message.notification?.title;
    }
    if (message.notification?.body != null) {
      combinedData['body'] = message.notification?.body;
    }

    final model = EventOnMapDataModel.fromNotificationData(
      combinedData,
      title: message.notification?.title,
      body: message.notification?.body,
    );

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      RoutesName.eventondevicemap,
      arguments: model,
    );
  }

  Future<void> _speak(RemoteMessage message) async {
    final title = message.notification?.title ?? '';
    if (title.isEmpty) return;
    final parts = title.split(' ');
    final plate = parts.first.split('').join(' ');
    final body = parts.skip(1).join(' ');
    await _tts.speak('Alert! $plate. $body');
  }

  void _updateNavBar(int index) {
    setState(() {
      navBarIndex = index;
    });
  }

  void _onTabChange(int index) {
    if (index == 0) {
      _dashboardKey.currentState?.triggerChartAnimation();
    }
    _updateNavBar(index);
  }

  Future<bool> _onWillPop() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exit App?'),
        content: const Text('Do you want to exit the application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
    } else if (state == AppLifecycleState.resumed) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: navBarIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildBottomNavBar() => BottomNavigationBar(
    currentIndex: navBarIndex,
    onTap: _onTabChange,
    selectedItemColor: AppColors.buttonColor,
    unselectedItemColor: Colors.black,
    selectedLabelStyle: const TextStyle(color: Colors.black87),
    iconSize: 28,
    elevation: 1,
    type: BottomNavigationBarType.fixed,
    showUnselectedLabels: true,
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.map_outlined),
        activeIcon: Icon(Icons.map),
        label: 'Status',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.location_on_outlined),
        activeIcon: Icon(Icons.location_on),
        label: 'Map',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.notifications_outlined),
        activeIcon: Icon(Icons.notifications),
        label: 'Alerts',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.phone_in_talk_outlined),
        activeIcon: Icon(Icons.phone_in_talk),
        label: 'Contact',
      ),
    ],
  );
}