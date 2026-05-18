import 'package:url_launcher/url_launcher.dart';

Future<String?> saveOrOpenFile({
  required String url,
  required String fileName,
}) async {
  final opened = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!opened) {
    throw StateError('Could not open downloaded file.');
  }
  return null;
}
