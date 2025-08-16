import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Service de gestion des fuseaux horaires
class TimezoneService {
  static bool _initialized = false;
  static late tz.Location _localLocation;

  /// Initialise le service des fuseaux horaires
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialiser les données des fuseaux horaires
      tz_data.initializeTimeZones();
      
      // Définir le fuseau horaire local (France)
      _localLocation = tz.getLocation('Europe/Paris');
      
      _initialized = true;
      debugPrint('✅ Service des fuseaux horaires initialisé (${_localLocation.name})');
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de l\'initialisation des fuseaux horaires: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Fallback vers UTC si erreur
      _localLocation = tz.UTC;
      _initialized = true;
    }
  }

  /// Obtient le fuseau horaire local
  static tz.Location get localLocation {
    if (!_initialized) {
      throw Exception('TimezoneService non initialisé');
    }
    return _localLocation;
  }

  /// Convertit une DateTime en TZDateTime local
  static tz.TZDateTime toLocal(DateTime dateTime) {
    if (!_initialized) {
      throw Exception('TimezoneService non initialisé');
    }
    
    if (dateTime.isUtc) {
      return tz.TZDateTime.from(dateTime, _localLocation);
    } else {
      // Assume que c'est déjà en heure locale
      return tz.TZDateTime(_localLocation, dateTime.year, dateTime.month, 
          dateTime.day, dateTime.hour, dateTime.minute, dateTime.second, 
          dateTime.millisecond, dateTime.microsecond);
    }
  }

  /// Convertit une DateTime en UTC
  static DateTime toUtc(DateTime dateTime) {
    if (dateTime.isUtc) {
      return dateTime;
    }
    
    final tzDateTime = toLocal(dateTime);
    return tzDateTime.toUtc();
  }

  /// Crée une TZDateTime pour une date et heure spécifiques
  static tz.TZDateTime createLocalDateTime({
    required int year,
    required int month,
    required int day,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  }) {
    if (!_initialized) {
      throw Exception('TimezoneService non initialisé');
    }
    
    return tz.TZDateTime(_localLocation, year, month, day, 
        hour, minute, second, millisecond, microsecond);
  }

  /// Obtient l'heure actuelle en fuseau local
  static tz.TZDateTime now() {
    if (!_initialized) {
      throw Exception('TimezoneService non initialisé');
    }
    
    return tz.TZDateTime.now(_localLocation);
  }

  /// Obtient le début de la journée pour une date
  static tz.TZDateTime startOfDay(DateTime date) {
    return createLocalDateTime(
      year: date.year,
      month: date.month,
      day: date.day,
    );
  }

  /// Obtient la fin de la journée pour une date
  static tz.TZDateTime endOfDay(DateTime date) {
    return createLocalDateTime(
      year: date.year,
      month: date.month,
      day: date.day,
      hour: 23,
      minute: 59,
      second: 59,
      millisecond: 999,
    );
  }

  /// Obtient le début de la semaine (lundi) pour une date
  static tz.TZDateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    final monday = date.subtract(Duration(days: daysFromMonday));
    return startOfDay(monday);
  }

  /// Obtient la fin de la semaine (dimanche) pour une date
  static tz.TZDateTime endOfWeek(DateTime date) {
    final daysToSunday = 7 - date.weekday;
    final sunday = date.add(Duration(days: daysToSunday));
    return endOfDay(sunday);
  }

  /// Obtient le début du mois pour une date
  static tz.TZDateTime startOfMonth(DateTime date) {
    return createLocalDateTime(
      year: date.year,
      month: date.month,
      day: 1,
    );
  }

  /// Obtient la fin du mois pour une date
  static tz.TZDateTime endOfMonth(DateTime date) {
    final nextMonth = date.month == 12 
        ? DateTime(date.year + 1, 1, 1)
        : DateTime(date.year, date.month + 1, 1);
    final lastDayOfMonth = nextMonth.subtract(const Duration(days: 1));
    return endOfDay(lastDayOfMonth);
  }

  /// Vérifie si une date est aujourd'hui
  static bool isToday(DateTime date) {
    final today = now();
    final targetDate = toLocal(date);
    
    return today.year == targetDate.year &&
           today.month == targetDate.month &&
           today.day == targetDate.day;
  }

  /// Vérifie si une date est demain
  static bool isTomorrow(DateTime date) {
    final tomorrow = now().add(const Duration(days: 1));
    final targetDate = toLocal(date);
    
    return tomorrow.year == targetDate.year &&
           tomorrow.month == targetDate.month &&
           tomorrow.day == targetDate.day;
  }

  /// Vérifie si une date est hier
  static bool isYesterday(DateTime date) {
    final yesterday = now().subtract(const Duration(days: 1));
    final targetDate = toLocal(date);
    
    return yesterday.year == targetDate.year &&
           yesterday.month == targetDate.month &&
           yesterday.day == targetDate.day;
  }

  /// Vérifie si une date est dans la semaine courante
  static bool isThisWeek(DateTime date) {
    final now = TimezoneService.now();
    final startWeek = startOfWeek(now);
    final endWeek = endOfWeek(now);
    final targetDate = toLocal(date);
    
    return targetDate.isAfter(startWeek.subtract(const Duration(microseconds: 1))) &&
           targetDate.isBefore(endWeek.add(const Duration(microseconds: 1)));
  }

  /// Vérifie si une date est dans le mois courant
  static bool isThisMonth(DateTime date) {
    final now = TimezoneService.now();
    final targetDate = toLocal(date);
    
    return now.year == targetDate.year && now.month == targetDate.month;
  }

  /// Formate une date selon le contexte (aujourd'hui, demain, etc.)
  static String formatRelativeDate(DateTime date) {
    if (isToday(date)) {
      return 'Aujourd\'hui';
    } else if (isTomorrow(date)) {
      return 'Demain';
    } else if (isYesterday(date)) {
      return 'Hier';
    } else {
      final targetDate = toLocal(date);
      final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      final months = [
        'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
        'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
      ];
      
      if (isThisWeek(date)) {
        return weekdays[targetDate.weekday - 1];
      } else if (isThisMonth(date)) {
        return '${targetDate.day} ${months[targetDate.month - 1]}';
      } else {
        return '${targetDate.day} ${months[targetDate.month - 1]} ${targetDate.year}';
      }
    }
  }

  /// Formate une heure en format 24h français
  static String formatTime(DateTime dateTime) {
    final localTime = toLocal(dateTime);
    return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  }

  /// Formate une date et heure complète
  static String formatDateTime(DateTime dateTime) {
    return '${formatRelativeDate(dateTime)} ${formatTime(dateTime)}';
  }

  /// Calcule la différence en jours entre deux dates
  static int daysBetween(DateTime start, DateTime end) {
    final startDate = startOfDay(start);
    final endDate = startOfDay(end);
    return endDate.difference(startDate).inDays;
  }

  /// Ajoute des jours ouvrables à une date (exclut samedi et dimanche)
  static tz.TZDateTime addBusinessDays(DateTime date, int days) {
    var result = toLocal(date);
    var remainingDays = days;
    
    while (remainingDays > 0) {
      result = result.add(const Duration(days: 1));
      // Lundi = 1, Dimanche = 7
      if (result.weekday <= 5) { // Lundi à Vendredi
        remainingDays--;
      }
    }
    
    return result;
  }

  /// Obtient le prochain jour ouvrable
  static tz.TZDateTime nextBusinessDay(DateTime date) {
    var result = toLocal(date).add(const Duration(days: 1));
    
    // Si c'est samedi (6) ou dimanche (7), aller au lundi suivant
    while (result.weekday > 5) {
      result = result.add(const Duration(days: 1));
    }
    
    return result;
  }

  /// Vérifie si une date est un jour ouvrable
  static bool isBusinessDay(DateTime date) {
    final localDate = toLocal(date);
    return localDate.weekday <= 5; // Lundi à Vendredi
  }

  /// Obtient les informations sur le changement d'heure (DST)
  static DstInfo getDstInfo(DateTime date) {
    final localDate = toLocal(date);
    final utcOffset = localDate.timeZoneOffset;
    
    // En France: UTC+1 en hiver, UTC+2 en été
    final isDst = utcOffset.inHours == 2;
    
    return DstInfo(
      isDst: isDst,
      offset: utcOffset,
      timezoneName: isDst ? 'CEST' : 'CET',
    );
  }

  /// Obtient les dates de changement d'heure pour une année
  static DstTransitions getDstTransitions(int year) {
    // Règles européennes: dernier dimanche de mars et d'octobre
    
    // Passage à l'heure d'été (dernier dimanche de mars)
    var springTransition = DateTime(year, 3, 31);
    while (springTransition.weekday != 7) { // Dimanche = 7
      springTransition = springTransition.subtract(const Duration(days: 1));
    }
    springTransition = DateTime(year, springTransition.month, springTransition.day, 2, 0);
    
    // Passage à l'heure d'hiver (dernier dimanche d'octobre)
    var fallTransition = DateTime(year, 10, 31);
    while (fallTransition.weekday != 7) { // Dimanche = 7
      fallTransition = fallTransition.subtract(const Duration(days: 1));
    }
    fallTransition = DateTime(year, fallTransition.month, fallTransition.day, 3, 0);
    
    return DstTransitions(
      springForward: toLocal(springTransition),
      fallBack: toLocal(fallTransition),
    );
  }

  /// Ajuste une heure pour éviter les problèmes de DST
  static tz.TZDateTime adjustForDst(DateTime dateTime) {
    final localDateTime = toLocal(dateTime);
    final transitions = getDstTransitions(localDateTime.year);
    
    // Si c'est pendant la transition de printemps (2h -> 3h)
    if (localDateTime.isAfter(transitions.springForward) &&
        localDateTime.isBefore(transitions.springForward.add(const Duration(hours: 1)))) {
      // Avancer d'une heure
      return localDateTime.add(const Duration(hours: 1));
    }
    
    return localDateTime;
  }

  /// Obtient les statistiques du service
  static TimezoneStats getStats() {
    return TimezoneStats(
      initialized: _initialized,
      locationName: _initialized ? _localLocation.name : 'Non initialisé',
      currentOffset: _initialized ? now().timeZoneOffset : Duration.zero,
      isDst: _initialized ? getDstInfo(DateTime.now()).isDst : false,
    );
  }
}

/// Informations sur l'heure d'été (DST)
class DstInfo {
  final bool isDst;
  final Duration offset;
  final String timezoneName;

  const DstInfo({
    required this.isDst,
    required this.offset,
    required this.timezoneName,
  });
}

/// Transitions d'heure d'été/hiver
class DstTransitions {
  final tz.TZDateTime springForward;
  final tz.TZDateTime fallBack;

  const DstTransitions({
    required this.springForward,
    required this.fallBack,
  });
}

/// Statistiques du service de fuseaux horaires
class TimezoneStats {
  final bool initialized;
  final String locationName;
  final Duration currentOffset;
  final bool isDst;

  const TimezoneStats({
    required this.initialized,
    required this.locationName,
    required this.currentOffset,
    required this.isDst,
  });
}
