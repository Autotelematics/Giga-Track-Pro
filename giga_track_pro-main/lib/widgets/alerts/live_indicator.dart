import 'package:flutter/material.dart';
import 'package:trackerapp/providers/get_alert_provider.dart';

class LiveIndicator extends StatelessWidget {
  final AlertsProvider provider;

  const LiveIndicator({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final seconds = provider.countdownSeconds;
    final isWarning = seconds <= 2;
    final isLive = provider.isLiveEnabled;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause Button
        IconButton(
          icon: Icon(
            isLive ? Icons.pause_circle_outline : Icons.play_circle_outline,
            color: isLive ? Colors.green : Colors.grey,
            size: 28,
          ),
          onPressed: provider.toggleLiveRefresh,
          tooltip: isLive ? 'Pause Live Refresh' : 'Resume Live Refresh',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        // Live Status Badge
        Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isLive
                ? (isWarning
                    ? Colors.red.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1))
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLive
                  ? (isWarning ? Colors.red : Colors.green)
                  : Colors.grey,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLive)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isWarning ? Colors.red : Colors.green,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const Icon(
                  Icons.pause,
                  size: 12,
                  color: Colors.grey,
                ),
              const SizedBox(width: 6),
              Text(
                isLive ? 'LIVE' : 'PAUSED',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isLive
                      ? (isWarning ? Colors.red : Colors.green)
                      : Colors.grey,
                ),
              ),
              if (isLive) ...[
                const SizedBox(width: 4),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isWarning
                        ? Colors.red.withOpacity(0.15)
                        : Colors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isWarning ? Colors.red : Colors.green,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$seconds',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isWarning ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
