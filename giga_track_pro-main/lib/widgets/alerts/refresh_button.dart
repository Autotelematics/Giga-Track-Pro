import 'package:flutter/material.dart';
import 'package:trackerapp/providers/get_alert_provider.dart';
import 'package:trackerapp/res/colors.dart';

class RefreshButton extends StatelessWidget {
  final AlertsProvider provider;
  final VoidCallback onRefresh;

  const RefreshButton({
    super.key,
    required this.provider,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: provider.isManualRefreshing
                ? Colors.grey
                : AppColors.primary,
          ),
          tooltip: 'Refresh',
          onPressed: provider.isManualRefreshing
              ? null
              : onRefresh,
        ),
        if (provider.isManualRefreshing)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }
}