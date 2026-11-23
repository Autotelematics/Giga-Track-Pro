import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatefulWidget {
  final Set<Marker> currentMarkers;
  final MapType currentMapType;
  final bool enableTraffic;
  final double latestLat;
  final double latestLng;
  final Function(GoogleMapController) onMapCreated;
  final Function(CameraPosition) onCameraMove;
  final VoidCallback onCameraMoveStarted;
  final VoidCallback? onUserInteractionStarted; // ✅ Detect start of touch
  final VoidCallback? onUserInteractionEnded;   // ✅ Detect end of touch

  const MapWidget({
    super.key,
    required this.currentMarkers,
    required this.currentMapType,
    required this.enableTraffic,
    required this.latestLat,
    required this.latestLng,
    required this.onMapCreated,
    required this.onCameraMove,
    required this.onCameraMoveStarted,
    this.onUserInteractionStarted,
    this.onUserInteractionEnded,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // ✅ Use Listener to detect touch without blocking zoom gestures
      onPointerDown: (_) => widget.onUserInteractionStarted?.call(),
      onPointerUp: (_) => widget.onUserInteractionEnded?.call(),
      onPointerCancel: (_) => widget.onUserInteractionEnded?.call(),
      child: GoogleMap(
        buildingsEnabled: false,
        indoorViewEnabled: false,
        rotateGesturesEnabled: true,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomGesturesEnabled: true, 
        scrollGesturesEnabled: true,
        tiltGesturesEnabled: true,
        minMaxZoomPreference: const MinMaxZoomPreference(1, 21),
        mapType: widget.currentMapType,
        trafficEnabled: widget.enableTraffic,
        markers: widget.currentMarkers,
        zoomControlsEnabled: false,
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.latestLat, widget.latestLng),
          zoom: 17,
        ),
        onCameraMove: widget.onCameraMove,
        onCameraMoveStarted: widget.onCameraMoveStarted,
        onMapCreated: (controller) {
          _mapController = controller;
          widget.onMapCreated(controller);
        },
        padding: const EdgeInsets.only(bottom: 250, top: 100),
      ),
    );
  }
}