import Flutter
import Photos
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var galleryChannel: FlutterMethodChannel?

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
