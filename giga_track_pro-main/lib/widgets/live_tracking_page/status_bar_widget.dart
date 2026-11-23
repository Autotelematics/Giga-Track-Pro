import 'package:flutter/material.dart';
import 'package:trackerapp/res/components/app_end_point.dart';

class StatusBarWidget extends StatelessWidget {
  final String vehicleName;
  final String updateTime;
  final String vehicleSpeed;
  final String vehicleStatus;
  final Color vehicleStatusColor;
  final Color mainBoxBackgroundColor;
  final String runningOrStoppedTime;

  const StatusBarWidget({
    super.key,
    required this.vehicleName,
    required this.updateTime,
    required this.vehicleSpeed,
    required this.vehicleStatus,
    required this.vehicleStatusColor,
    required this.mainBoxBackgroundColor,
    required this.runningOrStoppedTime,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: mainBoxBackgroundColor,
          borderRadius: BorderRadius.circular(15.0),
        ),
        height: 70,
        child: Row(
          children: [
            // Vehicle Icon
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black,
                    radius: 24.4,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 23,
                      child: Image(
                        fit: BoxFit.contain,
                        image: NetworkImage(
                          AppUrl.baseImgURL +
                              (vehicleName.isNotEmpty
                                  ? 'assets/images/car_icon6.png'
                                  : 'assets/images/car_icon6.png'),
                        ),
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.directions_car),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Vehicle Info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Vehicle Name
                  Text(
                    vehicleName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: vehicleStatusColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Last Update Time (e.g., "2:45 PM")
                  Text(
                    updateTime,
                    style: TextStyle(
                      color: vehicleStatusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  // ✅ SHOW "Running since 5 mins" OR "Stop since 10 mins"
                  Text(
                    runningOrStoppedTime,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: vehicleStatusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Speed
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    vehicleSpeed,
                    style: TextStyle(
                      color: vehicleStatusColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'km/h',
                    style: TextStyle(
                      color: vehicleStatusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  Text(
                    vehicleStatus,
                    style: TextStyle(
                      color: vehicleStatusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}