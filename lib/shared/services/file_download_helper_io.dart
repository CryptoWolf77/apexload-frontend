import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> saveOrOpenFile({
  required String url,
  required String fileName,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final downloadsDir = Directory('${directory.path}/apexload_downloads');
  if (!downloadsDir.existsSync()) {
    downloadsDir.createSync(recursive: true);
  }
  final path = '${downloadsDir.path}/$fileName';
  await Dio().download(url, path);
  return path;
}
