import 'package:flutter/material.dart';
import 'package:trackerapp/models/device_history_on_map.dart';
import 'package:trackerapp/models/device_on_map_model.dart';
import 'package:trackerapp/models/event_on_map_model.dart';
import 'package:trackerapp/models/events_intitial_data.dart';
import 'package:trackerapp/models/view_report_intial_data.dart';
import 'package:trackerapp/view/add_device_maintenance_screen.dart';
import 'package:trackerapp/view/alert_list.dart';
import 'package:trackerapp/view/alert_setting_list.dart';
import 'package:trackerapp/view/contact_us_screen.dart';
import 'package:trackerapp/view/view_alert_on_map.dart';
import 'package:trackerapp/view/geo_fence_list.dart';
import 'package:trackerapp/view/home.dart';
import 'package:trackerapp/view/login.dart';
import 'package:trackerapp/view/device_history_on_map.dart';
import 'package:trackerapp/view/device_reports_type.dart';
import 'package:trackerapp/view/device_live_tracking.dart';
import 'package:trackerapp/view/splash_screen.dart';
import 'package:trackerapp/utils/routes/routes_name.dart';
import 'package:trackerapp/view/device_fuel_list.dart';
import 'package:trackerapp/view/view_device_fuel.dart';
import 'package:trackerapp/view/device_history_list.dart';
import 'package:trackerapp/view/device_report_list.dart';
import 'package:trackerapp/view/view_expense_record.dart';
import 'package:trackerapp/view/view_report_screen.dart';
import 'package:trackerapp/view/view_device_upcoming_maintenance.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutesName.splashSceen:
        return MaterialPageRoute(
          builder: (BuildContext context) => const SplashScreen(),
        );

      case RoutesName.login:
        return MaterialPageRoute(
          builder: (BuildContext context) => Login(),
        );

      case RoutesName.geoFenceList:
        return MaterialPageRoute(
          builder: (BuildContext context) => const GeoFenceListScreen(),
        );

      case RoutesName.vehiclereportlist:
        return MaterialPageRoute(
          builder: (BuildContext context) => const VehicleReportList(),
        );

      case RoutesName.addVehicleMaintenanceScreen:
        return MaterialPageRoute(
          builder: (BuildContext context) =>
          const AddVehicleMaintenanceScreen(),
        );

      case RoutesName.vehiclehistorylist:
        return MaterialPageRoute(
          builder: (BuildContext context) => const VehicleHistoryList(),
        );

      case RoutesName.viewVehicleFuelList:
        return MaterialPageRoute(
          builder: (BuildContext context) => const VehicleFuelListScreen(),
        );

      case RoutesName.viewExpenseScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final vehicleId = args['vehicleId'] as String;
        return MaterialPageRoute(
          builder: (BuildContext context) =>
              ExpenseRecordsTable(vehicleId: vehicleId),
        );

      case RoutesName.contactusScreen:
        return MaterialPageRoute(
          builder: (BuildContext context) => const ContactUsScreen(),
        );

      case RoutesName.viewMaintenanceSchedule:
        return MaterialPageRoute(
          builder: (BuildContext context) => const ViewMaintenanceSchedule(),
        );

      case RoutesName.getreports:
        final viewReportIntialData = settings.arguments as ViewReportInitialData;
        return MaterialPageRoute(
          builder: (BuildContext context) =>
              GetReportScreen(viewReportIntialData),
        );

      case RoutesName.eventsScreen:
        final eventsInitialData = settings.arguments as EventsInitialData;
        return MaterialPageRoute(
          builder: (BuildContext context) =>
              EventsAlertsPage(eventsInitialData),
        );

      case RoutesName.reporttype:
        final deviceHistoryOnMapIntialData =
        settings.arguments as DeviceHistoryOnMapInitialData;
        return MaterialPageRoute(
          builder: (BuildContext context) =>
              ReportTypeScreen(deviceHistoryOnMapIntialData),
        );

      case RoutesName.playroutonmap:
        final deviceHistoryOnMapIntialData =
        settings.arguments as DeviceHistoryOnMapInitialData;
        return MaterialPageRoute(
          builder: (BuildContext context) =>
              HistoryPlayRoutOnMap(deviceHistoryOnMapIntialData),
        );

    // ✅ FIXED - Pass arguments to screen
      case RoutesName.viewVehicleFuelReport:
        final deviceHistoryOnMapIntialData =
        settings.arguments as DeviceHistoryOnMapInitialData;
        return MaterialPageRoute(
          builder: (BuildContext context) =>
              VehicleFuelReportViewScreen(deviceHistoryOnMapIntialData),
        );

      case RoutesName.home:
        return MaterialPageRoute(
          builder: (BuildContext context) => const HomePage(),
        );

      case RoutesName.alertsTypeList:
        return MaterialPageRoute(
          builder: (BuildContext context) => const AlertsTypeListScreen(),
        );

      case RoutesName.eventondevicemap:
        final eventsOnMapDataModel = settings.arguments as EventOnMapDataModel;
        return MaterialPageRoute(
          builder: (BuildContext context) => EventsOnMap(eventsOnMapDataModel),
        );

      case RoutesName.singledevicemap:
        final deviceOnMapintialData =
        settings.arguments as DeviceOnMapInitialData;
        return MaterialPageRoute(
          builder: (BuildContext context) =>
              SingleDeviceOnMap(deviceOnMapintialData),
        );

      default:
        return MaterialPageRoute(
          builder: (BuildContext context) => const SplashScreen(),
        );
    }
  }
}