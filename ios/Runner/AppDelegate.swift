import Flutter
import UIKit
// TEMPORARILY DISABLED - No iOS physical device for testing
// import Firebase
// import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // TEMPORARILY DISABLED - No iOS physical device for testing
    // FirebaseApp.configure()
    
    // Request notification permissions
    // if #available(iOS 10.0, *) {
    //   UNUserNotificationCenter.current().delegate = self
    //   let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    //   UNUserNotificationCenter.current().requestAuthorization(
    //     options: authOptions,
    //     completionHandler: { _, _ in }
    //   )
    // } else {
    //   let settings: UIUserNotificationSettings =
    //     UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
    //   application.registerUserNotificationSettings(settings)
    // }
    
    // application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // TEMPORARILY DISABLED - No iOS physical device for testing
  // Handle notification when app is in foreground
  // override func userNotificationCenter(
  //   _ center: UNUserNotificationCenter,
  //   willPresent notification: UNNotification,
  //   withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  // ) {
  //   completionHandler([[.alert, .sound, .badge]])
  // }
  
  // Handle notification tap
  // override func userNotificationCenter(
  //   _ center: UNUserNotificationCenter,
  //   didReceive response: UNNotificationResponse,
  //   withCompletionHandler completionHandler: @escaping () -> Void
  // ) {
  //   completionHandler()
  // }
}
