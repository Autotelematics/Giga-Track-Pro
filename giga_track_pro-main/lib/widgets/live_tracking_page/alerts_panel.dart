import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import 'package:trackerapp/models/device_on_map_model.dart';
import 'package:trackerapp/models/events_intitial_data.dart';
import 'package:trackerapp/providers/get_alert_provider.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/utils/date_time_extension.dart';
import 'package:trackerapp/utils/routes/routes_name.dart';

class AlertsPanel extends StatelessWidget {
  final DeviceOnMapInitialData? initialData;

  const AlertsPanel({super.key, required this.initialData});

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertsProvider>(
      builder: (context, alertsProvider, _) {
        return Container(
          width: MediaQuery.of(context).size.width - 30,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            children: [
              GFTypography(
                text: 'Recent Alerts',
                type: AppColors.deviceOnMapSligePanelHeading,
                icon: Icon(Icons.notifications_active_outlined,
                    color: Colors.blue[800]),
                showDivider: false,
                fontWeight: FontWeight.bold,
                textColor: Colors.blue[800],
              ),
              const Divider(),
              if (alertsProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                )
              else if (alertsProvider.errorMessage != null)
                Text('Error: ${alertsProvider.errorMessage}')
              else if ((alertsProvider.model?.items.isEmpty ?? true))
                  const Text('No recent alerts')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: (alertsProvider.model!.items.length > 5
                        ? 5
                        : alertsProvider.model!.items.length),
                    itemBuilder: (context, index) {
                      final alert = alertsProvider.model!.items[index];
                      return Column(
                        children: [
                          ListTile(
                            title: Text(alert.message,
                                style: const TextStyle(fontSize: 14)),
                            subtitle: Text(
                              alert.time != null
                                  ? alert.time.toString().toFormattedDateTime()
                                  : 'No time',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(
                              Icons.notifications_active_outlined,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                          const Divider(height: 2),
                        ],
                      );
                    },
                  ),
              if ((alertsProvider.model?.items.isNotEmpty ?? false) &&
                  (alertsProvider.model!.items.length > 3))
                GFButton(
                  onPressed: () {
                    Navigator.pushNamed(context, RoutesName.eventsScreen,
                        arguments: EventsInitialData(
                            deviceID: initialData!.deviceId.toString(),
                            eventType: '',
                            fromDate: '',
                            toDate: '',
                            pageNumber: ''));
                  },
                  text: 'View More Alerts',
                  textStyle: AppColors.settingPageButtonTextStyle,
                  color: AppColors.buttonColor,
                  shape: GFButtonShape.pills,
                  size: 25,
                ),
            ],
          ),
        );
      },
    );
  }
}