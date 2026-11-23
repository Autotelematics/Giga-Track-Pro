import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackerapp/data/response/status.dart';
import 'package:trackerapp/models/device_history_on_map.dart';
import 'package:trackerapp/providers/fuel_report_provider.dart';

class VehicleFuelReportViewScreen extends StatefulWidget {
  final DeviceHistoryOnMapInitialData? initialData;

  const VehicleFuelReportViewScreen(this.initialData, {super.key});

  @override
  State<VehicleFuelReportViewScreen> createState() =>
      _VehicleFuelReportViewScreenState();
}

class _VehicleFuelReportViewScreenState
    extends State<VehicleFuelReportViewScreen> {
  final FuelReportProvider _vm = FuelReportProvider();

  late String _fromDateDisplay, _toDateDisplay, _vehicleName;
  double _fuelAvg = 1.0, _fuelPrice = 1.0;

  @override
  void initState() {
    super.initState();

    final data = widget.initialData!;
    _vehicleName = data.deviceTitle.toString();

    final displayFormat = DateFormat("dd MMM yyyy");
    final apiDateFormat = DateFormat("yy-MM-dd");

    _fromDateDisplay = displayFormat.format(apiDateFormat.parse(data.fromDate!));
    _toDateDisplay = displayFormat.format(apiDateFormat.parse(data.toDate!));

    _vm.fetchDeviceHistory(
      deviceID: data.deviceId.toString(),
      fromDate: _formatDateForApi(data.fromDate!),
      toDate: _formatDateForApi(data.toDate!),
      fromTime: data.fromTime ?? "00:00:01",
      toTime: data.toTime ?? "23:59:59",
    );

    _loadPreferences();
  }

  String _formatDateForApi(String dateStr) {
    try {
      return DateFormat("yyyy-MM-dd").format(DateFormat("yy-MM-dd").parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fuelAvg = prefs.getDouble('fuelAverage_${widget.initialData!.deviceId}') ?? 1.0;
      _fuelPrice = prefs.getDouble('fuelPrice') ?? 1.0;
    });
  }

  // ================== IMPROVED ERROR UI ==================
  Widget _errorWidget(String? errorMsg) {
    String title = "Something went wrong";
    String message = "Failed to load fuel report. Please try again later.";

    // Handle specific API messages
    if (errorMsg != null) {
      if (errorMsg.toLowerCase().contains("expired")) {
        title = "Device Expired";
        message = "This vehicle's tracking service has expired.\nPlease renew your subscription.";
      } else if (errorMsg.toLowerCase().contains("invalid") ||
          errorMsg.toLowerCase().contains("date")) {
        title = "Invalid Request";
        message = "Please check the selected date range.";
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text("Go Back"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loading() => const Center(
    child: CircularProgressIndicator(color: Colors.red),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Report'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ChangeNotifierProvider.value(
        value: _vm,
        child: Consumer<FuelReportProvider>(
          builder: (context, vm, _) {
            switch (vm.historyResponse.status) {
              case Status.LOADING:
                return _loading();

              case Status.ERROR:
                return _errorWidget(vm.historyResponse.errorMessage);

              case Status.COMPLETED:
                final data = vm.historyResponse.data;
                final distArr = (data?.distanceSum ?? '0 km').split(' ');
                final distance = double.tryParse(distArr[0]) ?? 0.0;

                final fuelUsed = distance / _fuelAvg;
                final fuelCost = fuelUsed * _fuelPrice;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_vehicleName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('$_fromDateDisplay → $_toDateDisplay',
                            style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                        const Divider(height: 30),

                        _buildRow("🚗 Distance", data?.distanceSum ?? "-"),
                        _buildRow("⛽ Fuel Used", "${fuelUsed.toStringAsFixed(2)} L"),
                        _buildRow("💰 Fuel Cost", "Rs. ${fuelCost.toStringAsFixed(2)}"),
                        _buildRow("💵 Fuel Price", "Rs. $_fuelPrice / L"),
                        _buildRow("📊 Avg Consumption", "$_fuelAvg Km/L"),
                        _buildRow("🕒 Moving Time", data?.moveDuration ?? "-"),
                        _buildRow("⏸ Stop Time", data?.stopDuration ?? "-"),
                      ],
                    ),
                  ),
                );

              default:
                return const SizedBox();
            }
          },
        ),
      ),
    );
  }

  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}