import Flutter
import UIKit
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate,
                          FlutterImplicitEngineDelegate,
                          MessagingDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        print("🚀🚀🚀 AppDelegate didFinishLaunching")

        Messaging.messaging().delegate = self

        UNUserNotificationCenter.current().delegate = self

        application.registerForRemoteNotifications()

        print("📡📡📡 registerForRemoteNotifications CALLED")

        return super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }

    func didInitializeImplicitFlutterEngine(
        _ engineBridge: FlutterImplicitEngineBridge
    ) {
        GeneratedPluginRegistrant.register(
            with: engineBridge.pluginRegistry
        )
    }

    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken
            .map { String(format: "%02.2hhx", $0) }
            .joined()

        print("🍎🍎🍎 APNs DEVICE TOKEN: \(token)")

        Messaging.messaging().apnsToken = deviceToken
    }

    override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌❌❌ APNs registration FAILED")
        print("❌ Error: \(error.localizedDescription)")
    }

    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        print("🔥🔥🔥 FCM TOKEN: \(fcmToken ?? "nil")")
    }
}