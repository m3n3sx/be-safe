import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Klucz Maps SDK for iOS z Info.plist (GMSApiKey = $(GOOGLE_MAPS_IOS_API_KEY)),
    // wstrzykiwany w czasie builda z ios/Flutter/Secrets.xcconfig (gitignored) — nie commitujemy go.
    if let mapsKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !mapsKey.isEmpty, !mapsKey.hasPrefix("$(") {
      GMSServices.provideAPIKey(mapsKey)
    } else {
      NSLog("WARNING: brak GOOGLE_MAPS_IOS_API_KEY — Google Maps nie zadziała")
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
