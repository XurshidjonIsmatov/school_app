import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'database_helper.dart';
import 'secure_storage_service.dart';
import 'telegram_service.dart';
import 'logger_service.dart';

class AppBackgroundService {
  static const String notificationChannelId = 'my_foreground';
  static const int notificationId = 888;

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'Background Service',
      description: 'Xabarlarni orqa fonda yuborish xizmati',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'School App ishlamoqda',
        initialNotificationContent: 'Xabarlar navbati nazorat qilinmoqda...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async => true;

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Orqa fondagi xatoliklarni faylga yozish
    FlutterError.onError = (details) {
      LoggerService.logError("Background: ${details.exception}", details.stack);
    };

    final storage = SecureStorageService();
    bool isProcessing = false;

    Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (isProcessing) return;

      // Internet aloqasini tekshirish
      final List<ConnectivityResult> connectivityResult = await Connectivity()
          .checkConnectivity();
      final bool hasInternet = connectivityResult.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );

      if (!hasInternet) return;

      isProcessing = true;

      final db = DatabaseHelper.instance;

      try {
        final pendingMessages = await db.getPendingMessages();

        if (pendingMessages.isNotEmpty) {
          final token = await storage.getBotToken();
          if (token == null) return;

          final tgService = TelegramService(botToken: token);
          int sentCount = 0;

          for (var msgData in pendingMessages) {
            final id = msgData['id'] as int;
            final chatId = msgData['chat_id'] as String;
            final text = msgData['message'] as String;

            bool success = await tgService.sendMessage(chatId, text);
            if (success) {
              await db.deletePendingMessage(id);
              sentCount++;

              final logData = {
                'chat_id': chatId,
                'message': text,
                'status': 'Muvaffaqiyatli',
                'date': DateTime.now().toIso8601String(),
              };

              await db.insertMessageLog(logData);
              await db.cleanOldMessageLogs();

              // Har bir yuborilgan xabar haqida UI isolate'ga batafsil ma'lumot yuborish
              service.invoke('message_sent_details', {
                ...logData,
                'time': logData['date'].toString().substring(11, 16),
              });
            } else {
              _showLocalNotification(
                "Xabar yuborilmadi",
                "Internet aloqasini yoki Telegram bot sozlamalarini tekshiring.",
              );
              // Xabarni yuborishda xatolik bo'lsa (limit yoki internet), batchni to'xtatamiz
              break;
            }

            // Telegram rate limitga tushmaslik uchun kutamiz
            await Future.delayed(const Duration(milliseconds: 1200));
          }

          if (sentCount > 0) {
            _showLocalNotification(
              "Navbat yakunlandi",
              "$sentCount ta xabar muvaffaqiyatli yuborildi.",
            );

            // UI isolate'ga xabar berish (update_count event'ini yuborish)
            service.invoke('update_count');
          }
        }
      } catch (e) {
        _showLocalNotification(
          "Tizim xatosi",
          "Orqa fon xizmati ishlashida xatolik yuz berdi.",
        );
      } finally {
        isProcessing = false;
      }
    });
  }

  static void _showLocalNotification(String title, String body) {
    final FlutterLocalNotificationsPlugin notificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'msg_status',
          'Xabar holati',
          importance: Importance.high,
          priority: Priority.high,
        );
    notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }
}
