import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackerapp/data/response/status.dart';
import 'package:trackerapp/providers/alert_setting_provider.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/utils/utils.dart';

import '../widgets/live_tracking_page/loading_widget.dart';

class AlertsTypeListScreen extends StatefulWidget {
  const AlertsTypeListScreen({super.key});

  @override
  State<AlertsTypeListScreen> createState() =>
      _AlertsTypeListScreenState();
}

class _AlertsTypeListScreenState extends State<AlertsTypeListScreen> {
  late final AlertsProvider _provider;

  @override
  void initState() {
    super.initState();

    _provider = AlertsProvider();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.fetchAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AlertsProvider>.value(
      value: _provider,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'Alerts Settings',
              style: AppColors.appTitleTextStyle,
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            centerTitle: false,
          ),
          body: Consumer<AlertsProvider>(
            builder: (context, provider, _) {
              switch (provider.alertsResponse.status) {
                case Status.LOADING:
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LoadingWidget(),
                        SizedBox(height: 5),
                        Text('Loading...'),
                      ],
                    ),
                  );

                case Status.ERROR:
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.alertsResponse.errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => provider.fetchAlerts(),
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: const Text(
                              'Retry',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                case Status.COMPLETED:
                  final alerts =
                      provider.alertsResponse.data?.items?.alerts ?? [];

                  if (alerts.isEmpty) {
                    return const Center(
                      child: Text('No alerts available'),
                    );
                  }

                  return ListView.builder(
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Card(
                          shape: AppColors.cardBorderShape,
                          child: ListTile(
                            contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                            title: Text(
                              alert.name ?? "",
                              style: AppColors.settingTextstyle,
                            ),
                            trailing: SizedBox(
                              width: 50,
                              child: Checkbox(
                                activeColor: AppColors.buttonColor,
                                value: alert.active == 1,
                                onChanged: (val) async {
                                  Utils.toastMessage('Updating...');

                                  await provider.changeAlertStatus(
                                    alert.id.toString(),
                                    val == true ? 'true' : 'false',
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );

                default:
                  return const Center(
                    child: LoadingWidget(),
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}