import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> saveReportFile({
  required String filename,
  required List<int> bytes,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final path = '${directory.path}/$filename';
  await File(path).writeAsBytes(bytes);
  return filename;
}
