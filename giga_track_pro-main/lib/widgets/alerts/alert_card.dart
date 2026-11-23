import 'package:flutter/material.dart';
import 'package:trackerapp/models/get_alerts_list_model.dart';
import 'package:trackerapp/providers/get_alert_provider.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/res/components/custometitletontainer.dart';
import 'package:trackerapp/utils/date_time_extension.dart';

class AlertCard extends StatelessWidget {
  final Item item;
  final AlertsProvider provider;
  final VoidCallback? onTap;

  const AlertCard({
    super.key,
    required this.item,
    required this.provider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = provider.selectedAlertIds.contains(item.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: GestureDetector(
        onLongPress: () {
          if (!provider.isSelectionMode) {
            provider.enterSelectionMode(item.id);
          }
        },
        onTap: () {
          if (provider.isSelectionMode) {
            provider.toggleSelection(item.id);
          } else {
            if (onTap != null) {
              onTap!();
            }
          }
        },
        child: Card(
          shape: AppColors.cardBorderShape,
          color: isSelected ? const Color(0xffffdddd) : Colors.white,
          elevation: isSelected ? 3 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomTitleContainer(titleText: item.deviceName),
                  if (provider.isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.red.shade400 : Colors.grey,
                        size: 22,
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 15,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_outlined,
                      color: Colors.red,
                      size: 26,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      item.time != null
                          ? item.time.toString().toFormattedDateTime()
                          : '-',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}