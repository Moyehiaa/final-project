import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SoundAlertStyle {
  final String title;
  final String body;
  final String emoji;
  final Color color;
  final Int64List vibrationPattern;
  final Importance importance;
  final Priority priority;
  final bool fullScreen;

  const SoundAlertStyle({
    required this.title,
    required this.body,
    required this.emoji,
    required this.color,
    required this.vibrationPattern,
    required this.importance,
    required this.priority,
    required this.fullScreen,
  });
}

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);
  }

  static Future<void> showSoundAlert({
    required String label,
    required double confidence,
  }) async {
    final style = _styleForLabel(label);
    final percent = (confidence * 100).toStringAsFixed(0);

    final android = AndroidNotificationDetails(
      _channelIdForLabel(label),
      _channelNameForLabel(label),
      channelDescription: 'Visual alerts for detected important sounds',
      importance: style.importance,
      priority: style.priority,
      color: style.color,
      enableVibration: true,
      vibrationPattern: style.vibrationPattern,
      fullScreenIntent: style.fullScreen,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        '${style.body}\nConfidence: $percent%',
        contentTitle: '${style.emoji} ${style.title}',
        summaryText: 'Sound2Sign Alert',
      ),
    );

    final details = NotificationDetails(android: android);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '${style.emoji} ${style.title}',
      '${style.body} • $percent%',
      details,
    );
  }

  static SoundAlertStyle _styleForLabel(String label) {
    switch (label) {
      case 'alarm':
        return SoundAlertStyle(
          title: 'ALARM',
          body: 'Danger alert. Check now.',
          emoji: '🚨',
          color: const Color(0xFFD32F2F),
          vibrationPattern: Int64List.fromList([0, 700, 250, 700, 250, 700]),
          importance: Importance.max,
          priority: Priority.max,
          fullScreen: true,
        );

      case 'siren':
        return SoundAlertStyle(
          title: 'SIREN',
          body: 'Emergency sound nearby.',
          emoji: '🚑',
          color: const Color(0xFFC62828),
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
          importance: Importance.max,
          priority: Priority.max,
          fullScreen: true,
        );

      case 'baby_cry':
        return SoundAlertStyle(
          title: 'BABY CRY',
          body: 'Baby may need attention.',
          emoji: '👶',
          color: const Color(0xFF1976D2),
          vibrationPattern: Int64List.fromList([0, 400, 200, 400, 200, 400]),
          importance: Importance.max,
          priority: Priority.max,
          fullScreen: true,
        );

      case 'glass_breaking':
        return SoundAlertStyle(
          title: 'GLASS BREAKING',
          body: 'Possible danger. Check area.',
          emoji: '🪟',
          color: const Color(0xFFB71C1C),
          vibrationPattern: Int64List.fromList([0, 900, 200, 900]),
          importance: Importance.max,
          priority: Priority.max,
          fullScreen: true,
        );

      case 'knock':
        return SoundAlertStyle(
          title: 'KNOCK',
          body: 'Someone may be at the door.',
          emoji: '✊',
          color: const Color(0xFF795548),
          vibrationPattern: Int64List.fromList([0, 180, 120, 180, 120, 180]),
          importance: Importance.high,
          priority: Priority.high,
          fullScreen: false,
        );

      case 'bell':
        return SoundAlertStyle(
          title: 'BELL',
          body: 'Bell sound detected.',
          emoji: '🔔',
          color: const Color(0xFFF9A825),
          vibrationPattern: Int64List.fromList([0, 300, 150, 300]),
          importance: Importance.high,
          priority: Priority.high,
          fullScreen: false,
        );

      case 'phone_ring':
        return SoundAlertStyle(
          title: 'PHONE RING',
          body: 'Your phone may be ringing.',
          emoji: '📱',
          color: const Color(0xFF2E7D32),
          vibrationPattern: Int64List.fromList([0, 800, 300, 800]),
          importance: Importance.high,
          priority: Priority.high,
          fullScreen: false,
        );

      case 'dog':
        return SoundAlertStyle(
          title: 'DOG',
          body: 'Dog sound detected.',
          emoji: '🐶',
          color: const Color(0xFFEF6C00),
          vibrationPattern: Int64List.fromList([0, 250, 150, 250]),
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          fullScreen: false,
        );

      case 'speech':
        return SoundAlertStyle(
          title: 'SPEECH',
          body: 'Someone may be speaking.',
          emoji: '🗣️',
          color: const Color(0xFF616161),
          vibrationPattern: Int64List.fromList([0, 200]),
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          fullScreen: false,
        );

      default:
        return SoundAlertStyle(
          title: 'SOUND',
          body: 'Important sound detected.',
          emoji: '⚠️',
          color: const Color(0xFF455A64),
          vibrationPattern: Int64List.fromList([0, 300, 150, 300]),
          importance: Importance.high,
          priority: Priority.high,
          fullScreen: false,
        );
    }
  }

  static String _channelIdForLabel(String label) {
    switch (label) {
      case 'alarm':
      case 'siren':
      case 'baby_cry':
      case 'glass_breaking':
        return 'critical_sound_alerts';
      default:
        return 'sound_alerts';
    }
  }

  static String _channelNameForLabel(String label) {
    switch (label) {
      case 'alarm':
      case 'siren':
      case 'baby_cry':
      case 'glass_breaking':
        return 'Critical Sound Alerts';
      default:
        return 'Sound Alerts';
    }
  }
}
