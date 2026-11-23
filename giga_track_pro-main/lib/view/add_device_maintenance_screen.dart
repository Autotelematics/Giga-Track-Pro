import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trackerapp/data/globalsharedveriables.dart';
import 'package:trackerapp/models/vehicle_maintancne_model.dart';
import 'package:trackerapp/providers/device_maintenance_provider.dart';
import 'package:trackerapp/res/colors.dart';

class AddVehicleMaintenanceScreen extends StatefulWidget {
  const AddVehicleMaintenanceScreen({super.key});

  @override
  State<AddVehicleMaintenanceScreen> createState() =>
      _AddVehicleMaintenanceScreenState();
}

class _AddVehicleMaintenanceScreenState
    extends State<AddVehicleMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();

  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;

  bool _loading = false;

  String? _selectedMaintenance;
  String? _selectedVehicle;

  final List<String> maintenanceOptions = [
    'Oil Change',
    'Oil Filter Change',
    'Air Filter Change',
    'Timing Belt',
    'Greasing',
    'Engine Tuning',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (d != null) {
      setState(() {
        _date = d;
        _dateCtrl.text = DateFormat('dd-MM-yyyy').format(d);
      });
    }
  }

  Future<void> _pickTime() async {
    if (_date == null) return;

    final now = DateTime.now();

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (t != null) {
      final selectedDateTime = DateTime(
        _date!.year,
        _date!.month,
        _date!.day,
        t.hour,
        t.minute,
      );

      if (_date!.year == now.year &&
          _date!.month == now.month &&
          _date!.day == now.day &&
          selectedDateTime.isBefore(now)) {
        return;
      }

      setState(() {
        _time = t;
        _timeCtrl.text = t.format(context);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _time == null) return;

    final dt = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );

    if (dt.isBefore(DateTime.now())) return;

    setState(() => _loading = true);

    try {
      final vehicleData = vehiclesNamesIdMap.firstWhere(
            (v) => v['name'] == _selectedVehicle,
        orElse: () => {'id': ''},
      );

      final maintenance = VehicleMaintenance(
        maintenanceDate: dt,
        maintenanceType: _selectedMaintenance!,
        maintenanceDescription: _descCtrl.text,
        maintenanceVehicleId: vehicleData['id'].toString(),
        maintenanceVehicleName: _selectedVehicle!,
      );

      await context
          .read<DeviceMaintenanceProvider>()
          .addMaintenance(maintenance);

      Navigator.pop(context);
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      suffixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _textField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      readOnly: onTap != null,
      onTap: onTap,
      maxLines: maxLines,
      decoration: _inputDecoration(label, icon),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  Widget _dropdown({
    required String label,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      decoration: _inputDecoration(label, Icons.arrow_drop_down),
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Add Maintenance Schedule',
            style: AppColors.appTitleTextStyle,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _textField(
                  ctrl: _dateCtrl,
                  label: 'Maintenance Date',
                  icon: Icons.calendar_today,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                _textField(
                  ctrl: _timeCtrl,
                  label: 'Maintenance Time',
                  icon: Icons.access_time,
                  onTap: _pickTime,
                ),
                const SizedBox(height: 16),
                _dropdown(
                  label: 'Maintenance Type',
                  items: maintenanceOptions,
                  value: _selectedMaintenance,
                  onChanged: (v) =>
                      setState(() => _selectedMaintenance = v),
                ),
                const SizedBox(height: 16),
                _textField(
                  ctrl: _descCtrl,
                  label: 'Description',
                  icon: Icons.description,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _dropdown(
                  label: 'Select Vehicle',
                  items: vehicleNames,
                  value: _selectedVehicle,
                  onChanged: (v) =>
                      setState(() => _selectedVehicle = v),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _save,
                      icon: _loading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.save,
                          color: Colors.black87),
                      label: Text(
                        _loading ? 'Saving...' : 'Save',
                        style:
                        const TextStyle(color: Colors.black87),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed:
                      _loading ? null : () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}