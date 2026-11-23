import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'package:trackerapp/models/device_on_map_model.dart';
import 'package:trackerapp/models/get_device_list_model.dart';
import 'package:trackerapp/providers/get_devices_list_provider.dart';
import 'package:trackerapp/repository/get_devices_list_repository.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/res/components/app_end_point.dart';
import 'package:trackerapp/res/helper/map_helper.dart';
import 'package:trackerapp/utils/routes/routes_name.dart';
import 'package:trackerapp/utils/string_extensions.dart';
import 'package:trackerapp/widgets/common/loading_widget.dart';

class _StatusItem {
  final String label, filter;
  final Color color;
  final int count, position;
  const _StatusItem(this.label, this.filter, this.color, this.count, this.position);
}

class _VehicleStyle {
  final Color bg, statusColor;
  final String label;
  const _VehicleStyle(this.bg, this.statusColor, this.label);
}

class DevicesListDashboard extends StatelessWidget {
  const DevicesListDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StatusDashboardBody();
  }
}

class _StatusDashboardBody extends StatefulWidget {
  const _StatusDashboardBody();

  @override
  State<_StatusDashboardBody> createState() => _StatusDashboardBodyState();
}

class _StatusDashboardBodyState extends State<_StatusDashboardBody> {
  List<BitmapDescriptor> _markers = [];
  int _filterPos = 0;
  String _selectedLanguage = 'English';

  // Focus management
  late final FocusNode _searchFocusNode;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GetDevicesListProvider>().init(context);
      // Unfocus search field after initial load
      _searchFocusNode.unfocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _setMarker(int i, String iconPath) async {
    if (iconPath.isEmpty) return;

    final bmp = await MapHelper.getMarkerImageFromUrl(
      AppUrl.baseImgURL + iconPath,
    );

    if (!mounted) return;

    if (i < _markers.length) {
      _markers[i] = bmp;
    }
  }

  _VehicleStyle _styleFor(String? status, String? time) {
    final s = status?.toLowerCase() ?? '';
    final t = time?.toLowerCase() ?? '';

    if (s == 'offline' && t == 'expired') {
      return _VehicleStyle(const Color(0xFFFFEBEE), Colors.red, 'Expired');
    }
    if (s == 'offline' && t == 'not connected') {
      return _VehicleStyle(const Color(0xFFE0E0E0), Colors.black54, 'No Data');
    }
    if (s == 'offline') {
      return _VehicleStyle(const Color(0xFFD5EEFF), Colors.blue, 'Offline');
    }
    if (s == 'online') {
      return _VehicleStyle(const Color(0xFFCEF8CD), Colors.green, 'Driving');
    }
    if (s == 'ack') {
      return _VehicleStyle(const Color(0xFFFAD0D0), Colors.red, 'Stop');
    }
    if (s == 'engine') {
      return _VehicleStyle(const Color(0xFFFFF2AE), Colors.orange, 'Idle');
    }

    return _VehicleStyle(const Color(0xFFD5D8DA), Colors.black87, 'Unknown');
  }

  Map<String, dynamic> _parseSensors(List<Sensor>? sensors) {
    Color keyColor = Colors.grey;
    Color chargeColor = Colors.grey;
    bool immobilizer = false;
    String battery = 'n/a';

    for (final s in sensors ?? []) {
      final name = s.name?.toLowerCase().trim() ?? '';
      final val = s.value?.toLowerCase() ?? '';

      if (name == 'ignition') {
        keyColor = val == 'on'
            ? Colors.green
            : val == 'off'
            ? Colors.red
            : Colors.grey;
      }

      if (s.type?.toLowerCase() == 'battery') {
        battery = s.value ?? 'n/a';
      }

      if (name == 'charging') {
        chargeColor = val == 'on'
            ? Colors.green
            : val == 'off'
            ? Colors.red
            : Colors.grey;
      }

      if (name == 'immobiliser' || name == 'immobilizer') {
        immobilizer = val == 'on';
      }
    }

    return {
      'key': keyColor,
      'charge': chargeColor,
      'immobilizer': immobilizer,
      'battery': battery,
    };
  }

  double _parseLat(dynamic v) =>
      (v == null || v == 0) ? 24.945273 : double.tryParse(v.toString()) ?? 24.945273;

  double _parseLng(dynamic v) =>
      (v == null || v == 0) ? 67.095811 : double.tryParse(v.toString()) ?? 67.095811;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: GestureDetector(
          // Tap anywhere to dismiss keyboard
          onTap: () {
            _searchFocusNode.unfocus();
          },
          child: Column(
            children: [
              // ---------------- SEARCH BAR WITH DROPDOWN ----------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // Search Field
                    Expanded(
                      child: TextField(
                        focusNode: _searchFocusNode,
                        controller: _searchController,
                        onChanged: (value) {
                          context.read<GetDevicesListProvider>().updateSearchQuery(value);
                        },
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search vehicle...',
                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                          suffixIcon: IconButton(
                            onPressed: () {
                              _searchController.clear();
                              context.read<GetDevicesListProvider>().updateSearchQuery('');
                              _searchFocusNode.unfocus();
                            },
                            icon: const Icon(Icons.close_rounded, color: Colors.grey),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Language Dropdown Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLanguage,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          items: const [
                            DropdownMenuItem<String>(
                              value: 'English',
                              child: Row(
                                children: [
                                  Text('🇬🇧'),
                                  SizedBox(width: 6),
                                  Text('English'),
                                ],
                              ),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Urdu',
                              child: Row(
                                children: [
                                  Text('🇵🇰'),
                                  SizedBox(width: 6),
                                  Text('اردو'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (String? value) {
                            setState(() {
                              _selectedLanguage = value!;
                            });
                            _searchFocusNode.unfocus();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Consumer<GetDevicesListProvider>(
                builder: (_, provider, __) => _buildFilterBar(provider),
              ),

              Consumer<GetDevicesListProvider>(
                builder: (_, provider, __) => _buildBody(provider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(GetDevicesListProvider provider) {
    final items = [
      _StatusItem('Total', 'all', Colors.brown, provider.getCountForStatus('all'), 0),
      _StatusItem('Running', 'running', Colors.green, provider.getCountForStatus('running'), 1),
      _StatusItem('Stop', 'stopped', Colors.red, provider.getCountForStatus('stopped'), 2),
      _StatusItem('Idle', 'idle', Colors.yellow, provider.getCountForStatus('idle'), 3),
      _StatusItem('Offline', 'offline', Colors.blue, provider.getCountForStatus('offline'), 4),
      _StatusItem('No data', 'nodata', Colors.grey, provider.getCountForStatus('nodata'), 5),
      _StatusItem('Expired', 'expired', Colors.red, provider.getCountForStatus('expired'), 6),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) {
          return InkWell(
            onTap: () {
              setState(() => _filterPos = item.position);
              provider.setFilter(item.filter);
              _searchFocusNode.unfocus();
            },
            child: Column(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: AppColors.StatusDshboardBarborderRadius,
                    border: Border.all(
                      color: Colors.black,
                      width: _filterPos == item.position ? 1 : 0,
                    ),
                  ),
                  child: Text(
                    '${item.count}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(GetDevicesListProvider provider) {
    if (provider.showLoading) {
      return const Expanded(child: Center(child: LoadingWidget()));
    }

    if (provider.filteredVehicles.isEmpty) {
      return const Expanded(child: Center(child: Text('No vehicles found')));
    }

    final vehicles = provider.filteredVehicles;

    _markers = List.filled(vehicles.length, BitmapDescriptor.defaultMarker);

    for (int i = 0; i < vehicles.length; i++) {
      _setMarker(i, vehicles[i].path ?? '');
    }

    return Expanded(
      child: ListView.builder(
        itemCount: vehicles.length,
        itemBuilder: (ctx, i) => _buildCard(ctx, i, vehicles[i]),
      ),
    );
  }

  Widget _buildCard(BuildContext ctx, int i, Item item) {
    final lat = _parseLat(item.lat);
    final lng = _parseLng(item.lng);
    final iconPath = item.path ?? '';
    final sensors = _parseSensors(item.sensors);
    final style = _styleFor(item.online, item.time);
    final stopTime = (item.stopDuration ?? '-').formatDuration();
    final name = item.name ?? '-';
    final speed = item.speed?.toString() ?? '0';
    final time = item.time ?? '-';
    final address = item.addr ?? '';
    final isUrdu = _selectedLanguage == 'Urdu';

    return InkWell(
      onTap: () {
        // Unfocus before navigation
        _searchFocusNode.unfocus();
        Navigator.pushNamed(
          ctx,
          RoutesName.singledevicemap,
          arguments: DeviceOnMapInitialData(
            groupID: 0,
            itemID: i,
            initialLat: lat,
            initialLng: lng,
            deviceId: item.id ?? 0,
            markerImage: (_markers.length > i)
                ? _markers[i]
                : BitmapDescriptor.defaultMarker,
            initialDirection: item.course?.toDouble() ?? 0,
          ),
        ).then((_) {
          // When coming back, ensure focus is removed
          if (mounted) {
            _searchFocusNode.unfocus();
            // Clear focus from entire widget tree
            FocusManager.instance.primaryFocus?.unfocus();
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: style.bg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.softShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // ---------------- TOP ROW ----------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 150,
                      decoration: BoxDecoration(
                        color: style.statusColor,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 3,
                        ),
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          'Status: ',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          style.label,
                          style: TextStyle(
                            color: style.statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Divider(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _labelRow(Icons.speed, 'Speed:'),
                          const SizedBox(height: 5),
                          _labelRow(Icons.webhook_outlined, 'Status:'),
                          const SizedBox(height: 5),
                          _labelRow(Icons.access_time, 'Update'),
                        ],
                      ),
                    ),

                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                speed,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                ' km/h',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Text(
                                style.label,
                                style: TextStyle(
                                  color: style.statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  stopTime,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 10,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(time),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Center(
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.black87,
                          child: CircleAvatar(
                            radius: 29,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: iconPath.isNotEmpty
                                    ? Image.network(
                                  AppUrl.baseImgURL + iconPath,
                                  fit: BoxFit.contain,
                                )
                                    : const Icon(
                                  Icons.directions_car,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _sensorIcon(
                      (sensors['immobilizer'] ?? false)
                          ? Icons.lock
                          : Icons.lock_open,
                      (sensors['immobilizer'] ?? false)
                          ? Colors.red
                          : Colors.green,
                    ),

                    _sensorIcon(Icons.wifi, Colors.orange),

                    _sensorIcon(
                      Icons.key_sharp,
                      (sensors['key'] ?? Colors.grey) as Color,
                    ),

                    _sensorIcon(
                      Icons.battery_charging_full_outlined,
                      (sensors['charge'] ?? Colors.grey) as Color,
                    ),

                    Row(
                      children: [
                        _sensorIcon(Icons.battery_3_bar_sharp, Colors.green),
                        const SizedBox(width: 2),
                        Text(
                          (sensors['battery'] ?? 'n/a').toString(),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Divider(),

                // Address
                FutureBuilder<String>(
                  future: address.isNotEmpty
                      ? (isUrdu ? address.toUrdu() : Future.value(address))
                      : Future.value('Address not available'),
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'Loading...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _labelRow(IconData icon, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _sensorIcon(IconData icon, Color color) {
    return CircleAvatar(
      radius: 13,
      backgroundColor: Colors.white,
      child: Icon(
        icon,
        color: color,
        size: 18,
      ),
    );
  }
}