import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/utils/routes/routes_name.dart';

class MaintenancePanel extends StatelessWidget {
  const MaintenancePanel({super.key});

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
                Icon(Icons.car_repair, color: Colors.blueAccent)
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
                    const Text(
                      'Vehicle Maintenance',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54),
                    ),
                    GFButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          RoutesName.addVehicleMaintenanceScreen,
                        );
                      },
                      text: 'Add',
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