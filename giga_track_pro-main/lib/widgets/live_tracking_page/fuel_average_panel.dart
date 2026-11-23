import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:trackerapp/res/colors.dart';
import 'fuel_average_dialog.dart';

class FuelAveragePanel extends StatelessWidget {
  final double vehicleFuelAveragePerKm;
  final String vehicleId;
  final Function(double) onFuelAverageSet;
  const FuelAveragePanel({
    super.key,
    required this.vehicleFuelAveragePerKm,
    required this.onFuelAverageSet,
    required this.vehicleId,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 30,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.propane_tank_outlined, color: Colors.blueAccent)
              ],
            ),
          ),
          Expanded(
            flex: 9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fuel Average is $vehicleFuelAveragePerKm km/l',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54),
                    ),
                    GFButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => FuelAverageDialog(
                            onFuelAverageSet: onFuelAverageSet, vehicleId: vehicleId,
                          ),
                        );
                      },
                      text: 'Set',
                      textStyle: AppColors.settingPageButtonTextStyle,
                      color: AppColors.buttonColor,
                      shape: GFButtonShape.pills,
                      size: 25,
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}