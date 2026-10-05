import UIKit
import UniformTypeIdentifiers

/// Receives links using only extension-safe APIs. iOS does not allow a Share
/// extension to force-launch its containing app; the app consumes this inbox
/// when the user next opens it.
final class ShareViewController: UIViewController {
  private let message = UILabel()
  private let spinner = UIActivityIndicatorView(style: .large)
  private var started = false
  private var analysis: URLSessionDataTask?
  private var arabic: Bool { Locale.preferredLanguages.first?.hasPrefix("ar") == true }
  private func text(_ en: String, _ ar: String) -> String { arabic ? ar : en }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    let title = UILabel()
    title.text = "ApexLoad"
    title.font = .boldSystemFont(ofSize: 26)
    title.textAlignment = .center
    message.numberOfLines = 0
    message.textAlignment = .center
    message.text = text("Detecting video link…", "جارٍ اكتشاف رابط الفيديو…")
    let done = UIButton(type: .system)
    done.setTitle(text("Done", "تم"), for: .normal)
    done.addTarget(self, action: #selector(close), for: .touchUpInside)
    let stack = UIStackView(arrangedSubviews: [title, spinner, message, done])
    stack.axis = .vertical
    stack.spacing = 22
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
      stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    ])
    spinner.startAnimating()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard !started else { return }
    started = true
    let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
    let providers = items.flatMap { $0.attachments ?? [] }
    read(providers, index: 0)
  }

  private func read(_ providers: [NSItemProvider], index: Int) {
    guard index < providers.count else {
      show(text("No video link was found. Share the video's link to ApexLoad.", "لم يتم العثور على رابط فيديو. شارك رابط الفيديو مع ApexLoad."))
      return
    }
    let provider = providers[index]
    let types = [UTType.url.identifier, UTType.plainText.identifier, UTType.text.identifier]
    guard let type = types.first(where: { provider.hasItemConformingToTypeIdentifier($0) }) else {
      read(providers, index: index + 1); return
    }
    provider.loadItem(forTypeIdentifier: type, options: nil) { item, _ in
      let value = (item as? URL)?.absoluteString ?? (item as? String) ?? ""
      DispatchQueue.main.async {
        if let url = self.extractURL(value) { self.receive(url) }
        else { self.read(providers, index: index + 1) }
      }
    }
  }

  private func extractURL(_ value: String) -> URL? {
    guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return nil }
    return detector.matches(in: value, range: NSRange(value.startIndex..., in: value))
      .compactMap { $0.url }.first { ["http", "https"].contains($0.scheme?.lowercased() ?? "") && $0.host != nil }
  }

  private func receive(_ url: URL) {
    let host = url.host?.lowercased() ?? ""
    let blocked = ["youtube.com", "youtu.be", "youtube-nocookie.com", "googlevideo.com", "ytimg.com"]
    if blocked.contains(where: { host == $0 || host.hasSuffix("." + $0) }) {
      show(text("This source is not supported.", "هذا المصدر غير مدعوم.")); return
    }
    guard let defaults = UserDefaults(suiteName: "group.com.yahyazlab.apexload"),
          FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.yahyazlab.apexload") != nil else {
      show(text("Sharing is unavailable. Please open ApexLoad and paste the link.", "المشاركة غير متاحة. افتح ApexLoad والصق الرابط.")); return
    }
    defaults.set(url.absoluteString, forKey: "pendingSharedText")
    guard defaults.bool(forKey: "responsibleUseAcceptedV1"),
          let endpoint = defaults.string(forKey: "analyzeUrl"), let api = URL(string: endpoint), api.scheme == "https" else {
      show(text("Link saved. Open ApexLoad to complete setup and analyze it.", "تم حفظ الرابط. افتح ApexLoad لإكمال الإعداد وتحليله.")); return
    }
    message.text = text("Analyzing your video…", "جارٍ تحليل الفيديو…")
    var request = URLRequest(url: api)
    request.httpMethod = "POST"
    request.timeoutInterval = 20
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONSerialization.data(withJSONObject: ["url": url.absoluteString])
    analysis = URLSession.shared.dataTask(with: request) { data, response, _ in
      let json = data.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any]
      let success = (response as? HTTPURLResponse)?.statusCode == 200 && json?["success"] as? Bool == true
      DispatchQueue.main.async {
        if success {
          self.show(self.text("Video detected. Open ApexLoad to choose a format and download it.", "تم اكتشاف الفيديو. افتح ApexLoad لاختيار الصيغة وتنزيله."))
        } else {
          self.show(self.text("Link saved. Open ApexLoad to retry analysis.", "تم حفظ الرابط. افتح ApexLoad لإعادة محاولة التحليل."))
        }
      }
    }
    analysis?.resume()
  }

  private func show(_ value: String) { spinner.stopAnimating(); message.text = value }
  @objc private func close() {
    analysis?.cancel()
    extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
  }
}
