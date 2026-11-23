import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trackerapp/res/colors.dart';

class FABWidget extends StatelessWidget {
  final double latestLat;
  final double latestLng;
  final bool enableTraffic;
  final MapType currentMapType;
  final VoidCallback onMapTypeChanged;
  final VoidCallback onTrafficToggled;

  const FABWidget({
    super.key,
    required this.latestLat,
    required this.latestLng,
    required this.enableTraffic,
    required this.currentMapType,
    required this.onMapTypeChanged,
    required this.onTrafficToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: MediaQuery.of(context).padding.top + 100,
      child: Column(
        children: [
          _buildFAB(
            context,
            Icons.map,
            onMapTypeChanged,
            'Map Type',
          ),
          _buildFAB(
            context,
            Icons.traffic,
            onTrafficToggled,
            'Traffic',
            color: enableTraffic ? Colors.green : AppColors.buttonColor,
          ),
          _buildFAB(
            context,
            Icons.streetview,
                () => MapsLauncher.launchCoordinates(latestLat, latestLng),
            'Street View',
          ),
          _buildFAB(
            context,
            Icons.share,
                () => Share.share(
              'https://www.google.com/maps/search/?api=1&map_action=pano&query=$latestLat,$latestLng',
            ),
            'Share',
          ),
          _buildFAB(
            context,
            Icons.arrow_back,
                () async {
              await Future.delayed(const Duration(milliseconds: 300));
              if (context.mounted) Navigator.of(context).pop();
            },
            'Back',
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(
      BuildContext context,
      IconData icon,
      VoidCallback onPressed,
      String label, {
        Color? color,
      }) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: FloatingActionButton(
        heroTag: UniqueKey(),
        mini: true,
        backgroundColor: color ?? AppColors.buttonColor,
        onPressed: onPressed,
        tooltip: label,
        child: Icon(icon, color: Colors.black54),
      ),
    );
  }
}