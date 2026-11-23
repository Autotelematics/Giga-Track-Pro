import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';

import 'package:trackerapp/providers/device_live_tracking_provider.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/utils/string_extensions.dart';

class CurrentLocationPanel extends StatefulWidget {
  final Color keyColor;
  final String keyStatus;
  final Color batteryChargingColor;
  final String batteryVoltage;
  final bool immobilizerValue;

  const CurrentLocationPanel({
    super.key,
    required this.keyColor,
    required this.keyStatus,
    required this.batteryChargingColor,
    required this.batteryVoltage,
    required this.immobilizerValue,
  });

  @override
  State<CurrentLocationPanel> createState() => _CurrentLocationPanelState();
}

class _CurrentLocationPanelState extends State<CurrentLocationPanel> {
  String? _lastAddress;
  String? _translatedAddress;
  bool _isTranslating = false;

  Future<void> _translateAddress(String address) async {
    if (address.isEmpty || address == _lastAddress) return;

    setState(() {
      _lastAddress = address;
      _isTranslating = true;
    });

    final translated = await address.toUrdu();

    if (mounted && address == _lastAddress) {
      setState(() {
        _translatedAddress = translated;
        _isTranslating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GFButton(
                    onPressed: () {},
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    icon: Icon(Icons.key, color: widget.keyColor),
                    text: widget.keyStatus,
                    textColor: Colors.black54,
                    size: GFSize.SMALL,
                    shape: GFButtonShape.pills,
                    color: Colors.black12,
                  ),
                  GFIconButton(
                    onPressed: () {},
                    padding: const EdgeInsets.all(4),
                    icon: Icon(
                      Icons.battery_charging_full_outlined,
                      color: widget.batteryChargingColor,
                    ),
                    iconSize: 20,
                    color: Colors.black12,
                    shape: GFIconButtonShape.circle,
                  ),
                  GFIconButton(
                    onPressed: () {},
                    padding: const EdgeInsets.all(4),
                    icon: const Icon(Icons.wifi, color: Colors.green),
                    iconSize: 20,
                    color: Colors.black12,
                    shape: GFIconButtonShape.circle,
                  ),
                  GFIconButton(
                    onPressed: () {},
                    padding: const EdgeInsets.all(4),
                    icon: widget.immobilizerValue
                        ? const Icon(Icons.lock, color: Colors.red)
                        : const Icon(Icons.lock_open, color: Colors.green),
                    iconSize: 20,
                    color: Colors.black12,
                    shape: GFIconButtonShape.circle,
                  ),
                  GFButton(
                    onPressed: () {},
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    icon: const Icon(Icons.battery_5_bar, color: Colors.green),
                    text: widget.batteryVoltage,
                    textColor: Colors.black54,
                    size: GFSize.SMALL,
                    shape: GFButtonShape.pills,
                    color: Colors.black12,
                  ),
                ],
              ),
              const Divider(height: 5),
              GFTypography(
                text: 'Current Location',
                type: AppColors.deviceOnMapSligePanelHeading,
                icon: Icon(Icons.location_on_outlined, color: Colors.blue[800]),
                showDivider: false,
                fontWeight: FontWeight.bold,
                textColor: Colors.blue[800],
              ),
              const Divider(height: 5),
              Consumer<VehicleTrackingProvider>(
                builder: (context, provider, _) {
                  final address = provider.address;
                  
                  // Trigger translation if address changed
                  if (address.isNotEmpty && address != _lastAddress) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _translateAddress(address);
                    });
                  }

                  return Text(
                    _translatedAddress ?? (address.isNotEmpty ? address : 'Address not available'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}