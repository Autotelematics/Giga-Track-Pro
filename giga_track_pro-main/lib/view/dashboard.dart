import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackerapp/data/globalsharedveriables.dart';
import 'package:trackerapp/models/events_intitial_data.dart';
import 'package:trackerapp/providers/device_maintenance_provider.dart';
import 'package:trackerapp/providers/expense_record_provider.dart';
import 'package:trackerapp/providers/get_alert_provider.dart';
import 'package:trackerapp/providers/get_devices_list_provider.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/utils/routes/routes_name.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class _ChartData {
  final String x;
  final int y;
  const _ChartData(this.x, this.y);
}

class _QuickItem {
  final String label, imagePath;
  final VoidCallback onTap;
  const _QuickItem(this.label, this.imagePath, this.onTap);
}

class _AlertConfig {
  final IconData icon;
  final String label, alertType;
  final AlertsProvider provider;
  final List<Color> colors;
  const _AlertConfig(
      this.icon, this.label, this.alertType, this.provider, this.colors);
}

class Dashboard extends StatefulWidget {
  // ✅ ADDED: callback so Dashboard can ask HomePage to switch tabs
  final ValueChanged<int>? onTabChange;

  const Dashboard({super.key, this.onTabChange});

  @override
  State<Dashboard> createState() => DashboardState();
}

class DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  final _alertProviders = <String, AlertsProvider>{};

  static const _alertTypeKeys = [
    '',
    'Over Speed',
    'Over Parking',
    'Idle Duration',
    'Ignition Alert',
    'Power Alert',
    'Offline duration',
  ];

  int running = 0,
      stopped = 0,
      idle = 0,
      offline = 0,
      noData = 0,
      total = 0,
      expired = 0;

  List<dynamic> _deviceList = [];
  List<_ChartData> _chartData = [];

  late final TooltipBehavior _tooltip;
  late final Legend _legend;
  late final DataLabelSettings _labelSettings;
  late final TextStyle _headingStyle;

  Timer? _refreshTimer;
  Key _chartKey = UniqueKey();
  bool _isDisposed = false;

  static const _palette = [
    Colors.green,
    Colors.red,
    Colors.yellow,
    Colors.blue,
    Colors.grey,
    Color.fromARGB(255, 138, 13, 4),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _tooltip = TooltipBehavior(enable: true);
    _headingStyle = const TextStyle(
        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54);
    _labelSettings = const DataLabelSettings(
      isVisible: true,
      labelPosition: ChartDataLabelPosition.inside,
      showZeroValue: false,
      useSeriesColor: false,
    );
    _legend = Legend(
        isVisible: true,
        position: LegendPosition.right,
        isResponsive: true,
        width: '100%');
    _chartData = _defaultChartData();

    for (final key in _alertTypeKeys) {
      _alertProviders[key] = AlertsProvider();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        context.read<GetDevicesListProvider>().init(context);
        context.read<ExpenseRecordProvider>().fetchExpenseRecords('');
        context.read<DeviceMaintenanceProvider>().fetchMaintenanceList('');

        for (final entry in _alertProviders.entries) {
          entry.value.setAlertTypeFilter(entry.key.isEmpty ? null : entry.key);

          final now = DateTime.now();
          entry.value.setDateRangeFilter(
            from: DateTime(now.year, now.month, now.day),
            to: DateTime(now.year, now.month, now.day),
          );

          entry.value.setDeviceIdFilter(null);
          entry.value.fetchAlerts(isRefresh: true, context: context);
        }
      }
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_isDisposed && mounted) {
        context.read<GetDevicesListProvider>().fetchData();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _isDisposed = true;
    } else if (state == AppLifecycleState.resumed) {
      _isDisposed = false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  List<_ChartData> _defaultChartData() => [
    const _ChartData('Running', 1),
    const _ChartData('Stopped', 1),
    const _ChartData('Idle', 1),
    const _ChartData('Offline', 1),
    const _ChartData('No Data', 1),
    const _ChartData('Expired', 1),
  ];

  void triggerChartAnimation() {
    if (!_isDisposed && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed && mounted) {
          setState(() => _chartKey = UniqueKey());
        }
      });
    }
  }

  Future<void> _saveDefaultFuelAverages(
      List<Map<String, dynamic>> vehicles) async {
    final prefs = await SharedPreferences.getInstance();
    for (final v in vehicles) {
      final key = 'fuelAverage_${v['id']}';
      if (prefs.getDouble(key) == null) prefs.setDouble(key, 13.0);
    }
  }

  void _countStatuses(List<dynamic> list) {
    running = stopped = idle = offline = noData = total = expired = 0;
    vehicleNames.clear();
    vehiclesNamesIdMap.clear();
    for (final d in list) {
      vehicleNames.add(d['name']);
      vehiclesNamesIdMap.add({'id': d['id'], 'name': d['name']});
      total++;
      final s = d['online'].toString().toLowerCase();
      final t = d['time'].toString().toLowerCase();
      if (s == 'ack') stopped++;
      if (s == 'online') running++;
      if (s == 'offline' && t != 'not connected' && t != 'expired') offline++;
      if (s == 'offline' && t == 'not connected') noData++;
      if (t == 'expired') expired++;
      if (s == 'engine') idle++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Dashboard', style: AppColors.appTitleTextStyle),
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(children: [
            _buildStatusChart(),
            const SizedBox(height: 10),
            _buildAlertsCard(),
            const SizedBox(height: 10),
            _buildWarningCard(),
            const SizedBox(height: 10),
            _buildQuickAccessGrid(),
            _buildExpenseRow(),
            const SizedBox(height: 10),
            _buildMaintenanceRow(),
            const SizedBox(height: 10),
          ]),
        ),
      ),
    );
  }

  Widget _buildStatusChart() => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: AppColors.softShadow,
    ),
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Column(children: [
      const Padding(
        padding: EdgeInsets.only(top: 10),
        child: Text('Vehicle Status',
            style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.bold)),
      ),
      Consumer<GetDevicesListProvider>(
        builder: (context, deviceProvider, _) {
          final items = deviceProvider.vehicleData?.items ?? [];
          final done = items.isNotEmpty;

          if (done) {
            _deviceList = items
                .map((item) => {
              'id': item.id,
              'name': item.name ?? '',
              'online': item.online ?? '',
              'time': item.time ?? '',
              'path': item.path ?? '',
              'lat': item.lat ?? 0.0,
              'lng': item.lng ?? 0.0,
            })
                .toList();

            _countStatuses(_deviceList);
            _saveDefaultFuelAverages(vehiclesNamesIdMap);
            _chartData = [
              _ChartData('Running', running),
              _ChartData('Stopped', stopped),
              _ChartData('Idle', idle),
              _ChartData('Offline', offline),
              _ChartData('No Data', noData),
              _ChartData('Expired', expired),
            ];
          } else {
            _deviceList = [];
            _chartData = [
              const _ChartData('Running', 0),
              const _ChartData('Stopped', 0),
              const _ChartData('Idle', 0),
              const _ChartData('Offline', 0),
              const _ChartData('No Data', 0),
              const _ChartData('Expired', 0),
            ];
          }

          return SizedBox(
            key: _chartKey,
            child: SfCircularChart(
              margin: EdgeInsets.zero,
              tooltipBehavior: _tooltip,
              legend: _legend,
              palette: _palette,
              annotations: [
                CircularChartAnnotation(
                  widget: deviceProvider.isLoading && !done
                      ? const CircularProgressIndicator(color: Colors.red)
                      : Text(_deviceList.length.toString(),
                      style: const TextStyle(
                          color: Color.fromRGBO(0, 0, 0, .5),
                          fontSize: 40)),
                ),
              ],
              series: [
                DoughnutSeries<_ChartData, String>(
                  animationDuration: 1200,
                  innerRadius: '55%',
                  dataLabelSettings: _labelSettings,
                  dataSource: _chartData,
                  xValueMapper: (d, _) => d.x,
                  yValueMapper: (d, _) => d.y,
                  // ✅ FIXED: Use callback instead of global navBarIndex + Navigator
                  onPointTap: done
                      ? (_) {
                    widget.onTabChange?.call(1);
                  }
                      : (_) {},
                ),
              ],
            ),
          );
        },
      ),
    ]),
  );

  Widget _buildAlertsCard() {
    final alertPairs = [
      [
        _AlertConfig(
          Icons.speed,
          'Over Speed',
          'Over Speed',
          _alertProviders['Over Speed']!,
          const [Color.fromARGB(255, 142, 101, 255), Colors.deepPurple],
        ),
        _AlertConfig(
          Icons.local_parking_outlined,
          'Over Parking',
          'Over Parking',
          _alertProviders['Over Parking']!,
          const [Color.fromARGB(255, 102, 198, 242), Colors.blueAccent],
        ),
      ],
      [
        _AlertConfig(
          Icons.pause_circle_outline,
          'Idle Duration',
          'Idle Duration',
          _alertProviders['Idle Duration']!,
          const [Color.fromARGB(255, 249, 100, 100), Colors.red],
        ),
        _AlertConfig(
          Icons.key,
          'Ignition Alerts',
          'Ignition Alert',
          _alertProviders['Ignition Alert']!,
          const [Color.fromARGB(255, 255, 167, 38), Colors.orange],
        ),
      ],
      [
        _AlertConfig(
          Icons.bolt,
          'Power Alerts',
          'Power Alert',
          _alertProviders['Power Alert']!,
          const [Color.fromARGB(255, 80, 200, 120), Colors.green],
        ),
        _AlertConfig(
          Icons.wifi_off,
          'Offline',
          'Offline duration',
          _alertProviders['Offline duration']!,
          const [Color.fromARGB(255, 150, 150, 150), Colors.blueGrey],
        ),
      ],
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Alert Status',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _AlertTile(
            icon: Icons.notifications_active_outlined,
            label: 'Total Alerts',
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color.fromARGB(255, 245, 207, 93),
                Color.fromARGB(255, 244, 183, 2),
              ],
            ),
            alertType: '',
            provider: _alertProviders['']!,
            onTap: () {
              _alertProviders['']!.setDeviceIdFilter(null);
              Navigator.pushNamed(
                context,
                RoutesName.eventsScreen,
                arguments: EventsInitialData(
                  deviceID: '',
                  eventType: '',
                  fromDate: '',
                  toDate: '',
                  pageNumber: '',
                ),
              );
            },
          ),
        ),
        ...List.generate(
            alertPairs.length,
                (r) => Padding(
              padding: EdgeInsets.only(
                  top: 8, bottom: r == alertPairs.length - 1 ? 8 : 0),
              child: Row(
                children: List.generate(
                    2,
                        (c) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: c == 0 ? 8 : 4,
                            right: c == 0 ? 4 : 8),
                        child: _AlertTile(
                          icon: alertPairs[r][c].icon,
                          label: alertPairs[r][c].label,
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: alertPairs[r][c].colors,
                          ),
                          alertType: alertPairs[r][c].alertType,
                          provider: alertPairs[r][c].provider,
                          onTap: () {
                            final provider = alertPairs[r][c].provider;
                            provider.setDeviceIdFilter(null);
                            provider.setAlertTypeFilter(
                                alertPairs[r][c].alertType);

                            Navigator.pushNamed(
                              context,
                              RoutesName.eventsScreen,
                              arguments: EventsInitialData(
                                deviceID: '',
                                eventType: alertPairs[r][c].alertType,
                                fromDate: '',
                                toDate: '',
                                pageNumber: '',
                              ),
                            );
                          },
                        ),
                      ),
                    )),
              ),
            )),
      ]),
    );
  }

  Widget _buildWarningCard() => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: AppColors.softShadow,
    ),
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(children: [
        Text('!انتباہ',
            style: TextStyle(
                fontSize: 18,
                color: Colors.red,
                fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        Divider(height: 6),
        SizedBox(height: 5),
        Text(
          'ٹریکر ڈیوائس موٹر انشورنس کے متبادل نہیں ہے اور نا ہی چوری کو روکنے کا آلہ ہے، کمپنی گاڑی چوری کی صورت میں زمہ دار نہیں ہوگی۔',
          style: TextStyle(
            color: Colors.black87,
            height: 1.5,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
      ]),
    ),
  );

  Widget _buildQuickAccessGrid() {
    final items = [
      _QuickItem(
        'Reports',
        'assets/images/Combo_Chart_96px.png',
            () => Navigator.pushNamed(context, RoutesName.vehiclereportlist),
      ),
      _QuickItem(
        'History',
        'assets/images/Time_Machine_96px.png',
            () => Navigator.pushNamed(context, RoutesName.vehiclehistorylist),
      ),
      _QuickItem(
        'Vehicles',
        'assets/images/Traffic_Jam_96px.png',
        // ✅ FIXED: Use callback instead of setting global navBarIndex + Navigator
            () => widget.onTabChange?.call(1),
      ),
      _QuickItem(
        'Fuel',
        'assets/images/Gas_Station_96px.png',
            () => Navigator.pushNamed(context, RoutesName.viewVehicleFuelList),
      ),
    ];

    return Column(
      children: [
        Row(children: items.sublist(0, 2).map(_quickCard).toList()),
        Row(children: items.sublist(2, 4).map(_quickCard).toList()),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _quickCard(_QuickItem item) => Expanded(
    child: InkWell(
      onTap: item.onTap,
      child: Container(
        height: 150,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.label, style: _headingStyle),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Image(
                image: AssetImage(item.imagePath),
                height: 45,
                width: 45,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildExpenseRow() => InkWell(
    onTap: () => Navigator.pushNamed(context, RoutesName.viewExpenseScreen,
        arguments: {'vehicleId': ''}),
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(children: [
            CircleAvatar(
                maxRadius: 16,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.attach_money_outlined, color: Colors.white)),
            SizedBox(width: 8),
            Text('Vehicle Expenses',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold)),
          ]),
          Consumer<ExpenseRecordProvider>(
            builder: (_, provider, __) =>
                Text('Rs.${provider.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
          ),
        ],
      ),
    ),
  );

  Widget _buildMaintenanceRow() => InkWell(
    onTap: () =>
        Navigator.pushNamed(context, RoutesName.viewMaintenanceSchedule),
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            CircleAvatar(
                maxRadius: 16,
                backgroundColor: Colors.red[800],
                child: const Icon(Icons.car_repair, color: Colors.white)),
            const SizedBox(width: 8),
            const Text('Upcoming Maintenance',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold)),
          ]),
          Row(children: [
            CircleAvatar(
              maxRadius: 16,
              child: Consumer<DeviceMaintenanceProvider>(
                builder: (_, provider, __) =>
                    Text(provider.upcomingCount.toString()),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => Navigator.pushNamed(
                  context, RoutesName.addVehicleMaintenanceScreen),
              child:
              const CircleAvatar(maxRadius: 16, child: Icon(Icons.add, size: 18)),
            ),
          ]),
        ],
      ),
    ),
  );
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final String label, alertType;
  final Gradient gradient;
  final AlertsProvider provider;
  final VoidCallback onTap;

  const _AlertTile({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.alertType,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppColors.StatusDshboardBarborderRadius,
        boxShadow: AppColors.alertShadow,
      ),
      child: Row(children: [
        Expanded(flex: 1, child: Icon(icon, color: Colors.white, size: 28)),
        Expanded(
          flex: 2,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: CircleAvatar(
            backgroundColor: Colors.white,
            radius: 16,
            child: ChangeNotifierProvider.value(
              value: provider,
              child: Consumer<AlertsProvider>(
                builder: (_, p, __) {
                  if (p.isLoading && p.model == null) {
                    return const SizedBox(
                      width: 14,
                      height: 14,
                      child:
                      CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  if (p.errorMessage != null && p.model == null) {
                    return const Text('!',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red));
                  }
                  final count = alertType.isEmpty
                      ? (p.model?.total ?? 0)
                      : (p.model?.counts[alertType] ?? 0);
                  return Text(
                    count.toString(),
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
          ),
        ),
      ]),
    ),
  );
}