import Flutter
import UIKit

/// The OS owns these transfers while Flutter is suspended. Backend status uses
/// download tasks too, so a completed server job can schedule the file transfer.
final class BackgroundTransfers: NSObject, URLSessionDownloadDelegate {
  static let shared = BackgroundTransfers()
  static let identifier = "com.yahyazlab.apexload.downloads"
  private var results: [String: FlutterResult] = [:]
  var completionHandler: (() -> Void)?
  private var executionTime: UIBackgroundTaskIdentifier = .invalid
  private lazy var session: URLSession = {
    let config = URLSessionConfiguration.background(withIdentifier: Self.identifier)
    config.isDiscretionary = false
    config.sessionSendsLaunchEvents = true
    config.waitsForConnectivity = true
    config.timeoutIntervalForRequest = 120
    config.timeoutIntervalForResource = 6 * 60 * 60
    return URLSession(configuration: config, delegate: self, delegateQueue: .main)
  }()

  func reconnect() { _ = session }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "begin" {
      beginExecutionTime()
      result(nil)
      return
    }
    if call.method == "end" { endExecutionTime(); result(nil); return }
    guard call.method == "downloadFile" || call.method == "waitForJob",
          let args = call.arguments as? [String: String],
          let source = args["url"], let url = URL(string: source),
          ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
          url.host != nil else {
      result(FlutterError(code: "invalid_transfer", message: "Invalid download request.", details: nil))
      return
    }
    if call.method == "downloadFile" {
      guard let path = args["path"],
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
            URL(fileURLWithPath: path).standardizedFileURL.path.hasPrefix(documents.path + "/") else {
        result(FlutterError(code: "invalid_destination", message: "Invalid download destination.", details: nil))
        return
      }
    }
    let id = UUID().uuidString
    results[id] = result
    var metadata = args
    metadata["id"] = id
    metadata["kind"] = call.method == "waitForJob" ? "job" : "file"
    metadata["attempt"] = "0"
    metadata["deadline"] = String(Date().addingTimeInterval(6 * 60 * 60).timeIntervalSince1970)
    enqueue(metadata)
  }

  private func enqueue(_ metadata: [String: String], delay: TimeInterval = 0) {
    if let deadline = Double(metadata["deadline"] ?? ""), Date().timeIntervalSince1970 > deadline {
      finish(metadata, error: FlutterError(code: "download_timeout", message: "The download timed out.", details: nil))
      return
    }
    guard let source = metadata["url"], let url = URL(string: source),
          let data = try? JSONSerialization.data(withJSONObject: metadata),
          let description = String(data: data, encoding: .utf8) else { return }
    let task = session.downloadTask(with: url)
    task.taskDescription = description
    if delay > 0 { task.earliestBeginDate = Date().addingTimeInterval(delay) }
    task.resume()
  }

  private func metadata(_ task: URLSessionTask) -> [String: String]? {
    guard let data = task.taskDescription?.data(using: .utf8) else { return nil }
    return (try? JSONSerialization.jsonObject(with: data)) as? [String: String]
  }

  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                  didFinishDownloadingTo location: URL) {
    guard let info = metadata(downloadTask) else { return }
    let status = (downloadTask.response as? HTTPURLResponse)?.statusCode ?? 0
    guard (200...299).contains(status) else {
      if status == 408 || status == 429 || status >= 500 {
        retry(info, message: "Connection interrupted.")
      } else {
        finish(info, error: FlutterError(code: "http_error", message: "API returned \(status)", details: nil))
      }
      return
    }
    do {
      if info["kind"] == "job" {
        let data = try Data(contentsOf: location)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
          throw NSError(domain: "ApexLoad", code: 1)
        }
        let state = (json["status"] as? String ?? "").lowercased()
        if state == "completed" || state == "failed" || json["success"] as? Bool == false {
          finish(info, value: json)
        } else {
          var next = info
          next["attempt"] = "0"
          enqueue(next, delay: 0.75)
        }
      } else {
        guard let path = info["path"] else { throw NSError(domain: "ApexLoad", code: 2) }
        let destination = URL(fileURLWithPath: path)
        // Move before this delegate returns: URLSession deletes its temporary file.
        if FileManager.default.fileExists(atPath: path) { try FileManager.default.removeItem(at: destination) }
        try FileManager.default.moveItem(at: location, to: destination)
        finish(info, value: nil)
      }
    } catch {
      finish(info, error: FlutterError(code: "save_failed", message: error.localizedDescription, details: nil))
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let error = error as NSError?, let info = metadata(task) else { return }
    let transient = error.domain == NSURLErrorDomain && [
      NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet,
      NSURLErrorCannotConnectToHost, NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed
    ].contains(error.code)
    if transient { retry(info, message: error.localizedDescription) }
    else { finish(info, error: FlutterError(code: "transfer_failed", message: error.localizedDescription, details: nil)) }
  }

  private func retry(_ info: [String: String], message: String) {
    let attempt = Int(info["attempt"] ?? "0") ?? 0
    if attempt >= 5 {
      finish(info, error: FlutterError(code: "connection_interrupted", message: message, details: nil))
      return
    }
    var next = info
    next["attempt"] = String(attempt + 1)
    enqueue(next, delay: min(pow(2.0, Double(attempt + 1)), 30))
  }

  private func finish(_ info: [String: String], value: Any? = nil, error: FlutterError? = nil) {
    guard let id = info["id"], let result = results.removeValue(forKey: id) else { return }
    // A background session can wake us after the initial allowance expired.
    // Keep time for Dart to schedule the next transfer or persist the library.
    beginExecutionTime()
    if let error = error { result(error) } else { result(value) }
  }

  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    let completion = completionHandler
    completionHandler = nil
    completion?()
  }

  private func beginExecutionTime() {
    guard executionTime == .invalid else { return }
    executionTime = UIApplication.shared.beginBackgroundTask(withName: "ApexLoad download") {
      self.endExecutionTime()
    }
  }

  private func endExecutionTime() {
    guard executionTime != .invalid else { return }
    UIApplication.shared.endBackgroundTask(executionTime)
    executionTime = .invalid
  }
}
