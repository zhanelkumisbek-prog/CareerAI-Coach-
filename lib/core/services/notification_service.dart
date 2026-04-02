import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      'careerai_main',
      'CareerAI Coach',
      channelDescription: 'Карьерные напоминания и еженедельные рекомендации',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> showWelcomeReminder(String name) async {
    await _plugin.show(
      1,
      'Добро пожаловать в CareerAI Coach',
      '$name, ваш персональный план развития готов.',
      _details,
    );
  }

  Future<void> scheduleWeeklyReminder() async {
    await _plugin.periodicallyShow(
      2,
      'Проверка прогресса за неделю',
      'Откройте CareerAI Coach и просмотрите задачи на эту неделю.',
      RepeatInterval.weekly,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> scheduleIncompleteTaskReminder() async {
    await _plugin.periodicallyShow(
      3,
      'Напоминание о незавершенных задачах',
      'У вас еще остались карьерные задачи. Сделайте хотя бы один небольшой шаг сегодня.',
      RepeatInterval.daily,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> showRoadmapUpdated() async {
    await _plugin.show(
      4,
      'План обновлен',
      'Ваш следующий карьерный план готов. Проверьте приоритеты.',
      _details,
    );
  }

  Future<void> cancelAllRecurring() async {
    await _plugin.cancel(2);
    await _plugin.cancel(3);
  }
}
