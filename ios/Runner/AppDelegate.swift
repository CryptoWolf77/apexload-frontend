import Flutter
import Photos
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var galleryChannel: FlutterMethodChannel?
  private var backgroundChannel: FlutterMethodChannel?
  private var shareChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard
      let registrar = engineBridge.pluginRegistry.registrar(
        forPlugin: "ApexLoadGallery"
      )
    else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "apexload/ios",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "publishToGallery" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.publishToPhotos(call: call, result: result)
    }
    galleryChannel = channel
    let background = FlutterMethodChannel(name: "apexload/background", binaryMessenger: registrar.messenger())
    background.setMethodCallHandler { call, result in
      BackgroundTransfers.shared.handle(call, result: result)
    }
    backgroundChannel = background
    BackgroundTransfers.shared.reconnect()
    let shares = FlutterMethodChannel(name: "apexload/share", binaryMessenger: registrar.messenger())
    shares.setMethodCallHandler { call, result in
      guard let defaults = UserDefaults(suiteName: "group.com.yahyazlab.apexload") else {
        result(FlutterError(code: "share_group_unavailable", message: "Share container is unavailable.", details: nil))
        return
      }
      switch call.method {
      case "takeSharedText":
        let text = defaults.string(forKey: "pendingSharedText")
        defaults.removeObject(forKey: "pendingSharedText")
        result(text)
      case "setShareConsent":
        if let args = call.arguments as? [String: Any] {
          defaults.set(args["accepted"] as? Bool ?? false, forKey: "responsibleUseAcceptedV1")
          defaults.set(args["analyzeUrl"] as? String, forKey: "analyzeUrl")
        }
        result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    }
    shareChannel = shares
  }

  override func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String,
                            completionHandler: @escaping () -> Void) {
    if identifier == BackgroundTransfers.identifier {
      BackgroundTransfers.shared.completionHandler = completionHandler
      BackgroundTransfers.shared.reconnect()
    } else {
      super.application(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
    }
  }

  private func publishToPhotos(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let sourcePath = arguments["sourcePath"] as? String,
      let mediaType = arguments["type"] as? String
    else {
      result(
        FlutterError(
          code: "invalid_arguments",
          message: "A source path and media type are required.",
          details: nil
        )
      )
      return
    }
    guard mediaType == "video" || mediaType == "image" else {
      result(nil)
      return
    }

    let sourceURL = URL(fileURLWithPath: sourcePath)
    guard FileManager.default.fileExists(atPath: sourceURL.path) else {
      result(
        FlutterError(
          code: "file_missing",
          message: "The media file no longer exists.",
          details: nil
        )
      )
      return
    }

    PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
      guard status == .authorized || status == .limited else {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "photos_permission_denied",
              message: "Photos permission was not granted.",
              details: nil
            )
          )
        }
        return
      }

      PHPhotoLibrary.shared().performChanges {
        if mediaType == "video" {
          PHAssetChangeRequest.creationRequestForAssetFromVideo(
            atFileURL: sourceURL
          )
        } else {
          PHAssetChangeRequest.creationRequestForAssetFromImage(
            atFileURL: sourceURL
          )
        }
      } completionHandler: { success, error in
        DispatchQueue.main.async {
          if success {
            result("photos://saved")
          } else {
            result(
              FlutterError(
                code: "photos_save_failed",
                message: error?.localizedDescription
                  ?? "The media could not be saved to Photos.",
                details: nil
              )
            )
          }
        }
      }
    }
  }
}
