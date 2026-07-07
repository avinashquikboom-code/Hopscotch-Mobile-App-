import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class DevLogger {
  static Future<void> log(String message) async {
    if (!kDebugMode) return;

    // Print to console
    debugPrint(message);

    // Write to dev.log file
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/dev.log');
      final timestamp = DateTime.now().toIso8601String();
      await file.writeAsString('[$timestamp] $message\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('Failed to write to dev.log: $e');
    }
  }

  static Future<void> logError(String error, {String? context}) async {
    final message = context != null ? '[$context] ERROR: $error' : 'ERROR: $error';
    await log(message);
  }

  static Future<void> logInfo(String info) async {
    await log('INFO: $info');
  }

  static Future<String?> readLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/dev.log');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      debugPrint('Failed to read dev.log: $e');
    }
    return null;
  }

  static Future<void> clearLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/dev.log');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Failed to clear dev.log: $e');
    }
  }
}
