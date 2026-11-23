import UIKit
import Flutter
import flutter_local_notifications
import FirebaseCore
import GoogleMaps
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Google Maps API Key
    GMSServices.provideAPIKey("AIzaSyAkvOdakBq6F661E8GL8HHeN0EDh23pPQE")

    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    // Notification delegate setup (safe)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // Flutter local notifications callback
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}