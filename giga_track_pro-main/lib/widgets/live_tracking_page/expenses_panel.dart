import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:trackerapp/models/device_on_map_model.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/utils/routes/routes_name.dart';
import 'package:trackerapp/view/add_expense_record_screen.dart';

class ExpensesPanel extends StatelessWidget {
  final DeviceOnMapInitialData? initialData;
  final String deviceTitle;

  const ExpensesPanel({
    super.key,
    required this.initialData,
    required this.deviceTitle,
  });

  Future<void> _showAddExpenseForm(
      BuildContext context, String vehicleID, String vehicleName) {
    return showDialog(
      useSafeArea: true,
      context: context,
      builder: (BuildContext context) => AddExpenseScreen(
        vehicleId: vehicleID,
        vehicleName: vehicleName,
      ),
    );
  }

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
                Icon(
                  Icons.attach_money_outlined,
                  color: Colors.blueAccent,
                )
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
                      'Vehicle Expenses',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    Row(
                      children: [
                        // ✅ VIEW BUTTON
                        GFButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            RoutesName.viewExpenseScreen,
                            arguments: {
                              'vehicleId': initialData!.deviceId.toString()
                            },
                          ),
                          text: 'View',
                          textStyle: AppColors.settingPageButtonTextStyle,
                          color: AppColors.buttonColor,
                          shape: GFButtonShape.pills,
                          size: 25,
                        ),
                        const SizedBox(width: 2),
                        GFButton(
                          onPressed: () => _showAddExpenseForm(
                            context,
                            initialData!.deviceId.toString(),
                            deviceTitle,
                          ),
                          text: 'Add',
                          textStyle: AppColors.settingPageButtonTextStyle,
                          color: AppColors.buttonColor,
                          shape: GFButtonShape.pills,
                          size: 25,
                        ),
                      ],
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