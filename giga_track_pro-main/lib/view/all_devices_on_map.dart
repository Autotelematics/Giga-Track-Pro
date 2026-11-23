import 'dart:async';

import 'package:fluster/fluster.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:trackerapp/providers/all_devices_on_map_provider.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/res/components/app_end_point.dart';
import 'package:trackerapp/res/helper/map_helper.dart';
import 'package:trackerapp/res/helper/map_marker.dart';
import 'package:trackerapp/res/helper/map_marker_design.dart';
import 'package:trackerapp/widgets/common/loading_widget.dart';

class DevicesOnMap extends StatefulWidget {
  const DevicesOnMap({super.key});

  @override
  State<DevicesOnMap> createState() => _DevicesOnMapState();
}

class _DevicesOnMapState extends State<DevicesOnMap> {
  late GoogleMapController _mapController;
  late Completer<GoogleMapController> _controllerCompleter;

  MapType _currentMapType = MapType.normal;
  bool _enableTraffic = false;

  final List<Marker?> _searchMarkers = [];
  final Set<Marker> _mapMarkers = {};

  Fluster<MapMarker>? _clusterManager;
  double _currentZoom = 15;

  static const int _minClusterZoom = 0;
  static const int _maxClusterZoom = 19;
  static const Color _clusterColor = Colors.blue;
  static const Color _clusterTextColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _controllerCompleter = Completer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDeviceMarkers();
    });
  }

  @override
  void dispose() {
    if (!_controllerCompleter.isCompleted) {
      _controllerCompleter.completeError('Disposed');
    } else {
      _mapController.dispose();
    }
    super.dispose();
  }

  void _loadDeviceMarkers() {
    final provider = context.read<AllDevicesOnMapProvider>();
    provider.fetchDeviceMarkersFromApi(context);
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_controllerCompleter.isCompleted) {
      _controllerCompleter.complete(controller);
    }
    _mapController = controller;
  }

  Future<void> _animateCamera(double zoomLevel) async {
    await _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: LatLng(30.219696, 66.982138),
          zoom: 15,
        ),
      ),
    );
  }

  Future<void> _initClusterMarkers(List<Marker> markerList) async {
    final mapMarkers = <MapMarker>[];

    for (final marker in markerList) {
      try {
        final markerImage = await MapHelper.getMarkerImageFromUrl(
          AppUrl.baseImgURL + marker.infoWindow.snippet.toString(),
        );

        final markerWithTitle = await MapMarkerMaker.getMarkerIcon(
          AppUrl.baseImgURL + marker.infoWindow.snippet.toString(),
          marker.infoWindow.title.toString(),
          Colors.red,
          marker.rotation,
          true,
        );

        mapMarkers.add(
          MapMarker(
            id: marker.markerId.toString(),
            position: marker.position,
            icon: markerWithTitle,
            rotation: marker.rotation,
            onTap: marker.onTap,
          ),
        );
      } catch (e) {
        debugPrint('⚠️ Error processing marker: $e');
        continue;
      }
    }

    _clusterManager = await MapHelper.initClusterManager(
      mapMarkers,
      _minClusterZoom,
      _maxClusterZoom,
    );

    await _updateClusterMarkers();
  }

  Future<void> _updateClusterMarkers([double? zoom]) async {
    if (_clusterManager == null || zoom == _currentZoom) return;

    if (zoom != null) {
      _currentZoom = zoom;
    }

    final updatedMarkers = await MapHelper.getClusterMarkers(
      _clusterManager,
      _currentZoom,
      _clusterColor,
      _clusterTextColor,
      80,
    );

    if (mounted) {
      setState(() {
        _mapMarkers
          ..clear()
          ..addAll(updatedMarkers);
      });
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType =
      _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal;
    });
  }

  void _toggleTraffic() {
    setState(() {
      _enableTraffic = !_enableTraffic;
    });
  }
  Widget _buildLoadingState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingWidget(),
            const SizedBox(height: 16),
            const Text(
              'Loading devices...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage, VoidCallback onRetry) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(VoidCallback onRefresh) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No devices found on map',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'There are no vehicles available to display.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.only(top: 5),
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color.fromARGB(220, 255, 255, 255),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GFSearchBar(
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        searchList: _searchMarkers,
        searchQueryBuilder: (query, list) {
          return list
              .where((item) =>
          item?.infoWindow.title
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()) ??
              false)
              .toList();
        },
        overlaySearchListHeight: MediaQuery.of(context).size.height * 0.60,
        noItemsFoundWidget: const ListTile(
          title: Text('No vehicle found. Please search again.'),
        ),
        overlaySearchListItemBuilder: (item) {
          return ListTile(
            title: Text(item?.infoWindow.title.toString() ?? 'Unknown'),
            trailing: const Icon(Icons.arrow_forward),
            leading: const Icon(Icons.directions_car),
          );
        },
        searchBoxInputDecoration: const InputDecoration(
          hintText: 'Search vehicle...',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
        ),
        onItemSelected: (item) => item?.onTap?.call(),
      ),
    );
  }

  Widget _buildMapButtons() {
    return Positioned(
      right: 10,
      top: 150,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: 'map_type_toggle',
            mini: true,
            backgroundColor: AppColors.buttonColor,
            onPressed: _toggleMapType,
            tooltip: 'Toggle map type',
            child: const Icon(Icons.map, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'traffic_toggle',
            mini: true,
            backgroundColor: _enableTraffic ? Colors.green : AppColors.buttonColor,
            onPressed: _toggleTraffic,
            tooltip: 'Toggle traffic',
            child: const Icon(Icons.traffic, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent(AllDevicesOnMapProvider provider) {
    _searchMarkers.clear();
    _searchMarkers.addAll(provider.markersList);

    if (_clusterManager == null) {
      _initClusterMarkers(provider.markersList);
    }

    return Expanded(
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(30.229696, 66.982138),
              zoom: 6,
            ),
            onMapCreated: _onMapCreated,
            mapType: _currentMapType,
            compassEnabled: false,
            trafficEnabled: _enableTraffic,
            mapToolbarEnabled: true,
            zoomControlsEnabled: true,
            onCameraMove: (position) => _updateClusterMarkers(position.zoom),
            markers: _mapMarkers,
          ),
          _buildSearchBar(),
          _buildMapButtons(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor:Colors.white,
        body: Column(
          children: [
            Consumer<AllDevicesOnMapProvider>(
              builder: (context, provider, _) {
                // Use the new when() method for cleaner state handling
                provider.deviceListMarkers.when(
                  onLoading: () {},
                  onSuccess: (_) {},
                  onError: (error) {},
                );

                if (provider.isLoading) {
                  return _buildLoadingState();
                }

                if (provider.hasError) {
                  return _buildErrorState(
                    provider.errorMessage,
                        () => provider.retryFetchMarkers(context),
                  );
                }

                if (provider.markersList.isEmpty) {
                  return _buildEmptyState(
                    () => provider.retryFetchMarkers(context),
                  );
                }

                return _buildMapContent(provider);
              },
            ),
          ],
        ),
      ),
    );
  }
}