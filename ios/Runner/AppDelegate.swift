import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var nfcHandler: NfcHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let nfcChannel = FlutterMethodChannel(
      name: "com.grapph.allcoderelay/nfc",
      binaryMessenger: controller.binaryMessenger)

    nfcHandler = NfcHandler(methodChannel: nfcChannel)
    nfcChannel.setMethodCallHandler { [weak self] call, result in
      self?.nfcHandler?.handle(call, result: result)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
