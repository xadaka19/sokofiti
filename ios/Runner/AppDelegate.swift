import UIKit
import Flutter
import FirebaseCore
import GoogleMaps
import FirebaseAuth
import awesome_notifications
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyDPl2XUqbM80fVEKZHSGoP5x4K_LJoZhk8")
    GeneratedPluginRegistrant.register(with: self)
      
      SwiftAwesomeNotificationsPlugin.setPluginRegistrantCallback { registry in
               SwiftAwesomeNotificationsPlugin.register(
                 with: registry.registrar(forPlugin: "io.flutter.plugins.awesomenotifications.AwesomeNotificationsPlugin")!)
           }
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
 override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }

}

