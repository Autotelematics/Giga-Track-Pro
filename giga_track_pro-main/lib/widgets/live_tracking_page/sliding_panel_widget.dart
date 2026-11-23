import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:trackerapp/models/device_on_map_model.dart';
import 'package:trackerapp/widgets/live_tracking_page/sensors_panel.dart';
import 'package:trackerapp/widgets/live_tracking_page/travel_summary_panel.dart';

import 'action_buttons_panel.dart';
import 'alerts_panel.dart';
import 'current_location_panel.dart';
import 'expenses_panel.dart';
import 'fuel_average_panel.dart';
import 'immobilizer_panel.dart';
import 'maintenance_panel.dart';


class SlidingPanelWidget extends StatelessWidget {
  final ScrollController scrollController;
  final PanelController panelController;
  final DeviceOnMapInitialData? initialData;
  final String stopDurationDisplay;
  final String stopStartStatus;
  final int deviceId;
  final String deviceName;
  final Color keyColor;
  final String keyStatus;
  final Color batteryChargingColor;
  final String batteryVoltage;
  final bool immobilizerValue;
  final String immobilizerStatus;
  final double vehicleFuelAveragePerKm;
  final double? currentFuelCost;
  final Function(double) onFuelAverageSet;
  final Function(int) onTravelSummaryFetch;

  const SlidingPanelWidget({
    super.key,
    required this.scrollController,
    required this.panelController,
    required this.initialData,
    required this.keyColor,
    required this.stopDurationDisplay,
    required this.stopStartStatus,
    required this.keyStatus,
    required this.batteryChargingColor,
    required this.batteryVoltage,
    required this.immobilizerValue,
    required this.immobilizerStatus,
    required this.vehicleFuelAveragePerKm,
    required this.currentFuelCost,
    required this.onFuelAverageSet,
    required this.onTravelSummaryFetch, required this.deviceId, required this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      children: [
        // Panel Handle
        GestureDetector(
          child: Center(
            child: Container(
              height: 5,
              width: 30,
              decoration: const BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          onTap: () {
            if (panelController.isPanelOpen) {
              panelController.close();
            } else {
              panelController.open();
            }
          },
        ),

        // Current Location Panel
        CurrentLocationPanel(
          keyColor: keyColor,
          keyStatus: keyStatus,
          batteryChargingColor: batteryChargingColor,
          batteryVoltage: batteryVoltage,
          immobilizerValue: immobilizerValue,
        ),

        // Travel Summary Panel
        TravelSummaryPanel(
          vehicleFuelAveragePerKm: vehicleFuelAveragePerKm,
          currentFuelCost: currentFuelCost,
          onTravelSummaryFetch: onTravelSummaryFetch,
        ),

        // Action Buttons Panel
         ActionButtonsPanel(deviceId: deviceId, deviceTitle: deviceName,),

        // Immobilizer Panel
        ImmobilizerPanel(
          immobilizerValue: immobilizerValue,
          immobilizerStatus: immobilizerStatus, deviceId: deviceId.toString(),
        ),

        // Expenses Panel
        ExpensesPanel(initialData: initialData, deviceTitle: deviceName,),

        // Maintenance Panel
        const MaintenancePanel(),

        // Fuel Average Panel
        FuelAveragePanel(
          vehicleFuelAveragePerKm: vehicleFuelAveragePerKm,
          onFuelAverageSet: onFuelAverageSet, vehicleId:deviceId.toString() ,
        ),

        // Sensors Panel
        const SensorsPanel(),

        // Alerts Panel
        AlertsPanel(initialData: initialData),

        const SizedBox(height: 20),
      ],
    );
  }
}