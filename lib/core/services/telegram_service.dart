import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_app/core/database/database_helper.dart';

class TelegramService {
  final String botToken;

  TelegramService({required this.botToken});

  /// Oddiy xabar yuborish (HTML formatda)
  Future<bool> sendMessage(String chatId, String text) async {
    final url = Uri.parse('https://api.telegram.org/bot$botToken/sendMessage');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'text': text,
          'parse_mode': 'HTML',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Guruhdagi barcha o'quvchilar ro'yxati bilan umumiy xabar yuborish
  Future<void> sendGroupAnnouncement(
    int groupId,
    String chatId,
    String message,
  ) async {
    final students = await DatabaseHelper.instance.getStudentsByGroup(groupId);

    String announcement = "<b>DIQQAT:</b>\n$message\n\n";
    if (students.isNotEmpty) {
      announcement += "<b>O'quvchilar ro'yxati:</b>\n";
      for (var student in students) {
        announcement += "• ${student.name}\n";
      }
    }

    await sendMessage(chatId, announcement);
  }
}
