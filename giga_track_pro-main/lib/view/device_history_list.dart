import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trackerapp/models/device_history_on_map.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/res/components/app_end_point.dart';
import 'package:trackerapp/utils/routes/routes_name.dart';
import 'package:trackerapp/providers/get_devices_list_provider.dart';
import 'package:trackerapp/view/filter_for_history.dart';

class VehicleHistoryList extends StatefulWidget {
  const VehicleHistoryList({super.key});

  @override
  State<VehicleHistoryList> createState() => _VehicleHistoryListState();
}

class _VehicleHistoryListState extends State<VehicleHistoryList> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GetDevicesListProvider>().init(context);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleMenuSelection(dynamic vehicleId, String vehicleName, int menuValue) {
    final vehicleIdStr = vehicleId.toString();
    final dateFormat = DateFormat("yy-MM-dd");
    final now = DateTime.now();

    String fromDate;
    String toDate;

    switch (menuValue) {
      case 0:
      // Today
        fromDate = dateFormat.format(now);
        toDate = dateFormat.format(now);
        break;

      case 1:
      // Yesterday
        final yesterday = now.subtract(const Duration(days: 1));
        fromDate = dateFormat.format(yesterday);
        toDate = dateFormat.format(yesterday);
        break;

      case 7:
      // Last 7 days
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        fromDate = dateFormat.format(sevenDaysAgo);
        toDate = dateFormat.format(now);
        break;

      case 30:
      // Last 30 days
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        fromDate = dateFormat.format(thirtyDaysAgo);
        toDate = dateFormat.format(now);
        break;

      case 2:
      // Custom date picker
        _showCustomDatePicker(vehicleIdStr);
        return;

      default:
        fromDate = dateFormat.format(now);
        toDate = dateFormat.format(now);
    }

    _navigateToHistory(vehicleIdStr, vehicleName, fromDate, toDate);
  }

  void _showCustomDatePicker(String vehicleId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: CustomHistoryDateTimePicker(
            vehicleId,
            RoutesName.playroutonmap,
          ),
        ),
      ),
    );
  }

  void _navigateToHistory(
      String vehicleId,
      String vehicleName,
      String fromDate,
      String toDate,
      ) {
    Navigator.pushNamed(
      context,
      RoutesName.playroutonmap,
      arguments: DeviceHistoryOnMapInitialData(
        deviceTitle: vehicleName,
        deviceId: vehicleId,
        fromDate: fromDate,
        toDate: toDate,
        fromTime: '00:00:01',
        toTime: '23:59:00',
      ),
    );
  }
  Widget _buildVehicleCard(Map<String, dynamic> vehicle) => Card(
    shape: AppColors.cardBorderShape,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 9),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Vehicle info
        Expanded(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(
                    child: SizedBox(
                      width: 35,
                      height: 35,
                      child: Image.network(
                        AppUrl.baseImgURL + (vehicle['iconPath'] ?? ''),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.directions_car,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  vehicle['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Date range menu
        PopupMenuButton<int>(
          shape: ContinuousRectangleBorder(
            borderRadius: AppColors.popupmenuborder,
          ),
          onSelected: (value) => _handleMenuSelection(
            vehicle['id'],
            vehicle['name'] ?? 'Vehicle',
            value,
          ),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 0, child: Text('Today')),
            PopupMenuItem(value: 1, child: Text('Yesterday')),
            PopupMenuItem(value: 7, child: Text('7 Days')),
            PopupMenuItem(value: 30, child: Text('30 Days')),
            PopupMenuItem(value: 2, child: Text('Custom Date')),
          ],
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Vehicle History',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<GetDevicesListProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => provider.updateSearchQuery(value),
                  decoration: const InputDecoration(
                    labelText: 'Search Vehicle',
                    suffixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              Expanded(
                child: _buildVehicleListContent(provider),
              ),
            ],
          );
        },
      ),
    );
  }
  Widget _buildVehicleListContent(GetDevicesListProvider provider) {
    // Loading state - show only on initial load
    if (provider.showLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(color:Colors.red),
            ),
            SizedBox(height: 16),
            Text(
              'Loading vehicles...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Error state - only show if no data
    if (provider.error != null && (provider.vehicleData?.items?.isEmpty ?? true)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                provider.error ?? 'Failed to load vehicles',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => provider.fetchData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state - no vehicles found
    if (provider.filteredVehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No vehicles found matching "${_searchController.text}"'
                  : 'No vehicles available',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  provider.updateSearchQuery('');
                },
                child: const Text('Clear Search'),
              ),
            ],
          ],
        ),
      );
    }

    // Vehicle list
    return ListView.builder(
      itemCount: provider.filteredVehicles.length,
      itemBuilder: (context, index) {
        final vehicle = provider.filteredVehicles[index];
        return _buildVehicleCard({
          'id': vehicle.id,
          'name': vehicle.name,
          'iconPath': vehicle.path?? '',
        });
      },
    );
  }
}