import 'package:flutter/material.dart';
import 'package:trackerapp/models/get_alerts_list_model.dart';
import 'package:trackerapp/providers/get_alert_provider.dart';
import 'package:trackerapp/widgets/alerts/alert_card.dart';
import 'package:trackerapp/widgets/alerts/alert_state_widgets.dart';
import 'package:trackerapp/widgets/common/shimmer_effect.dart';

class AlertListContent extends StatelessWidget {
  final AlertsProvider provider;
  final bool isInitialLoad;
  final ScrollController scrollController;
  final VoidCallback onClearSearch;
  final String searchQuery;
  final Function(Item)? onTapItem;

  const AlertListContent({
    super.key,
    required this.provider,
    required this.isInitialLoad,
    required this.scrollController,
    required this.onClearSearch,
    required this.searchQuery,
    this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final items = provider.filteredItems;
    final hasData = items.isNotEmpty || provider.model != null;

    // Show shimmer ONLY on initial load when there is NO data yet
    if (provider.isLoading && !hasData) {
      return const ShimmerAlertList();
    }

    // Error state when no data is available
    if (provider.errorMessage != null && !hasData) {
      return ErrorStateWidget(
        errorMessage: provider.errorMessage!,
        onRetry: () {
          provider.resetCountdown();
          provider.fetchAlerts(
            isRefresh: true,
            context: context,
            showLoading: true,
            isManual: true,
          );
        },
      );
    }

    // Empty state when no alerts exist
    if (items.isEmpty && !hasData && !provider.isLoading) {
      return EmptyStateWidget(
        onRefresh: () {
          provider.resetCountdown();
          provider.fetchAlerts(
            isRefresh: true,
            context: context,
            showLoading: true,
            isManual: true,
          );
        },
      );
    }

    // Search empty state
    if (items.isEmpty && hasData) {
      return SearchEmptyStateWidget(
        searchQuery: searchQuery,
        onClearSearch: onClearSearch,
      );
    }

    // Normal data list with Pull-to-Refresh & background updates (NO shimmer overlay!)
    return RefreshIndicator(
      onRefresh: () async {
        provider.resetCountdown();
        await provider.fetchAlerts(
          isRefresh: true,
          context: context,
          showLoading: false,
          isManual: true,
        );
      },
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: items.length + (provider.isLoadMore ? 1 : 0),
        itemBuilder: (ctx, index) {
          if (index == items.length) {
            return const LoadMoreIndicator();
          }
          return AlertCard(
            item: items[index],
            provider: provider,
            onTap: () {
              if (onTapItem != null) {
                onTapItem!(items[index]);
              }
            },
          );
        },
      ),
    );
  }
}
