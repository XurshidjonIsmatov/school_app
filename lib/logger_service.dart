import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LoggerService {
  static Future<File> _getLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/error_logs.txt');
  }

  /// Xatolikni vaqt bilan birga faylga yozish
  static Future<void> logError(dynamic error, [StackTrace? stackTrace]) async {
    try {
      final file = await _getLogFile();
      final timestamp = DateTime.now().toIso8601String();
      final logEntry =
          "[$timestamp] ERROR: $error\nSTACKTRACE: $stackTrace\n"
          "--------------------------------------------------\n";
      await file.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      // Log yozishda xatolik bo'lsa, konsolga chiqarish
      debugPrint('Logging error: $e');
    }
  }

  /// Barcha loglarni o'qish
  static Future<String> readLogs() async {
    try {
      final file = await _getLogFile();
      if (await file.exists()) return await file.readAsString();
    } catch (_) {}
    return "Hozircha xatoliklar logi bo'sh.";
  }

  /// Log faylini tozalash
  static Future<void> clearLogs() async {
    final file = await _getLogFile();
    if (await file.exists()) await file.delete();
  }
}
