import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trackerapp/models/vehicle_maintancne_model.dart';
import 'package:trackerapp/providers/device_maintenance_provider.dart';
import 'package:trackerapp/res/colors.dart';

class ViewMaintenanceSchedule extends StatefulWidget {
  const ViewMaintenanceSchedule({super.key});

  @override
  State<ViewMaintenanceSchedule> createState() =>
      _ViewMaintenanceScheduleState();
}

class _ViewMaintenanceScheduleState extends State<ViewMaintenanceSchedule> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceMaintenanceProvider>().fetchMaintenanceList('');
    });
  }

  Future<void> _delete(DeviceMaintenanceProvider p, VehicleMaintenance m) async {
    await p.deleteMaintenance(m);
  }

  void _confirmDelete(BuildContext context, VehicleMaintenance m,
      DeviceMaintenanceProvider p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Maintenance'),
        content: Text('${m.maintenanceVehicleName} • ${m.maintenanceType}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _delete(p, m);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _value(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
        height: 1.3,
      ),
    );
  }

  Widget _status(bool upcoming) {
    final color = upcoming ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        upcoming ? 'UPCOMING' : 'OVERDUE',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DecoratedBox(
        decoration: AppColors.appScreenBackgroundImage,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'Maintenance Schedule',
              style: AppColors.appTitleTextStyle,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Consumer<DeviceMaintenanceProvider>(
            builder: (_, provider, __) {
              final list = provider.maintenanceList;

              if (provider.isLoading && list.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (list.isEmpty) {
                return const Center(
                  child: Text(
                    'No maintenance scheduled',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: provider.refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final m = list[i];
                    final upcoming =
                    m.maintenanceDate.isAfter(DateTime.now());

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 6,
                            color: Colors.black12,
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// HEADER
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  m.maintenanceVehicleName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _status(upcoming),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 24,
                                ),
                                onPressed: () =>
                                    _confirmDelete(context, m, provider),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          /// TYPE
                          Text(
                            m.maintenanceType,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// DATE & TIME (CLEAN ROW)
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label("Date"),
                                  const SizedBox(height: 3),
                                  _value(DateFormat('dd MMM yyyy')
                                      .format(m.maintenanceDate)),
                                ],
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label("Time"),
                                  const SizedBox(height: 3),
                                  _value(DateFormat('hh:mm a')
                                      .format(m.maintenanceDate)),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          /// DESCRIPTION
                          _label("Description"),
                          const SizedBox(height: 4),
                          _value(m.maintenanceDescription),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}