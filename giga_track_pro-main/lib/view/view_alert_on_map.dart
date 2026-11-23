import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:trackerapp/models/event_on_map_model.dart';
import 'package:trackerapp/models/get_alerts_list_model.dart';
import 'package:trackerapp/providers/user_login_provider.dart';
import 'package:trackerapp/repository/get_alert_list_repository.dart';
import 'package:trackerapp/res/colors.dart';

class EventsOnMap extends StatefulWidget {
  final EventOnMapDataModel eventOnMapDataModel;
  const EventsOnMap(this.eventOnMapDataModel, {super.key});

  @override
  State<EventsOnMap> createState() => _EventsOnMapState();
}

class _EventsOnMapState extends State<EventsOnMap> {
  final AlertsRepository _alertsRepository = AlertsRepository();
  final List<Marker> _markers = [];
  GoogleMapController? _controller;

  bool _isLoading = true;
  late String _vehicleName;
  late String _message;
  late String _address;
  late String _speed;
  late String _eventTimeStr;
  late double _lat;
  late double _lng;

  @override
  void initState() {
    super.initState();
    _initDataFromWidget();
    _initializeMarkers();
    _fetchAlertDetailsFromApi();
  }

  void _initDataFromWidget() {
    _vehicleName = widget.eventOnMapDataModel.vehiclename?.toString() ?? 'Vehicle';
    _message = widget.eventOnMapDataModel.message?.toString() ?? 'Alert Notification';
    _address = widget.eventOnMapDataModel.address ?? 'Address not available';
    _speed = widget.eventOnMapDataModel.speed?.toString() ?? '0';
    _eventTimeStr = widget.eventOnMapDataModel.eventtime?.toString() ?? '';
    _lat = double.tryParse(widget.eventOnMapDataModel.intialLat.toString()) ?? 24.945273;
    _lng = double.tryParse(widget.eventOnMapDataModel.intiallng.toString()) ?? 67.095811;
  }

  void _initializeMarkers() {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('1'),
        position: LatLng(_lat, _lng),
        infoWindow: InfoWindow(
          title: _vehicleName,
          snippet: _message,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  Future<void> _fetchAlertDetailsFromApi() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiKey = await UserLoginProvider().getUserApiHashString();
      final deviceIdStr = widget.eventOnMapDataModel.deviceId?.toString();

      final result = await _alertsRepository.getAlerts(
        page: 1,
        userApiHashKey: apiKey,
        deviceId: deviceIdStr,
      );

      if (result != null && result.items.isNotEmpty) {
        Item? matchedItem;

        // 1. Try to match by exact message or device name
        for (final item in result.items) {
          if (item.message.toLowerCase() == _message.toLowerCase() ||
              (_vehicleName.isNotEmpty &&
                  item.deviceName.toLowerCase().contains(_vehicleName.toLowerCase()))) {
            matchedItem = item;
            break;
          }
        }

        // 2. If no exact match, pick the latest alert item
        matchedItem ??= result.items.first;

        _vehicleName = matchedItem.deviceName.isNotEmpty
            ? matchedItem.deviceName
            : _vehicleName;
        _message = matchedItem.message.isNotEmpty
            ? matchedItem.message
            : _message;
        _address = matchedItem.address.isNotEmpty
            ? matchedItem.address
            : _address;
        _speed = matchedItem.speed.toString();
        if (matchedItem.latitude != 0.0) _lat = matchedItem.latitude;
        if (matchedItem.longitude != 0.0) _lng = matchedItem.longitude;

        if (matchedItem.time != null) {
          _eventTimeStr = matchedItem.time!.toIso8601String();
        }

        _initializeMarkers();

        if (_controller != null) {
          _controller!.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(_lat, _lng), 16),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching alert details from API: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatTo12HourDateTime(String rawTime) {
    if (rawTime.trim().isEmpty || rawTime == '-') return 'Time not available';
    try {
      final dt = DateTime.parse(rawTime);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {}
    try {
      final dt = DateFormat('yyyy-MM-dd HH:mm:ss').parse(rawTime);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {}
    return rawTime;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _handleBackNavigation() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = _formatTo12HourDateTime(_eventTimeStr);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: _handleBackNavigation,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            minMaxZoomPreference: const MinMaxZoomPreference(1, 21),
            initialCameraPosition: CameraPosition(
              target: LatLng(_lat, _lng),
              zoom: 16,
            ),
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: Set<Marker>.of(_markers),
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              _controller?.showMarkerInfoWindow(const MarkerId('1'));
            },
            padding: const EdgeInsets.only(bottom: 220),
          ),

          // Modern Info Panel
          Positioned(
            bottom: 20,
            left: 15,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Zoom buttons
                Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'zoom_in',
                      onPressed: () => _controller?.animateCamera(CameraUpdate.zoomIn()),
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.add, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'zoom_out',
                      onPressed: () => _controller?.animateCamera(CameraUpdate.zoomOut()),
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.remove, color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Main Details Card (Shimmer while loading)
                _isLoading
                    ? _buildShimmerDetailsCard()
                    : Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _vehicleName,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time_rounded,
                                                  size: 15,
                                                  color: Colors.blue.shade700,
                                                ),
                                                const SizedBox(width: 5),
                                                Expanded(
                                                  child: Text(
                                                    formattedTime,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.blue.shade700,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              _speed,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const Text(
                                              'km/h',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Divider(height: 28),

                                  // Alert Message Section
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.notifications_active_rounded,
                                          color: Colors.red,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Alert Message',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _message,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Location Section
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.location_on_rounded,
                                          color: Colors.blue,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Event Location',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _address,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(width: 140, height: 18),
                  const SizedBox(height: 8),
                  _shimmerBox(width: 160, height: 14),
                ],
              ),
              _shimmerBox(width: 50, height: 45, radius: 12),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              _shimmerBox(width: 40, height: 40, radius: 20),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(width: 80, height: 12),
                  const SizedBox(height: 6),
                  _shimmerBox(width: 180, height: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _shimmerBox(width: 40, height: 40, radius: 20),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(width: 90, height: 12),
                  const SizedBox(height: 6),
                  _shimmerBox(width: 200, height: 14),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    double radius = 6,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
