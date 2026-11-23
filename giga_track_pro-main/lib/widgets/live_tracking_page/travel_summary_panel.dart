import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:provider/provider.dart';
import 'package:trackerapp/data/response/status.dart' show Status;
import 'package:trackerapp/providers/get_device_history_provider.dart';
import 'package:trackerapp/res/colors.dart';

class TravelSummaryPanel extends StatelessWidget {
  final double vehicleFuelAveragePerKm;
  final double? currentFuelCost;
  final Function(int) onTravelSummaryFetch;

  const TravelSummaryPanel({
    super.key,
    required this.vehicleFuelAveragePerKm,
    required this.currentFuelCost,
    required this.onTravelSummaryFetch,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryPlayRoutOnMapProvider>(
      builder: (context, historyProvider, _) {
        final historyResponse = historyProvider.deviceRoutHistoryResponse;

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
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: GFTypography(
                      text: 'Travel Summary',
                      type: AppColors.deviceOnMapSligePanelHeading,
                      icon: Icon(Icons.travel_explore_outlined,
                          color: Colors.blue[800]),
                      showDivider: false,
                      textColor: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton(
                    shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    onSelected: onTravelSummaryFetch,
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(value: 0, child: Text('Today')),
                        PopupMenuItem(value: 1, child: Text('Yesterday')),
                        PopupMenuItem(value: 7, child: Text('7 Days')),
                        PopupMenuItem(value: 30, child: Text('30 Days')),
                      ];
                    },
                  )
                ],
              ),
              const Divider(height: 5),
              if (historyResponse.status == Status.LOADING)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                )
              else if (historyResponse.status == Status.COMPLETED &&
                  historyResponse.data != null)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 10),
                      child: Text(
                        'Today, Your vehicle traveled ${historyResponse.data!.distanceSum} with maximum speed at ${historyResponse.data!.topSpeed}.',
                        style: TextStyle(color: Colors.grey[700]),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Fuel Used',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_calculateFuelUsed(historyResponse.data!.distanceSum.toString(), vehicleFuelAveragePerKm).toStringAsFixed(2)} liters',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Fuel Cost',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rs.${_calculateFuelCost(historyResponse.data!.distanceSum.toString(), vehicleFuelAveragePerKm, currentFuelCost ?? 0).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Running Time',
                                  style: TextStyle(
                                    color: Colors.green[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  historyResponse.data!.moveDuration.toString(),
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Stop Time',
                                  style: TextStyle(
                                    color: Colors.red[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  historyResponse.data!.stopDuration
                                      .toString(),
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else if (historyResponse.status == Status.ERROR)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 10),
                  child: Text(
                    historyResponse.errorMessage ?? 'Failed to load history',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 10),
                  child: Text(
                    'No data available',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              const Divider(height: 5),
            ],
          ),
        );
      },
    );
  }

  double _calculateFuelUsed(String distanceSum, double fuelAverage) {
    try {
      var arr = distanceSum.split(' ');
      if (arr.isNotEmpty) {
        double distance = double.parse(arr[0]);
        return distance / fuelAverage;
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    return 0.0;
  }

  double _calculateFuelCost(
      String distanceSum, double fuelAverage, double fuelPrice) {
    double fuelUsed = _calculateFuelUsed(distanceSum, fuelAverage);
    return fuelUsed * fuelPrice;
  }
}