import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:intl/intl.dart';
import 'package:trackerapp/models/device_on_map_model.dart';
import 'package:trackerapp/providers/device_live_tracking_provider.dart';
import 'package:trackerapp/providers/get_alert_provider.dart';
import 'package:trackerapp/providers/get_device_history_provider.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/res/components/app_end_point.dart';
import 'package:trackerapp/res/helper/map_helper.dart';
import 'package:trackerapp/utils/animated_marker.dart';
import 'package:trackerapp/widgets/live_tracking_page/fab_widget.dart';
import 'package:trackerapp/widgets/live_tracking_page/loading_widget.dart';
import 'package:trackerapp/widgets/live_tracking_page/map_widget.dart';
import 'package:trackerapp/widgets/live_tracking_page/sliding_panel_widget.dart';
import 'package:trackerapp/widgets/live_tracking_page/status_bar_widget.dart';

const kMarkerId = MarkerId('MarkerId1');

class SingleDeviceOnMap extends StatefulWidget {
  final DeviceOnMapInitialData? initialData;
  const SingleDeviceOnMap(this.initialData, {super.key});

  @override
  State<SingleDeviceOnMap> createState() => _SingleDeviceOnMapState();
}

class _SingleDeviceOnMapState extends State<SingleDeviceOnMap>
    with WidgetsBindingObserver {
  late VehicleTrackingProvider _trackingProvider;
  late HistoryPlayRoutOnMapProvider _historyProvider;
  late AlertsProvider _alertsProvider;

  GoogleMapController? _mapController;
  final PanelController panelController = PanelController();

  // Map Controls
  MapType currentMapType = MapType.normal;
  bool enableTraffic = false;
  double currentZoom = 17.0;
  bool _isCameraInitialized = false;

  // CAMERA CONTROL
  LatLng? _smoothMarkerPos;
  bool _isUserInteracting = false; // ✅ Track if fingers are on screen

  // UI State
  Color mainBoxBackgroundColor = Colors.grey;
  String vehicleStatus = 'Loading';
  String updateTime = '';
  String vehicleSpeed = '0';
  Color vehicleStatusColor = Colors.white;
  Color keyColor = Colors.grey;
  Color batteryChargingColor = Colors.grey;
  bool immobilizerValue = false;
  String immobilizerStatus = 'Immobiliser is not available';
  String batteryVoltage = 'N/A';
  String keyStatus = 'N/A';
  double? currentFuelCost = 249.5;
  double vehicleFuelAveragePerKm = 13.0;
  BitmapDescriptor _markerIcon = BitmapDescriptor.defaultMarker;
  Marker _currentMarker = const Marker(markerId: kMarkerId);
  bool _markerInitialized = false;
  LatLng _lastKnownPosition = const LatLng(0, 0);
  String _lastLoadedIconPath = '';

  // Animation duration
  Duration _animationDuration = const Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _trackingProvider =
        Provider.of<VehicleTrackingProvider>(context, listen: false);
    _historyProvider =
        Provider.of<HistoryPlayRoutOnMapProvider>(context, listen: false);
    _alertsProvider = Provider.of<AlertsProvider>(context, listen: false);

    // ✅ Reset old coordinates immediately
    _trackingProvider.resetCoordinates();

    // ✅ Initialize with data from dashboard
    if (widget.initialData != null) {
      final initialLat = widget.initialData!.initialLat ?? 0.0;
      final initialLng = widget.initialData!.initialLng ?? 0.0;
      final initialDir = widget.initialData!.initialDirection ?? 0.0;

      _trackingProvider.initWithDashboardData(
        initialLat,
        initialLng,
        initialDir,
      );

      _lastKnownPosition = LatLng(initialLat, initialLng);
      
      if (widget.initialData!.markerImage != null) {
        _markerIcon = widget.initialData!.markerImage!;
      }
      
      _currentMarker = _makeMarker(
        position: _lastKnownPosition,
        icon: _markerIcon,
        rotation: initialDir,
      );
      
      _markerInitialized = initialLat != 0.0;
    }

    _getVehicleFuelAveragePerKm();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTracking();
    });
  }

  Marker _makeMarker({
    required LatLng position,
    required BitmapDescriptor icon,
    required double rotation,
  }) {
    return Marker(
      markerId: kMarkerId,
      position: position,
      icon: icon,
      anchor: const Offset(0.5, 0.5),
      rotation: rotation,
      flat: true,
      consumeTapEvents: false,
    );
  }

  void _updateMarkerIfNeeded({
    required LatLng newPosition,
    required double newRotation,
    required BitmapDescriptor newIcon,
  }) {
    bool needsUpdate = false;

    if (_lastKnownPosition != newPosition) {
      _lastKnownPosition = newPosition;
      needsUpdate = true;
    }

    if ((_currentMarker.rotation - newRotation).abs() > 1.0) {
      needsUpdate = true;
    }

    if (!identical(newIcon, _markerIcon)) {
      _markerIcon = newIcon;
      needsUpdate = true;
    }

    if (needsUpdate) {
      _currentMarker = _makeMarker(
        position: newPosition,
        icon: _markerIcon,
        rotation: newRotation,
      );
      _markerInitialized = true;
    }
  }

  void _reloadIconIfPathChanged(String newPath) {
    if (newPath.isEmpty || newPath == _lastLoadedIconPath) return;

    _lastLoadedIconPath = newPath;

    MapHelper.getMarkerImageFromUrl(AppUrl.baseImgURL + newPath).then((icon) {
      if (!mounted) return;

      _updateMarkerIfNeeded(
        newPosition: _lastKnownPosition,
        newRotation: _currentMarker.rotation,
        newIcon: icon,
      );
      
      if (mounted) setState(() {});
    }).catchError((e) {
      debugPrint('Icon reload error: $e');
    });
  }

  Future<void> _getVehicleFuelAveragePerKm() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      vehicleFuelAveragePerKm =
          prefs.getDouble('fuelAverage_${widget.initialData!.deviceId}') ??
              13.0;
      currentFuelCost = prefs.getDouble('fuelPrice') ?? 249.5;
    } catch (e) {
      debugPrint('Error loading fuel average: $e');
    }
  }

  void _initializeTracking() {
    if (!mounted || _trackingProvider.isDisposed) return;

    _trackingProvider.startPeriodicRefresh(
      widget.initialData!.deviceId ?? 0,
      context,
      intervalSeconds: 8,
    );

    // ✅ Don't fetch history/alerts if vehicle is already known to be expired from dashboard
    final isExpiredFromDashboard = vehicleStatus.toLowerCase().contains('expired');
    
    if (!isExpiredFromDashboard) {
      _fetchTravelSummaryData(0);

      String deviceIdStr = (widget.initialData!.deviceId ?? 0).toString();
      _alertsProvider.setDeviceIdFilter(deviceIdStr);
      _alertsProvider.setAlertTypeFilter(null);
      _alertsProvider.fetchAlerts(isRefresh: true, context: context);
    }
  }

  void _fetchTravelSummaryData(int days) {
    late String toDate;
    late String fromDate;
    const String fromTime = '00:00:01';
    const String toTime = '23:59:00';
    DateTime dt = DateTime.now();
    DateFormat newFormat = DateFormat("yy-MM-dd");

    switch (days) {
      case 0:
        toDate = fromDate = newFormat.format(dt);
        break;
      case 1:
        final yesterday = dt.subtract(const Duration(days: 1));
        toDate = fromDate = newFormat.format(yesterday);
        break;
      case 7:
        toDate = newFormat.format(dt);
        fromDate = newFormat.format(dt.subtract(const Duration(days: 7)));
        break;
      case 30:
        toDate = newFormat.format(dt);
        fromDate = newFormat.format(dt.subtract(const Duration(days: 30)));
        break;
    }

    _historyProvider.fetchDeviceRouteHistory(
      widget.initialData!.deviceId.toString(),
      fromDate,
      toDate,
      fromTime,
      toTime,
    );
  }

  Future<void> _initializeCamera(VehicleTrackingProvider provider) async {
    if (_mapController == null || !mounted) return;
    try {
      final target = _smoothMarkerPos ?? LatLng(provider.latitude, provider.longitude);

      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: 17.0,
          ),
        ),
      );
      _isCameraInitialized = true;
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  void _updateUIFromProvider(VehicleTrackingProvider provider) {
    mainBoxBackgroundColor = provider.statusColor;
    vehicleStatus = provider.statusText;
    vehicleStatusColor = vehicleStatus == 'Idle' ? Colors.black : Colors.white;
    updateTime = provider.lastUpdate;
    vehicleSpeed = provider.deviceSpeed.toString();
    _animationDuration = const Duration(seconds: 15);

    final iconPath = provider.iconPath;
    if (iconPath.isNotEmpty) {
      _reloadIconIfPathChanged(iconPath);
    }

    final currentPos = LatLng(provider.latitude, provider.longitude);
    final currentCourse = provider.course;

    if (currentPos.latitude != 0.0 || currentPos.longitude != 0.0) {
      _updateMarkerIfNeeded(
        newPosition: currentPos,
        newRotation: currentCourse,
        newIcon: _markerIcon,
      );
    }

    if (provider.sensors != null && provider.sensors!.isNotEmpty) {
      for (var element in provider.sensors!) {
        final name = element.name?.toString().toLowerCase() ?? '';
        final value = element.value?.toString().toLowerCase() ?? '';

        if (name.contains('ignition')) {
          keyColor = value == 'on' ? Colors.green : (value == 'off' ? Colors.red : Colors.grey);
          keyStatus = value == 'on' ? 'ON' : (value == 'off' ? 'OFF' : 'N/A');
        }
        if (name.contains('charging')) {
          batteryChargingColor = value == 'on' ? Colors.green : (value == 'off' ? Colors.red : Colors.grey);
        }
        if (element.type?.toString().toLowerCase() == 'battery') {
          batteryVoltage = element.value?.toString() ?? 'N/A';
        }
        if (name.contains('immobiliser') || name.contains('immobilizer')) {
          immobilizerValue = value == 'on';
          immobilizerStatus = value == 'on'
              ? 'Immobiliser is on'
              : (value == 'off' ? 'Immobiliser is off' : 'Immobiliser is N/A');
        }
      }
    }
  }

  Set<Marker> get _staticMarkers {
    if (!_markerInitialized || _trackingProvider.deviceSpeed > 5) return {};
    return {_currentMarker};
  }

  Set<Marker> get _animatedMarkers {
    if (!_markerInitialized || _trackingProvider.deviceSpeed <= 5) return {};
    return {_currentMarker};
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_trackingProvider.isDisposed) {
      _trackingProvider.fetchDeviceLiveTracking(
        deviceId: widget.initialData!.deviceId ?? 0,
        context: context,
        isRefresh: true,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_trackingProvider.isDisposed) {
      _trackingProvider.stopPeriodicRefresh();
    }
    _mapController?.dispose();
    super.dispose();
  }

  Widget _buildErrorOverlay({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await Future.delayed(const Duration(milliseconds: 200));
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Consumer<VehicleTrackingProvider>(
          builder: (context, provider, _) {
            // 🔄 LOADING STATE (Wait for API response to verify subscription)
            if (provider.isLoading) {
              return const LoadingWidget();
            }

            // 🛑 EXPIRED VEHICLE CHECK (Show full-screen overlay)
            if (provider.isExpired) {
              return _buildErrorOverlay(
                icon: Icons.timer_off_outlined,
                title: 'Vehicle Expired',
                message: 'This vehicle tracking subscription has expired. Please contact support to renew.',
                buttonText: 'Back to List',
                onPressed: () => Navigator.pop(context),
              );
            }

            // 🛑 NOT CONNECTED / NO DATA CHECK
            if (provider.hasNoData) {
              return _buildErrorOverlay(
                icon: Icons.no_sim_outlined,
                title: 'Not Connected',
                message: provider.noDataMessage ?? 'This vehicle has no live location data yet.',
                buttonText: 'Go Back',
                onPressed: () => Navigator.pop(context),
              );
            }

            // 🛑 CONNECTION ERROR CHECK (Only for non-expiry/non-data cases)
            if (provider.errorMessage != null) {
              return _buildErrorOverlay(
                icon: Icons.error_outline_rounded,
                title: 'Connection Error',
                message: provider.errorMessage!,
                buttonText: 'Retry',
                onPressed: () => provider.fetchDeviceLiveTracking(
                  deviceId: widget.initialData!.deviceId ?? 0,
                  context: context,
                ),
              );
            }

            _updateUIFromProvider(provider);

            // ✅ INITIAL CAMERA SETUP (Only once)
            if (!_isCameraInitialized && provider.latitude != 0.0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _initializeCamera(provider);
              });
            }

            return Stack(
              children: [
                // 🗺️ MAP ENGINE
                VehicleAnimatedMarker(
                  key: const ValueKey('animated_marker'),
                  staticMarkers: _staticMarkers,
                  animatedMarkers: _animatedMarkers,
                  duration: _animationDuration,
                  curve: Curves.linear, // Use linear for consistent tracking
                  fps: 30,
                  onMarkerUpdate: (id, pos) {
                    if (id == kMarkerId) {
                      _smoothMarkerPos = pos;
                      
                      // ✅ ALWAYS FOLLOW: Re-center on every marker update
                      // 🔥 BUT: Skip if user is currently zooming or dragging
                      if (_isCameraInitialized && !_isUserInteracting) {
                        _mapController?.moveCamera(CameraUpdate.newLatLng(pos));
                      }
                    }
                  },
                  builder: (context, markers) {
                    return MapWidget(
                      currentMarkers: markers,
                      currentMapType: currentMapType,
                      enableTraffic: enableTraffic,
                      latestLat: provider.latitude,
                      latestLng: provider.longitude,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        controller.setMapStyle(null);
                      },
                      onCameraMove: (pos) => currentZoom = pos.zoom,
                      onCameraMoveStarted: () {},
                      onUserInteractionStarted: () {
                        // ✅ Temporarily pause camera follow to allow smooth zoom
                        setState(() => _isUserInteracting = true);
                      },
                      onUserInteractionEnded: () {
                        // ✅ Resume follow when fingers are lifted
                        setState(() => _isUserInteracting = false);
                      },
                    );
                  },
                ),

                // 🔘 FABs
                FABWidget(
                  latestLat: provider.latitude,
                  latestLng: provider.longitude,
                  enableTraffic: enableTraffic,
                  currentMapType: currentMapType,
                  onMapTypeChanged: () {
                    setState(() {
                      currentMapType = currentMapType == MapType.normal
                          ? MapType.hybrid
                          : MapType.normal;
                    });
                  },
                  onTrafficToggled: () {
                    setState(() => enableTraffic = !enableTraffic);
                  },
                ),

                // 📊 STATUS BAR
                StatusBarWidget(
                  vehicleName: provider.deviceName,
                  updateTime: updateTime,
                  vehicleSpeed: vehicleSpeed,
                  vehicleStatus: vehicleStatus,
                  vehicleStatusColor: vehicleStatusColor,
                  mainBoxBackgroundColor: mainBoxBackgroundColor,
                  runningOrStoppedTime: provider.runningOrStoppedInfoRealTime,
                ),

                // 🔼 SLIDING PANEL
                SlidingUpPanel(
                  minHeight: MediaQuery.of(context).size.height * 0.25,
                  controller: panelController,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
                  color: Colors.white.withOpacity(0.8),
                  panelBuilder: (sc) => SlidingPanelWidget(
                    scrollController: sc,
                    panelController: panelController,
                    initialData: widget.initialData,
                    keyColor: keyColor,
                    keyStatus: keyStatus,
                    batteryChargingColor: batteryChargingColor,
                    batteryVoltage: batteryVoltage,
                    immobilizerValue: immobilizerValue,
                    immobilizerStatus: immobilizerStatus,
                    vehicleFuelAveragePerKm: vehicleFuelAveragePerKm,
                    currentFuelCost: currentFuelCost,
                    deviceId: int.tryParse(provider.deviceId) ?? 0,
                    deviceName: provider.deviceName,
                    stopDurationDisplay: provider.stopDurationDisplay,
                    stopStartStatus: provider.stopStartStatus,
                    onFuelAverageSet: (val) => setState(() => vehicleFuelAveragePerKm = val),
                    onTravelSummaryFetch: _fetchTravelSummaryData,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}