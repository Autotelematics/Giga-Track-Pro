import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import 'package:trackerapp/providers/device_live_tracking_provider.dart';
import 'package:trackerapp/res/colors.dart';

class SensorsPanel extends StatelessWidget {
  const SensorsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VehicleTrackingProvider>(
      builder: (context, provider, _) {
        if (provider.sensors == null || provider.sensors!.isEmpty) {
          return Container();
        }

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
                text: 'Vehicle Sensors',
                type: AppColors.deviceOnMapSligePanelHeading,
                icon: Icon(Icons.sensors_outlined, color: Colors.blue[800]),
                showDivider: false,
                textColor: Colors.blue[800],
              ),
              const Divider(),
              ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: provider.sensors!.length,
                itemBuilder: (context, index) {
                  final sensor = provider.sensors![index];
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sensor.name?.toUpperCase() ?? 'UNKNOWN',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sensor.value?.toString() ?? '',
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}