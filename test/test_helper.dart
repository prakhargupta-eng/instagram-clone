import 'dart:io';
import 'package:hive/hive.dart';

Future<void> setupTestHive() async {
  await Hive.close();
  final tempDir = Directory.systemTemp.createTempSync();
  Hive.init(tempDir.path);
}
