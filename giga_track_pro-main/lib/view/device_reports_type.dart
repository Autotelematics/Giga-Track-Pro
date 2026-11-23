import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trackerapp/data/response/status.dart';
import 'package:trackerapp/models/device_history_on_map.dart';
import 'package:trackerapp/models/view_report_intial_data.dart';
import 'package:trackerapp/providers/device_reports_view_provider.dart';
import 'package:trackerapp/res/colors.dart';
import 'package:trackerapp/utils/routes/routes_name.dart';

class ReportTypeScreen extends StatefulWidget {
  final DeviceHistoryOnMapInitialData initialData;

  const ReportTypeScreen(this.initialData, {super.key});

  @override
  State<ReportTypeScreen> createState() => _ReportTypeScreenState();
}

class _ReportTypeScreenState extends State<ReportTypeScreen> {
  late ReportTypeProvider _reportTypeViewProvider;

  late DateTime _fromDateTime;
  late DateTime _toDateTime;
  String _selectedFilterKey = 'today';

  final DateFormat _dateApiFormat = DateFormat("yyyy-MM-dd");
  final DateFormat _timeApiFormat = DateFormat("HH:mm:ss");
  final DateFormat _dateDisplayFormat = DateFormat("dd MMM yyyy");
  final DateFormat _timeDisplayFormat = DateFormat("hh:mm a");

  @override
  void initState() {
    super.initState();
    _reportTypeViewProvider = ReportTypeProvider();
    _reportTypeViewProvider.fetchReportTypes();
    _initDateTimes();
  }

  @override
  void dispose() {
    _reportTypeViewProvider.dispose();
    super.dispose();
  }

  void _initDateTimes() {
    final now = DateTime.now();

    DateTime from = _parseDateString(widget.initialData.fromDate) ??
        DateTime(now.year, now.month, now.day, 0, 0, 0);
    DateTime to = _parseDateString(widget.initialData.toDate) ??
        DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (widget.initialData.fromTime != null && widget.initialData.fromTime!.isNotEmpty) {
      final t = _parseTimeString(widget.initialData.fromTime!);
      from = DateTime(from.year, from.month, from.day, t.hour, t.minute, t.second);
    } else {
      from = DateTime(from.year, from.month, from.day, 0, 0, 0);
    }

    if (widget.initialData.toTime != null && widget.initialData.toTime!.isNotEmpty) {
      final t = _parseTimeString(widget.initialData.toTime!);
      to = DateTime(to.year, to.month, to.day, t.hour, t.minute, t.second);
    } else {
      to = DateTime(to.year, to.month, to.day, 23, 59, 59);
    }

    _fromDateTime = from;
    _toDateTime = to;
    _updateSelectedFilterKey();
  }

  DateTime? _parseDateString(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      return DateFormat("yyyy-MM-dd").parse(dateStr);
    } catch (_) {}
    try {
      return DateFormat("yy-MM-dd").parse(dateStr);
    } catch (_) {}
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}
    return null;
  }

  ({int hour, int minute, int second}) _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final second = parts.length >= 3 ? int.parse(parts[2]) : 0;
        return (hour: hour, minute: minute, second: second);
      }
    } catch (_) {}
    return (hour: 0, minute: 0, second: 0);
  }

  void _updateSelectedFilterKey() {
    final now = DateTime.now();
    final todayStr = _dateApiFormat.format(now);
    final yesterdayStr = _dateApiFormat.format(now.subtract(const Duration(days: 1)));
    final last7Str = _dateApiFormat.format(now.subtract(const Duration(days: 6)));
    final last30Str = _dateApiFormat.format(now.subtract(const Duration(days: 29)));

    final fromStr = _dateApiFormat.format(_fromDateTime);
    final toStr = _dateApiFormat.format(_toDateTime);

    if (fromStr == todayStr && toStr == todayStr) {
      _selectedFilterKey = 'today';
    } else if (fromStr == yesterdayStr && toStr == yesterdayStr) {
      _selectedFilterKey = 'yesterday';
    } else if (fromStr == last7Str && toStr == todayStr) {
      _selectedFilterKey = 'last7';
    } else if (fromStr == last30Str && toStr == todayStr) {
      _selectedFilterKey = 'last30';
    } else {
      _selectedFilterKey = 'custom';
    }
  }

  void _onFilterChipSelected(String key) {
    final now = DateTime.now();
    setState(() {
      _selectedFilterKey = key;
      switch (key) {
        case 'today':
          _fromDateTime = DateTime(now.year, now.month, now.day, 0, 0, 0);
          _toDateTime = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'yesterday':
          final yesterday = now.subtract(const Duration(days: 1));
          _fromDateTime = DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0);
          _toDateTime = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
          break;
        case 'last7':
          final start7 = now.subtract(const Duration(days: 6));
          _fromDateTime = DateTime(start7.year, start7.month, start7.day, 0, 0, 0);
          _toDateTime = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'last30':
          final start30 = now.subtract(const Duration(days: 29));
          _fromDateTime = DateTime(start30.year, start30.month, start30.day, 0, 0, 0);
          _toDateTime = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'custom':
          _showCustomDateTimePickerDialog();
          break;
      }
    });
  }

  void _showCustomDateTimePickerDialog() async {
    DateTime tempFrom = _fromDateTime;
    DateTime tempTo = _toDateTime;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Custom Date & Time',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // From Section
                      _buildDialogTile(
                        context: dialogContext,
                        title: 'From (Start)',
                        dateTime: tempFrom,
                        onDateTap: () async {
                          final pickedDate = await showDatePicker(
                            context: dialogContext,
                            initialDate: tempFrom.isAfter(DateTime.now())
                                ? DateTime.now()
                                : tempFrom,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            setDialogState(() {
                              tempFrom = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                tempFrom.hour,
                                tempFrom.minute,
                                0,
                              );
                              if (tempTo.isBefore(tempFrom)) {
                                tempTo = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  23,
                                  59,
                                  59,
                                );
                              }
                            });
                          }
                        },
                        onTimeTap: () async {
                          final pickedTime = await showTimePicker(
                            context: dialogContext,
                            initialTime: TimeOfDay(
                              hour: tempFrom.hour,
                              minute: tempFrom.minute,
                            ),
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context)
                                    .copyWith(alwaysUse24HourFormat: false),
                                child: child!,
                              );
                            },
                          );
                          if (pickedTime != null) {
                            setDialogState(() {
                              tempFrom = DateTime(
                                tempFrom.year,
                                tempFrom.month,
                                tempFrom.day,
                                pickedTime.hour,
                                pickedTime.minute,
                                0,
                              );
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // To Section
                      _buildDialogTile(
                        context: dialogContext,
                        title: 'To (End)',
                        dateTime: tempTo,
                        onDateTap: () async {
                          final pickedDate = await showDatePicker(
                            context: dialogContext,
                            initialDate: tempTo.isAfter(DateTime.now())
                                ? DateTime.now()
                                : tempTo,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            setDialogState(() {
                              tempTo = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                tempTo.hour,
                                tempTo.minute,
                                59,
                              );
                            });
                          }
                        },
                        onTimeTap: () async {
                          final pickedTime = await showTimePicker(
                            context: dialogContext,
                            initialTime: TimeOfDay(
                              hour: tempTo.hour,
                              minute: tempTo.minute,
                            ),
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context)
                                    .copyWith(alwaysUse24HourFormat: false),
                                child: child!,
                              );
                            },
                          );
                          if (pickedTime != null) {
                            setDialogState(() {
                              tempTo = DateTime(
                                tempTo.year,
                                tempTo.month,
                                tempTo.day,
                                pickedTime.hour,
                                pickedTime.minute,
                                59,
                              );
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Apply button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            if (tempTo.isBefore(tempFrom)) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'End date and time cannot be earlier than start date and time.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            setState(() {
                              _fromDateTime = tempFrom;
                              _toDateTime = tempTo;
                              _selectedFilterKey = 'custom';
                            });
                            Navigator.of(dialogContext).pop();
                          },
                          child: const Text(
                            'Apply Filter',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogTile({
    required BuildContext context,
    required String title,
    required DateTime dateTime,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onDateTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _dateDisplayFormat.format(dateTime),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: onTimeTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.blue),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _timeDisplayFormat.format(dateTime),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsBar() {
    final filters = [
      {'key': 'today', 'label': 'Today'},
      {'key': 'yesterday', 'label': 'Yesterday'},
      {'key': 'last7', 'label': 'Last 7 Days'},
      {'key': 'last30', 'label': 'Last 30 Days'},
      {'key': 'custom', 'label': 'Custom'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final key = f['key']!;
            final label = f['label']!;
            final isSelected = _selectedFilterKey == key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                selected: isSelected,
                selectedColor: Colors.blue,
                backgroundColor: Colors.grey.shade100,
                onSelected: (_) => _onFilterChipSelected(key),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    String filterLabel = 'Today';
    switch (_selectedFilterKey) {
      case 'today':
        filterLabel = 'Today';
        break;
      case 'yesterday':
        filterLabel = 'Yesterday';
        break;
      case 'last7':
        filterLabel = 'Last 7 Days';
        break;
      case 'last30':
        filterLabel = 'Last 30 Days';
        break;
      case 'custom':
        filterLabel = 'Custom Range';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device info & filter badge
          Row(
            children: [
              const Icon(Icons.directions_car, color: Colors.blue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vehicle',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.initialData.deviceTitle?.toString() ?? 'Device',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  filterLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Date & Time range info (Tapping opens custom dialog)
          InkWell(
            onTap: _showCustomDateTimePickerDialog,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDateInfo(
                      label: 'From',
                      dateTime: _fromDateTime,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDateInfo(
                      label: 'To',
                      dateTime: _toDateTime,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_calendar, size: 18, color: Colors.blue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo({
    required String label,
    required DateTime dateTime,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _dateDisplayFormat.format(dateTime),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          _timeDisplayFormat.format(dateTime),
          style: const TextStyle(
            fontSize: 11,
            color: Colors.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildReportsList(ReportTypeProvider provider) {
    switch (provider.reportTypeResponse.status) {
      case Status.LOADING:
        return const Center(
          child: CircularProgressIndicator(),
        );

      case Status.ERROR:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  provider.reportTypeResponse.errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _reportTypeViewProvider.fetchReportTypes(),
                child: const Text('Retry'),
              ),
            ],
          ),
        );

      case Status.COMPLETED:
        final reports = provider.reportTypeResponse.data?.items ?? [];

        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No reports available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _buildReportCard(report, index);
          },
        );


    }
  }

  Widget _buildReportCard(dynamic report, int index) {
    return Card(
      shape: AppColors.cardBorderShape,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      child: InkWell(
        onTap: () => _navigateToReport(report),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.file_present,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.name.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to view report',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToReport(dynamic report) {
    try {
      if (report == null) {
        _showErrorSnackBar('Invalid report data');
        return;
      }
      final reportType = int.tryParse(report.type.toString());
      final deviceId = int.tryParse(widget.initialData.deviceId.toString());
      if (reportType == null || deviceId == null) {
        _showErrorSnackBar('Invalid report data');
        return;
      }

      final fromDateStr = _dateApiFormat.format(_fromDateTime);
      final toDateStr = _dateApiFormat.format(_toDateTime);
      final fromTimeStr = _timeApiFormat.format(_fromDateTime);
      final toTimeStr = _timeApiFormat.format(_toDateTime);

      Navigator.pushNamed(
        context,
        RoutesName.getreports,
        arguments: ViewReportInitialData(
          fromDateStr,
          toDateStr,
          deviceId,
          'pdf',
          reportType,
          fromTime: fromTimeStr,
          toTime: toTimeStr,
        ),
      );
    } catch (e) {
      debugPrint('Navigation Error: $e');
      _showErrorSnackBar('Failed to open report');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.blue),
            tooltip: 'Filter Date & Time',
            onPressed: _showCustomDateTimePickerDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChipsBar(),
          _buildHeaderInfo(),
          Expanded(
            child: ChangeNotifierProvider.value(
              value: _reportTypeViewProvider,
              child: Consumer<ReportTypeProvider>(
                builder: (context, provider, _) => _buildReportsList(provider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
