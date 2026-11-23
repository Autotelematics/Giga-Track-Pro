import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackerapp/models/event_on_map_model.dart';
import 'package:trackerapp/models/events_intitial_data.dart';
import 'package:trackerapp/providers/get_alert_provider.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/utils/routes/routes_name.dart';
import 'package:trackerapp/widgets/alerts/alert_list_content.dart';
import 'package:trackerapp/widgets/alerts/alert_search_bar.dart';
import 'package:trackerapp/widgets/alerts/live_indicator.dart';
import 'package:trackerapp/widgets/alerts/refresh_button.dart';

import '../models/get_alerts_list_model.dart';

class EventsAlertsPage extends StatelessWidget {
  final EventsInitialData eventsInitialData;
  const EventsAlertsPage(this.eventsInitialData, {super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AlertsProvider()..startAutoRefresh(),
      child: _EventsAlertsBody(eventsInitialData),
    );
  }
}

class _EventsAlertsBody extends StatefulWidget {
  final EventsInitialData eventsInitialData;
  const _EventsAlertsBody(this.eventsInitialData);

  @override
  State<_EventsAlertsBody> createState() => _EventsAlertsBodyState();
}

class _EventsAlertsBodyState extends State<_EventsAlertsBody> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AlertsProvider>();

      // Set filters from initial data
      if (widget.eventsInitialData.deviceID != null &&
          widget.eventsInitialData.deviceID!.isNotEmpty) {
        provider.setDeviceIdFilter(widget.eventsInitialData.deviceID);
      } else {
        provider.setDeviceIdFilter(null);
      }

      if (widget.eventsInitialData.eventType != null &&
          widget.eventsInitialData.eventType!.isNotEmpty) {
        provider.setAlertTypeFilter(widget.eventsInitialData.eventType);
      } else {
        provider.setAlertTypeFilter(null);
      }

      provider.fetchAlerts(isRefresh: true, context: context, showLoading: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200) {
      context.read<AlertsProvider>().loadMore(context);
    }
  }

  void _onSearchChanged() {
    if (_isInitialLoad) {
      _isInitialLoad = false;
    }
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<AlertsProvider>().setSearchQuery(null);
    if (_isInitialLoad) {
      _isInitialLoad = false;
    }
  }

  void _handleRefresh(AlertsProvider provider) {
    provider.resetCountdown();
    provider.fetchAlerts(
      isRefresh: true,
      context: context,
      showLoading: false,
      isManual: true,
    );
  }

  Future<void> _confirmDeleteSelected(AlertsProvider provider) async {
    final count = provider.selectedCount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Alerts'),
        content: Text('Delete $count selected alert${count > 1 ? 's' : ''}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await provider.deleteSelectedAlerts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? '$count alert${count > 1 ? 's' : ''} deleted'
              : 'Failed to delete alerts. Try again.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ));
      }
    }
  }

  void _navigateToMap(BuildContext context, Item item) {
    Navigator.pushNamed(
      context,
      RoutesName.eventondevicemap,
      arguments: EventOnMapDataModel(
        intialLat: item.latitude,
        intiallng: item.longitude,
        vehiclename: item.deviceName,
        message: item.message,
        speed: item.speed,
        intialdirection: item.course,
        eventtime: item.time?.toString() ?? '-',
        address: item.address,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertsProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: _buildAppBar(provider),
          body: Column(
            children: [
              AlertSearchBar(
                controller: _searchController,
                provider: provider,
                onSearchChanged: _onSearchChanged,
              ),
              Expanded(
                child: AlertListContent(
                  provider: provider,
                  isInitialLoad: _isInitialLoad,
                  scrollController: _scrollController,
                  onClearSearch: _clearSearch,
                  searchQuery: _searchController.text,
                  onTapItem: (Item item) => _navigateToMap(context, item),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(AlertsProvider provider) {
    String title = 'Events & Alerts';
    if (provider.isSelectionMode) {
      title = '${provider.selectedCount} selected';
    } else if (widget.eventsInitialData.deviceID?.isNotEmpty ?? false) {
      title = 'Device Alerts';
    } else if (widget.eventsInitialData.eventType?.isNotEmpty ?? false) {
      title = 'Category: ${widget.eventsInitialData.eventType}';
    }

    return AppBar(
      title: Text(title, style: AppColors.appTitleTextStyle),
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: false,
      leading: provider.isSelectionMode
          ? IconButton(
        icon: const Icon(Icons.close),
        onPressed: provider.clearSelection,
      )
          : null,
      actions: [
        if (provider.isSelectionMode) ...[
          TextButton(
            onPressed: provider.selectAll,
            child: const Text('All',
                style: TextStyle(color: Colors.black87, fontSize: 13)),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete selected',
            onPressed: () => _confirmDeleteSelected(provider),
          ),
        ] else ...[
          LiveIndicator(provider: provider),
          RefreshButton(
            provider: provider,
            onRefresh: () => _handleRefresh(provider),
          ),
        ],
      ],
    );
  }
}