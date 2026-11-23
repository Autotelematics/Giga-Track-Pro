import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackerapp/res/components/submitbutton.dart';
import 'package:trackerapp/utils/utils.dart';

class FuelAverageDialog extends StatefulWidget {
  final String vehicleId; // 🔥 unique id for each vehicle
  final Function(double)? onFuelAverageSet;

  const FuelAverageDialog({
    super.key,
    required this.vehicleId,
    this.onFuelAverageSet,
  });

  @override
  State<FuelAverageDialog> createState() => _FuelAverageDialogState();
}

class _FuelAverageDialogState extends State<FuelAverageDialog> {
  final TextEditingController fuelAverageController = TextEditingController();
  final FocusNode fuelFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadPreviousValue(); // 🔥 load saved value
  }

  Future<void> _loadPreviousValue() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();

    double? value = sp.getDouble('fuelAverage_${widget.vehicleId}');

    if (value != null) {
      fuelAverageController.text = value.toString();
    }
  }

  @override
  void dispose() {
    fuelAverageController.dispose();
    fuelFocusNode.dispose();
    super.dispose();
  }

  Future<void> _setFuelAverage() async {
    if (fuelAverageController.text.isEmpty) {
      Utils.toastMessage('Please enter fuel average');
      return;
    }

    final double? value = double.tryParse(fuelAverageController.text);

    if (value == null || value < 1 || value > 50) {
      Utils.toastMessage('Please enter value from 1 to 50 range');
      return;
    }

    try {
      final SharedPreferences sp = await SharedPreferences.getInstance();

      // 🔥 Save per vehicle
      await sp.setDouble('fuelAverage_${widget.vehicleId}', value);

      Utils.toastMessage('Fuel average set successfully');

      widget.onFuelAverageSet?.call(value);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      Utils.toastMessage('Failed to save fuel average');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Set Vehicle Fuel Average',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// Input Field
            TextField(
              controller: fuelAverageController,
              focusNode: fuelFocusNode,
              autofocus: true,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Fuel Average (km/l)",
                filled: true,
                fillColor: Color(0xfff2f2f3),
                contentPadding:
                EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                prefixIcon: Icon(Icons.local_gas_station_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Enter value between 1 to 50',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            /// Submit Button
            SubmitButton(
              title: 'Set Fuel Average',
              onPress: _setFuelAverage,
            ),
          ],
        ),
      ),
    );
  }
}