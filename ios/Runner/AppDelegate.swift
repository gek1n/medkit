import Flutter
import UIKit
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var apnsDebugChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Hedge against firebase_messaging's own registerForRemoteNotifications()
    // call not firing reliably on this Scene-based (FlutterImplicitEngineDelegate)
    // template. Safe to call unconditionally and early: iOS only actually
    // talks to APNs once notification permission is granted, so this is a
    // no-op until then.
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    apnsDebugChannel = FlutterMethodChannel(
      name: "com.ellyapp.medkit/apns_debug",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
  }

  // Manual APNs token capture — Firebase's own documented manual-integration
  // path (see Firebase iOS docs on "APNs token not being set"). The
  // automatic method-swizzling capture of this callback has been unreliable
  // on Flutter's Scene-based iOS template (see flutter/flutter#185048:
  // "Messaging.messaging().delegate is nil after plugin registration via
  // FlutterImplicitEngineDelegate") — iOS calls this delegate method fine,
  // but getAPNSToken() on the Dart side stayed null regardless. Setting
  // apnsToken here directly is safe to run alongside the automatic
  // swizzling if that ever starts working again: re-setting the same Data
  // value is a no-op.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
    apnsDebugChannel?.invokeMethod("nativeApnsTokenRegistered", arguments: hex)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    apnsDebugChannel?.invokeMethod("nativeApnsTokenFailed", arguments: error.localizedDescription)
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
