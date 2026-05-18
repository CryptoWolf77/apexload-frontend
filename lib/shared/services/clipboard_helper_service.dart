import 'package:flutter/services.dart';

class ClipboardHelperService {
  Future<String> readText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text ?? '';
  }
}
