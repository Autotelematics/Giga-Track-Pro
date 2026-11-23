import 'dart:async';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:trackerapp/data/response/status.dart';
import 'package:trackerapp/models/device_history_on_map.dart';
import 'package:trackerapp/models/track_play_rout_model.dart';
import 'package:trackerapp/providers/get_device_history_provider.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/utils/date_time_extension.dart';

class HistoryPlayRoutOnMap extends StatefulWidget {
  final DeviceHistoryOnMapInitialData? initialData;

  const HistoryPlayRoutOnMap(this.initialData, {super.key});

  @override
  State<HistoryPlayRoutOnMap> createState() => _HistoryPlayRoutOnMapState();
}

class _HistoryPlayRoutOnMapState extends State<HistoryPlayRoutOnMap>
    with SingleTickerProviderStateMixin {
  final panelController = PanelController();
  final _mapController = Completer<GoogleMapController>();

  Timer? _timerPlayBack;
  bool _isPlaying = false;
  double _currentZoom = 14.5;

  MapType _currentMapType = MapType.normal;
  IconData _playingIcon = Icons.play_circle_outline;

  late String fromDateStr, toDateStr;

  static const double _zoomPlaying = 19.0;
  static const double _zoomPaused = 14.5;

  final _fabMapKey = UniqueKey();
  final _fabBackKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    final d = widget.initialData!;

    // === FIXED: Robust date parsing (prevents crash on Custom Date & Yesterday) ===
    try {
      // Original format used by Today / 3/7/30 days
      final fmt = DateFormat('yy-MM-dd');
      fromDateStr = DateFormat('dd-MM-yy').format(fmt.parse(d.fromDate!));
      toDateStr = DateFormat('dd-MM-yy').format(fmt.parse(d.toDate!));
    } catch (_) {
      // Fallback for Custom Date and Yesterday (usually yyyy-MM-dd)
      try {
        final parsedFrom = DateTime.parse(d.fromDate!);
        final parsedTo = DateTime.parse(d.toDate!);
        fromDateStr = DateFormat('dd-MM-yy').format(parsedFrom);
        toDateStr = DateFormat('dd-MM-yy').format(parsedTo);
      } catch (__) {
        // Ultimate safe fallback
        fromDateStr = d.fromDate ?? 'N/A';
        toDateStr = d.toDate ?? 'N/A';
      }
    }

    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HistoryPlayRoutOnMapProvider>().fetchDeviceRouteHistory(
          d.deviceId.toString(),
          d.fromDate!,
          d.toDate!,
          d.fromTime!,
          d.toTime!,
        );
      }
    });
  }

  @override
  void dispose() {
    _timerPlayBack?.cancel();
    super.dispose();
  }

  Timer _createRepeatingTimer(
      Duration duration,
      Function(Timer) callback,
      ) {
    Timer makeTimer() {
      final t = Timer(duration, makeTimer);
      callback(t);
      return t;
    }
    return Timer(duration, makeTimer);
  }

  void _startPlayback(HistoryPlayRoutOnMapProvider provider) {
    void tick() {
      if (!_isPlaying || !mounted) return;

      final max = provider.routeList.length - 1;
      if (provider.currentSliderValue < max) {
        provider.playUsingSlider(provider.currentSliderValue + 1);
        _moveCameraWithZoom(
          provider.routeList[provider.currentSliderValue],
          _zoomPlaying,
        );

        // ✅ Re-calculate duration for every step to allow real-time speed changes
        final speedMs = provider.playBackTimeSpeed[provider.selectedPlayBackSpeed];
        _timerPlayBack = Timer(Duration(milliseconds: speedMs), tick);
      } else {
        provider.playUsingSlider(0);
        if (provider.routeList.isNotEmpty) {
          _moveCameraWithZoom(provider.routeList[0], _zoomPlaying);
        }
        _stopPlayback();
      }
    }

    // Start first step
    tick();
  }

  void _stopPlayback() {
    _timerPlayBack?.cancel();
    setState(() {
      _isPlaying = false;
      _playingIcon = Icons.play_circle_outline;
    });
    // ✅ Show full route when stopped
    final provider = context.read<HistoryPlayRoutOnMapProvider>();
    _showFullRoute(provider);
  }

  void _togglePlayPause(HistoryPlayRoutOnMapProvider provider) {
    if (_isPlaying) {
      _timerPlayBack?.cancel();
      setState(() {
        _isPlaying = false;
        _playingIcon = Icons.play_circle_outline;
      });
      // ✅ Show full route when paused
      _showFullRoute(provider);
    } else {
      setState(() {
        _isPlaying = true;
        _playingIcon = Icons.pause_circle_outline;
        _currentZoom = _zoomPlaying;
      });
      _startPlayback(provider);
    }
  }

  // ✅ NEW: Method to fit the entire route on the screen
  void _showFullRoute(HistoryPlayRoutOnMapProvider provider) async {
    if (provider.polyLatLng.isEmpty) return;
    try {
      final controller = await _mapController.future;
      double minLat = provider.polyLatLng.first.latitude;
      double maxLat = provider.polyLatLng.first.latitude;
      double minLng = provider.polyLatLng.first.longitude;
      double maxLng = provider.polyLatLng.first.longitude;

      for (var p in provider.polyLatLng) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }

      controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          70, // Padding
        ),
      );
    } catch (_) {}
  }

  void _moveCameraWithZoom(dynamic pos, double zoom) async {
    final lat = double.tryParse(pos.latitude?.toString() ?? '');
    final lng = double.tryParse(pos.longitude?.toString() ?? '');
    if (lat == null || lng == null) return;

    try {
      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: zoom),
        ),
      );
    } catch (_) {}
  }

  void _moveCamera(dynamic pos) => _moveCameraWithZoom(pos, _currentZoom);

  void _onCameraMove(CameraPosition position) =>
      _currentZoom = position.zoom;

  Widget _buildLoading() => const Expanded(
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(color: Colors.red),
          ),
          SizedBox(height: 16),
          Text(
            'Loading route history...',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    ),
  );

  Widget _buildError(String message) => Expanded(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildEmptyMap(HistoryPlayRoutOnMapProvider provider) => Expanded(
    child: Stack(
      children: [
        _buildGoogleMap(
          provider,
          const CameraPosition(target: LatLng(0.0, 0.0), zoom: 5),
        ),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width - 30,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning,
                  size: 48,
                  color: Colors.amber,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No record found',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No GPS data available for the selected date and time range.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                GFButton(
                  onPressed: () => Navigator.pop(context),
                  text: 'Back',
                  textColor: Colors.black87,
                  size: GFSize.SMALL,
                  shape: GFButtonShape.pills,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildMapView(HistoryPlayRoutOnMapProvider provider) => Expanded(
    child: Stack(
      children: [
        _buildGoogleMap(
          provider,
          CameraPosition(
            target: provider.polyLatLng.first,
            zoom: _currentZoom,
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.35,
          ),
        ),
        _buildMapButtons(),
        SlidingUpPanel(
          minHeight: MediaQuery.of(context).size.height * 0.35,
          maxHeight: MediaQuery.of(context).size.height,
          controller: panelController,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
          padding: const EdgeInsets.fromLTRB(15, 5, 15, 0),
          color: const Color.fromARGB(166, 255, 255, 255),
          panelBuilder: (sc) => _buildSlidingPanel(sc, provider),
        ),
      ],
    ),
  );

  Widget _buildGoogleMap(
      HistoryPlayRoutOnMapProvider provider,
      CameraPosition initialPos, {
        EdgeInsets? padding,
      }) =>
      GoogleMap(
        zoomControlsEnabled: false,
        initialCameraPosition: initialPos,
        markers: Set<Marker>.of(provider.mapMarkers),
        onMapCreated: (GoogleMapController controller) {
          if (!_mapController.isCompleted) {
            _mapController.complete(controller);
          }
          if (provider.routeList.isNotEmpty) {
            provider.applyMarkersOnMap();
            // ✅ Show full route initially
            _showFullRoute(provider);
          }
        },
        onCameraMove: _onCameraMove,
        mapType: _currentMapType,
        polylines: provider.routPolyLine,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        padding: padding ?? EdgeInsets.zero,
      );

  Widget _buildMapButtons() => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.34),
          _buildFAB(
            Icons.map,
            heroTag: _fabMapKey,
            onPressed: () {
              setState(() {
                _currentMapType = _currentMapType == MapType.normal
                    ? MapType.hybrid
                    : MapType.normal;
              });
              context.read<HistoryPlayRoutOnMapProvider>().resetGoogleMap();
            },
          ),
          _buildFAB(
            Icons.arrow_back,
            heroTag: _fabBackKey,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ],
  );

  Widget _buildFAB(
      IconData icon, {
        required Key heroTag,
        required VoidCallback onPressed,
      }) =>
      Padding(
        padding: const EdgeInsets.all(6),
        child: FloatingActionButton(
          mini: true,
          heroTag: heroTag,
          backgroundColor: AppColors.buttonColor,
          onPressed: onPressed,
          child: Icon(icon, color: Colors.black54),
        ),
      );

  Widget _buildSlidingPanel(
      ScrollController sc,
      HistoryPlayRoutOnMapProvider provider,
      ) =>
      ListView(
        controller: sc,
        children: [
          _buildDragHandle(),
          _buildInfoCard(provider),
          _buildTripsList(provider),
          const SizedBox(height: 20),
        ],
      );

  Widget _buildDragHandle() => InkWell(
    onTap: () => panelController.isPanelOpen
        ? panelController.close()
        : panelController.open(),
    child: Center(
      child: Container(
        height: 5,
        width: 30,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
  );

  Widget _buildInfoCard(HistoryPlayRoutOnMapProvider provider) => Container(
    width: MediaQuery.of(context).size.width - 30,
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          blurRadius: 2,
          color: Colors.grey.withOpacity(0.3),
        )
      ],
    ),
    child: Column(
      children: [
        _buildDateRow(provider),
        const Divider(),
        _buildStatsRow(provider),
        const Divider(),
        _buildPlaybackControls(provider),
        const Divider(),
        _buildSummaryRow(provider),
        const Divider(),
        _buildProgressBars(provider),
      ],
    ),
  );

  Widget _buildDateRow(HistoryPlayRoutOnMapProvider provider) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _buildLabelWithIcon(Icons.calendar_month_outlined, 'From:', fromDateStr),
      Container(
        decoration: BoxDecoration(
          color: Colors.amber[700],
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(
          provider.deviceName.isNotEmpty ? provider.deviceName : 'Vehicle',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      _buildLabelWithIcon(Icons.calendar_month_outlined, 'To:', toDateStr),
    ],
  );

  Widget _buildLabelWithIcon(IconData icon, String label, String val) => Row(
    children: [
      Icon(icon, color: Colors.grey, size: 16),
      const SizedBox(width: 6),
      Text.rich(
        TextSpan(
          text: label,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
          children: [
            TextSpan(
              text: ' $val',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  // All remaining methods are unchanged
  Widget _buildStatsRow(HistoryPlayRoutOnMapProvider provider) {
    if (provider.routeList.isEmpty) return const SizedBox.shrink();

    final r = provider.routeList[provider.currentSliderValue];
    final speed = r.speed ?? 0;
    final distance = double.tryParse(r.distance?.toString() ?? '0') ?? 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildIconRichText(Icons.speed, '$speed', 'km/h'),
        _buildIconRichText(Icons.access_alarm, r.time?.toFormattedDateTime() ?? '-', ''),
        _buildIconRichText(
          Icons.directions_run_outlined,
          distance.toStringAsFixed(2),
          'km',
        ),
      ],
    );
  }

  Widget _buildIconRichText(IconData icon, String bold, String normal) => Row(
    children: [
      Icon(icon, color: Colors.grey, size: 16),
      const SizedBox(width: 6),
      RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          text: bold,
          children: [
            TextSpan(
              text: normal.isNotEmpty ? ' $normal' : '',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildPlaybackControls(HistoryPlayRoutOnMapProvider provider) {
    final maxVal = provider.sliderValueMax.toDouble();
    final curVal = provider.currentSliderValue.toDouble().clamp(0.0, maxVal);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _togglePlayPause(provider),
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(4),
              backgroundColor: Colors.grey[200],
            ),
            child: Icon(_playingIcon, size: 28, color: Colors.black54),
          ),
        ),
        Expanded(
          flex: 5,
          child: Slider(
            activeColor: Colors.grey[400],
            thumbColor: Colors.grey[400],
            divisions: maxVal > 0 ? maxVal.toInt() : 1,
            min: 0,
            max: maxVal > 0 ? maxVal : 1,
            value: curVal,
            onChanged: (v) {
              final idx = v.round().toInt().clamp(0, provider.sliderValueMax);
              provider.playUsingSlider(idx);
              if (provider.routeList.isNotEmpty) {
                _moveCamera(provider.routeList[idx]);
              }
            },
          ),
        ),
        Expanded(
          child: ElevatedButton(
            onPressed: () => provider.setPlayBackSpeed(),
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(4),
              backgroundColor: Colors.grey[200],
            ),
            child: Text(
              '${provider.selectedPlayBackSpeed + 1}x',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(HistoryPlayRoutOnMapProvider provider) {
    final data = provider.deviceRoutHistoryResponse.data;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSummaryText('Total Distance:', '${data?.distanceSum ?? '-'}'),
        _buildSummaryText('Max Speed:', '${data?.topSpeed ?? '-'}'),
      ],
    );
  }

  Widget _buildSummaryText(String label, String val) => RichText(
    text: TextSpan(
      style: const TextStyle(color: Colors.grey, fontSize: 11),
      text: label,
      children: [
        TextSpan(
          text: ' $val',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _buildProgressBars(HistoryPlayRoutOnMapProvider provider) {
    final data = provider.deviceRoutHistoryResponse.data;
    return Row(
      children: [
        _buildProgressTile(
          color: Colors.green,
          bgColor: Colors.green[50]!,
          label: 'Travel (${provider.tripCount})',
          duration: '${data?.moveDuration ?? '-'}',
        ),
        _buildProgressTile(
          color: Colors.red,
          bgColor: Colors.red[50]!,
          label: 'Stops (${provider.stopCount})',
          duration: '${data?.stopDuration ?? '-'}',
        ),
      ],
    );
  }

  Widget _buildProgressTile({
    required Color color,
    required Color bgColor,
    required String label,
    required String duration,
  }) =>
      Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              GFProgressBar(
                margin: const EdgeInsets.all(2),
                percentage: 0.6,
                lineHeight: 4,
                backgroundColor: Colors.black12,
                progressBarColor: color,
              ),
              const SizedBox(height: 4),
              Text(
                duration,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildTripsList(HistoryPlayRoutOnMapProvider provider) =>
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: provider.tripsList.length,
        itemBuilder: (context, index) {
          final trip = provider.tripsList[index];
          return _buildTripCard(provider, trip);
        },
      );

  Widget _buildTripCard(
      HistoryPlayRoutOnMapProvider provider,
      TripsRoutModel trip,
      ) =>
      InkWell(
        onTap: () => _onTripTapped(provider, trip),
        child: Card(
          shape: AppColors.cardBorderShape,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDistanceLabel(trip.distance),
                    _buildStatusBadge(trip.status ?? 0),
                    _buildSpeedLabel(trip.topSpeed),
                  ],
                ),
                const Divider(height: 12),
                _buildTripRow(
                  Icons.play_circle_outline,
                  'Start:',
                  trip.tripStart?.toString() ?? '-',
                ),
                const Divider(height: 8),
                _buildTripRow(
                  Icons.access_time,
                  'Duration:',
                  trip.totalTripDuration?.toString() ?? '-',
                ),
                const Divider(height: 8),
                _buildTripRow(
                  Icons.stop_circle_outlined,
                  'End:',
                  trip.tripEnd?.toString() ?? '-',
                ),
              ],
            ),
          ),
        ),
      );

  void _onTripTapped(HistoryPlayRoutOnMapProvider provider, TripsRoutModel trip) {
    panelController.close();

    if (trip.status == 2) {
      _currentZoom = 19.0;
      if (trip.tripPlayBackRout.isNotEmpty) {
        _moveCameraWithZoom(trip.tripPlayBackRout[0], 19.0);
      }
    } else if (trip.status == 1) {
      _currentZoom = _zoomPaused;
      provider
        ..removeSingleRoutPolyLineLatLng()
        ..setSingleRoutPolyLineLatLng(trip.tripRoutLatLng);

      if (trip.tripPlayBackRout.isNotEmpty) {
        _moveCameraWithZoom(trip.tripPlayBackRout.first, _zoomPaused);
      }

      if (trip.tripRoutLatLng.isNotEmpty) {
        final firstLat = trip.tripRoutLatLng.first.latitude.toString();
        final firstLng = trip.tripRoutLatLng.first.longitude.toString();
        final idx = provider.routeList.indexWhere(
              (r) => r.latitude == firstLat && r.longitude == firstLng,
        );
        if (idx >= 0) provider.playUsingSlider(idx);
      }
    }
  }

  Widget _buildDistanceLabel(dynamic distance) => Row(
    children: [
      const Icon(Icons.directions_run_outlined, size: 16, color: Colors.grey),
      const SizedBox(width: 6),
      Text(
        'Distance: $distance km',
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  Widget _buildSpeedLabel(dynamic topSpeed) => Row(
    children: [
      const Icon(Icons.speed, size: 16, color: Colors.grey),
      const SizedBox(width: 6),
      Text(
        'Max: $topSpeed kph',
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  Widget _buildStatusBadge(int status) => Container(
    decoration: BoxDecoration(
      color: status == 1 ? Colors.green : Colors.orange,
      borderRadius: BorderRadius.circular(6),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Text(
      status == 1 ? 'Trip' : 'Stop',
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );

  Widget _buildTripRow(IconData icon, String label, String val) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
      Text(
        val,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<HistoryPlayRoutOnMapProvider>(
              builder: (context, provider, _) {
                switch (provider.deviceRoutHistoryResponse.status) {
                  case Status.LOADING:
                    return _buildLoading();

                  case Status.ERROR:
                    return _buildError(provider.errorMessage);

                  case Status.COMPLETED:
                    return provider.routeList.isEmpty
                        ? _buildEmptyMap(provider)
                        : _buildMapView(provider);
                  }
              },
            ),
          ],
        ),
      ),
    );
  }
}