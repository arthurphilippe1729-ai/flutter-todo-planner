import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

/// Service de gestion des notifications locales
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Initialise le service de notifications
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Configuration Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configuration iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Configuration générale
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialisation
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Demander les permissions sur Android 13+
      if (Platform.isAndroid) {
        await _requestAndroidPermissions();
      }

      _initialized = true;
      debugPrint('✅ Service de notifications initialisé');
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de l\'initialisation des notifications: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Demande les permissions Android
  static Future<void> _requestAndroidPermissions() async {
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Permission pour les notifications (Android 13+)
        await androidPlugin.requestNotificationsPermission();
        
        // Permission pour les alarmes exactes
        await androidPlugin.requestExactAlarmsPermission();
        
        debugPrint('✅ Permissions Android demandées');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la demande de permissions Android: $e');
    }
  }

  /// Gère le tap sur une notification
  static void _onNotificationTapped(NotificationResponse response) {
    try {
      final payload = response.payload;
      debugPrint('📱 Notification tappée: $payload');
      
      if (payload != null) {
        // Ici on pourrait naviguer vers la tâche concernée
        // Par exemple: navigateToTask(payload);
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du traitement du tap sur notification: $e');
    }
  }

  /// Programme une notification pour une tâche
  static Future<void> scheduleTaskNotification(Task task) async {
    if (!_initialized) {
      debugPrint('⚠️ Service de notifications non initialisé');
      return;
    }

    try {
      // Annuler les notifications existantes pour cette tâche
      await cancelTaskNotifications(task.id);

      // Programmer les rappels
      for (int i = 0; i < task.reminders.length; i++) {
        final reminderMinutes = task.reminders[i];
        final notificationTime = task.startAt.subtract(Duration(minutes: reminderMinutes));
        
        // Ne programmer que les notifications futures
        if (notificationTime.isAfter(DateTime.now())) {
          await _scheduleNotification(
            id: _generateNotificationId(task.id, i),
            title: _getReminderTitle(reminderMinutes),
            body: task.title,
            scheduledDate: notificationTime,
            payload: task.id,
            task: task,
          );
        }
      }

      debugPrint('✅ Notifications programmées pour "${task.title}"');
    } catch (e) {
      debugPrint('❌ Erreur lors de la programmation des notifications pour "${task.title}": $e');
    }
  }

  /// Programme une notification
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    Task? task,
  }) async {
    try {
      // Détails Android
      final androidDetails = AndroidNotificationDetails(
        'task_reminders',
        'Rappels de tâches',
        channelDescription: 'Notifications pour les rappels de tâches',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        when: scheduledDate.millisecondsSinceEpoch,
        icon: '@mipmap/ic_launcher',
        color: task != null ? _getTaskColor(task) : null,
        enableVibration: true,
        playSound: true,
        actions: [
          const AndroidNotificationAction(
            'snooze_5',
            'Reporter 5 min',
            showsUserInterface: false,
          ),
          const AndroidNotificationAction(
            'mark_done',
            'Marquer terminé',
            showsUserInterface: false,
          ),
        ],
      );

      // Détails iOS
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      // Détails généraux
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Programmer la notification
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('📅 Notification programmée: $title à ${scheduledDate.toString()}');
    } catch (e) {
      debugPrint('❌ Erreur lors de la programmation de la notification: $e');
    }
  }

  /// Annule les notifications d'une tâche
  static Future<void> cancelTaskNotifications(String taskId) async {
    try {
      // Annuler toutes les notifications possibles pour cette tâche
      // (on assume max 10 rappels par tâche)
      for (int i = 0; i < 10; i++) {
        final notificationId = _generateNotificationId(taskId, i);
        await _notifications.cancel(notificationId);
      }
      
      debugPrint('✅ Notifications annulées pour la tâche $taskId');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'annulation des notifications: $e');
    }
  }

  /// Annule toutes les notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      debugPrint('✅ Toutes les notifications annulées');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'annulation de toutes les notifications: $e');
    }
  }

  /// Affiche une notification immédiate
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      debugPrint('⚠️ Service de notifications non initialisé');
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'instant_notifications',
        'Notifications instantanées',
        channelDescription: 'Notifications affichées immédiatement',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('📱 Notification immédiate affichée: $title');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'affichage de la notification: $e');
    }
  }

  /// Programme une notification de rappel avec snooze
  static Future<void> snoozeNotification(String taskId, int minutes) async {
    try {
      final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
      
      await _scheduleNotification(
        id: _generateSnoozeNotificationId(taskId),
        title: 'Rappel reporté',
        body: 'Tâche reportée de $minutes minutes',
        scheduledDate: snoozeTime,
        payload: taskId,
      );

      debugPrint('⏰ Notification reportée de $minutes minutes');
    } catch (e) {
      debugPrint('❌ Erreur lors du report de notification: $e');
    }
  }

  /// Obtient les notifications en attente
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des notifications en attente: $e');
      return [];
    }
  }

  /// Vérifie si les notifications sont autorisées
  static Future<bool> areNotificationsEnabled() async {
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await androidPlugin?.areNotificationsEnabled() ?? false;
      } else if (Platform.isIOS) {
        final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        return await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification des permissions: $e');
      return false;
    }
  }

  /// Génère un ID unique pour une notification
  static int _generateNotificationId(String taskId, int reminderIndex) {
    // Utilise un hash simple pour générer un ID unique
    final combined = '$taskId-$reminderIndex';
    return combined.hashCode.abs() % 2147483647; // Max int32
  }

  /// Génère un ID pour une notification de snooze
  static int _generateSnoozeNotificationId(String taskId) {
    final combined = '$taskId-snooze';
    return combined.hashCode.abs() % 2147483647;
  }

  /// Obtient le titre du rappel selon les minutes
  static String _getReminderTitle(int minutes) {
    if (minutes == 0) {
      return 'C\'est maintenant !';
    } else if (minutes < 60) {
      return 'Dans $minutes minutes';
    } else if (minutes == 60) {
      return 'Dans 1 heure';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return 'Dans $hours heure${hours > 1 ? 's' : ''}';
      } else {
        return 'Dans ${hours}h${remainingMinutes}min';
      }
    }
  }

  /// Obtient la couleur d'une tâche pour Android
  static Color? _getTaskColor(Task task) {
    try {
      // Convertit la couleur de priorité en Color Android
      final colorHex = task.priority.colorHex.replaceAll('#', '');
      final colorInt = int.parse('FF$colorHex', radix: 16);
      return Color(colorInt);
    } catch (e) {
      return null;
    }
  }

  /// Teste les notifications
  static Future<void> testNotification() async {
    await showNotification(
      title: 'Test de notification',
      body: 'Cette notification confirme que le système fonctionne correctement.',
    );
  }

  /// Obtient les statistiques des notifications
  static Future<NotificationStats> getNotificationStats() async {
    try {
      final pendingNotifications = await getPendingNotifications();
      final isEnabled = await areNotificationsEnabled();
      
      return NotificationStats(
        isEnabled: isEnabled,
        pendingCount: pendingNotifications.length,
        initialized: _initialized,
      );
    } catch (e) {
      debugPrint('❌ Erreur lors du calcul des statistiques de notifications: $e');
      return NotificationStats.empty();
    }
  }
}

/// Classe pour les statistiques des notifications
class NotificationStats {
  final bool isEnabled;
  final int pendingCount;
  final bool initialized;

  const NotificationStats({
    required this.isEnabled,
    required this.pendingCount,
    required this.initialized,
  });

  factory NotificationStats.empty() {
    return const NotificationStats(
      isEnabled: false,
      pendingCount: 0,
      initialized: false,
    );
  }
}

/// Classe pour représenter une couleur Android
class Color {
  final int value;
  
  const Color(this.value);
  
  @override
  String toString() => 'Color(0x${value.toRadixString(16).padLeft(8, '0')})';
}
