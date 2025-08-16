import 'package:flutter/foundation.dart';
import 'package:rrule/rrule.dart';
import '../models/task.dart';
import 'timezone_service.dart';

/// Service de gestion de la récurrence des tâches
class RecurrenceService {
  /// Génère les occurrences d'une tâche récurrente
  static List<Task> generateOccurrences(
    Task task, {
    required DateTime startDate,
    required DateTime endDate,
    int? maxOccurrences,
  }) {
    if (!task.isRecurrent || task.recurrenceRule == null) {
      return [task];
    }

    try {
      final occurrences = <Task>[];
      final rrule = RecurrenceRule.fromString(task.recurrenceRule!);
      
      // Calculer les dates d'occurrence
      final occurrenceDates = rrule.between(
        startDate,
        endDate,
        inc: true,
      );

      // Limiter le nombre d'occurrences si spécifié
      final limitedDates = maxOccurrences != null && occurrenceDates.length > maxOccurrences
          ? occurrenceDates.take(maxOccurrences).toList()
          : occurrenceDates;

      // Créer une tâche pour chaque occurrence
      for (final occurrenceDate in limitedDates) {
        // Vérifier si l'occurrence est avant la date de fin de récurrence
        if (task.recurrenceEndsAt != null && occurrenceDate.isAfter(task.recurrenceEndsAt!)) {
          break;
        }

        // Calculer la durée de la tâche originale
        final duration = task.endAt.difference(task.startAt);
        
        // Créer la nouvelle occurrence
        final occurrence = task.copyWith(
          id: '${task.id}_${occurrenceDate.millisecondsSinceEpoch}',
          startAt: occurrenceDate,
          endAt: occurrenceDate.add(duration),
        );

        occurrences.add(occurrence);
      }

      debugPrint('✅ ${occurrences.length} occurrences générées pour "${task.title}"');
      return occurrences;
    } catch (e) {
      debugPrint('❌ Erreur lors de la génération des occurrences pour "${task.title}": $e');
      return [task];
    }
  }

  /// Crée une règle RRULE pour une récurrence quotidienne
  static String createDailyRule({
    int interval = 1,
    DateTime? until,
    int? count,
  }) {
    var rule = 'FREQ=DAILY';
    
    if (interval > 1) {
      rule += ';INTERVAL=$interval';
    }
    
    if (until != null) {
      final utcUntil = TimezoneService.toUtc(until);
      rule += ';UNTIL=${_formatDateTimeForRRule(utcUntil)}';
    }
    
    if (count != null) {
      rule += ';COUNT=$count';
    }
    
    return rule;
  }

  /// Crée une règle RRULE pour une récurrence hebdomadaire
  static String createWeeklyRule({
    int interval = 1,
    List<int>? byWeekDay, // 1=Lundi, 7=Dimanche
    DateTime? until,
    int? count,
  }) {
    var rule = 'FREQ=WEEKLY';
    
    if (interval > 1) {
      rule += ';INTERVAL=$interval';
    }
    
    if (byWeekDay != null && byWeekDay.isNotEmpty) {
      final days = byWeekDay.map((day) => _weekDayToRRule(day)).join(',');
      rule += ';BYDAY=$days';
    }
    
    if (until != null) {
      final utcUntil = TimezoneService.toUtc(until);
      rule += ';UNTIL=${_formatDateTimeForRRule(utcUntil)}';
    }
    
    if (count != null) {
      rule += ';COUNT=$count';
    }
    
    return rule;
  }

  /// Crée une règle RRULE pour une récurrence mensuelle
  static String createMonthlyRule({
    int interval = 1,
    int? byMonthDay,
    int? bySetPos, // Pour "le 2ème lundi du mois" par exemple
    List<int>? byWeekDay,
    DateTime? until,
    int? count,
  }) {
    var rule = 'FREQ=MONTHLY';
    
    if (interval > 1) {
      rule += ';INTERVAL=$interval';
    }
    
    if (byMonthDay != null) {
      rule += ';BYMONTHDAY=$byMonthDay';
    }
    
    if (bySetPos != null && byWeekDay != null && byWeekDay.isNotEmpty) {
      final days = byWeekDay.map((day) => _weekDayToRRule(day)).join(',');
      rule += ';BYDAY=$days;BYSETPOS=$bySetPos';
    }
    
    if (until != null) {
      final utcUntil = TimezoneService.toUtc(until);
      rule += ';UNTIL=${_formatDateTimeForRRule(utcUntil)}';
    }
    
    if (count != null) {
      rule += ';COUNT=$count';
    }
    
    return rule;
  }

  /// Crée une règle RRULE pour une récurrence annuelle
  static String createYearlyRule({
    int interval = 1,
    int? byMonth,
    int? byMonthDay,
    DateTime? until,
    int? count,
  }) {
    var rule = 'FREQ=YEARLY';
    
    if (interval > 1) {
      rule += ';INTERVAL=$interval';
    }
    
    if (byMonth != null) {
      rule += ';BYMONTH=$byMonth';
    }
    
    if (byMonthDay != null) {
      rule += ';BYMONTHDAY=$byMonthDay';
    }
    
    if (until != null) {
      final utcUntil = TimezoneService.toUtc(until);
      rule += ';UNTIL=${_formatDateTimeForRRule(utcUntil)}';
    }
    
    if (count != null) {
      rule += ';COUNT=$count';
    }
    
    return rule;
  }

  /// Crée une règle pour les jours ouvrables (lundi à vendredi)
  static String createWeekdaysRule({
    DateTime? until,
    int? count,
  }) {
    return createWeeklyRule(
      byWeekDay: [1, 2, 3, 4, 5], // Lundi à Vendredi
      until: until,
      count: count,
    );
  }

  /// Crée une règle pour les week-ends (samedi et dimanche)
  static String createWeekendsRule({
    DateTime? until,
    int? count,
  }) {
    return createWeeklyRule(
      byWeekDay: [6, 7], // Samedi et Dimanche
      until: until,
      count: count,
    );
  }

  /// Parse une règle RRULE et retourne des informations lisibles
  static RecurrenceInfo parseRecurrenceRule(String rruleString) {
    try {
      final rrule = RecurrenceRule.fromString(rruleString);
      
      return RecurrenceInfo(
        frequency: _getFrequencyLabel(rrule.frequency),
        interval: rrule.interval ?? 1,
        byWeekDay: rrule.byWeekDays?.map((wd) => wd.day).toList(),
        byMonthDay: rrule.byMonthDays,
        byMonth: rrule.byMonths,
        until: rrule.until,
        count: rrule.count,
        description: _generateDescription(rrule),
      );
    } catch (e) {
      debugPrint('❌ Erreur lors du parsing de la règle RRULE: $e');
      return RecurrenceInfo.invalid();
    }
  }

  /// Vérifie si une règle RRULE est valide
  static bool isValidRecurrenceRule(String rruleString) {
    try {
      RecurrenceRule.fromString(rruleString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtient la prochaine occurrence d'une tâche récurrente
  static DateTime? getNextOccurrence(Task task, {DateTime? after}) {
    if (!task.isRecurrent || task.recurrenceRule == null) {
      return null;
    }

    try {
      final rrule = RecurrenceRule.fromString(task.recurrenceRule!);
      final afterDate = after ?? DateTime.now();
      
      // Vérifier si la récurrence a une date de fin
      if (task.recurrenceEndsAt != null && afterDate.isAfter(task.recurrenceEndsAt!)) {
        return null;
      }
      
      final nextOccurrences = rrule.between(
        afterDate,
        afterDate.add(const Duration(days: 365)), // Chercher dans l'année suivante
        inc: false,
      );
      
      return nextOccurrences.isNotEmpty ? nextOccurrences.first : null;
    } catch (e) {
      debugPrint('❌ Erreur lors du calcul de la prochaine occurrence: $e');
      return null;
    }
  }

  /// Obtient toutes les occurrences d'une tâche pour une période donnée
  static List<DateTime> getOccurrencesInRange(
    Task task,
    DateTime startDate,
    DateTime endDate,
  ) {
    if (!task.isRecurrent || task.recurrenceRule == null) {
      // Si la tâche n'est pas récurrente, vérifier si elle est dans la plage
      if (task.startAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
          task.startAt.isBefore(endDate.add(const Duration(days: 1)))) {
        return [task.startAt];
      }
      return [];
    }

    try {
      final rrule = RecurrenceRule.fromString(task.recurrenceRule!);
      return rrule.between(startDate, endDate, inc: true);
    } catch (e) {
      debugPrint('❌ Erreur lors du calcul des occurrences: $e');
      return [];
    }
  }

  /// Modifie une occurrence spécifique d'une tâche récurrente
  static Task modifyOccurrence(Task originalTask, DateTime occurrenceDate, Task modifiedTask) {
    // Pour une vraie implémentation, il faudrait gérer les exceptions RRULE
    // Ici, on retourne simplement la tâche modifiée avec un nouvel ID
    return modifiedTask.copyWith(
      id: '${originalTask.id}_exception_${occurrenceDate.millisecondsSinceEpoch}',
    );
  }

  /// Supprime une occurrence spécifique d'une tâche récurrente
  static String addExceptionToRule(String rruleString, DateTime exceptionDate) {
    // Ajouter une date d'exception à la règle RRULE
    final utcException = TimezoneService.toUtc(exceptionDate);
    final exceptionStr = _formatDateTimeForRRule(utcException);
    
    if (rruleString.contains('EXDATE=')) {
      // Ajouter à la liste existante
      return rruleString.replaceFirst('EXDATE=', 'EXDATE=$exceptionStr,');
    } else {
      // Créer une nouvelle liste d'exceptions
      return '$rruleString;EXDATE=$exceptionStr';
    }
  }

  /// Convertit un jour de la semaine (1-7) en format RRULE
  static String _weekDayToRRule(int weekDay) {
    const weekDays = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    return weekDays[weekDay - 1];
  }

  /// Formate une DateTime pour RRULE
  static String _formatDateTimeForRRule(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}'
           '${dateTime.month.toString().padLeft(2, '0')}'
           '${dateTime.day.toString().padLeft(2, '0')}'
           'T'
           '${dateTime.hour.toString().padLeft(2, '0')}'
           '${dateTime.minute.toString().padLeft(2, '0')}'
           '${dateTime.second.toString().padLeft(2, '0')}'
           'Z';
  }

  /// Obtient le libellé de fréquence
  static String _getFrequencyLabel(Frequency frequency) {
    switch (frequency) {
      case Frequency.daily:
        return 'Quotidien';
      case Frequency.weekly:
        return 'Hebdomadaire';
      case Frequency.monthly:
        return 'Mensuel';
      case Frequency.yearly:
        return 'Annuel';
      default:
        return 'Inconnu';
    }
  }

  /// Génère une description lisible de la règle de récurrence
  static String _generateDescription(RecurrenceRule rrule) {
    final interval = rrule.interval ?? 1;
    
    switch (rrule.frequency) {
      case Frequency.daily:
        if (interval == 1) {
          return 'Tous les jours';
        } else {
          return 'Tous les $interval jours';
        }
        
      case Frequency.weekly:
        if (rrule.byWeekDays != null && rrule.byWeekDays!.isNotEmpty) {
          final days = rrule.byWeekDays!.map((wd) => _getWeekDayName(wd.day)).join(', ');
          if (interval == 1) {
            return 'Chaque $days';
          } else {
            return 'Toutes les $interval semaines le $days';
          }
        } else {
          if (interval == 1) {
            return 'Chaque semaine';
          } else {
            return 'Toutes les $interval semaines';
          }
        }
        
      case Frequency.monthly:
        if (interval == 1) {
          return 'Chaque mois';
        } else {
          return 'Tous les $interval mois';
        }
        
      case Frequency.yearly:
        if (interval == 1) {
          return 'Chaque année';
        } else {
          return 'Tous les $interval ans';
        }
        
      default:
        return 'Récurrence personnalisée';
    }
  }

  /// Obtient le nom du jour de la semaine
  static String _getWeekDayName(int weekDay) {
    const weekDays = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    return weekDays[weekDay - 1];
  }

  /// Obtient des suggestions de récurrence courantes
  static List<RecurrenceSuggestion> getCommonRecurrences() {
    return [
      RecurrenceSuggestion(
        label: 'Tous les jours',
        description: 'Répéter quotidiennement',
        rrule: createDailyRule(),
      ),
      RecurrenceSuggestion(
        label: 'Jours ouvrables',
        description: 'Du lundi au vendredi',
        rrule: createWeekdaysRule(),
      ),
      RecurrenceSuggestion(
        label: 'Chaque semaine',
        description: 'Répéter chaque semaine',
        rrule: createWeeklyRule(),
      ),
      RecurrenceSuggestion(
        label: 'Chaque mois',
        description: 'Répéter chaque mois',
        rrule: createMonthlyRule(),
      ),
      RecurrenceSuggestion(
        label: 'Chaque année',
        description: 'Répéter chaque année',
        rrule: createYearlyRule(),
      ),
    ];
  }
}

/// Informations sur une règle de récurrence
class RecurrenceInfo {
  final String frequency;
  final int interval;
  final List<int>? byWeekDay;
  final List<int>? byMonthDay;
  final List<int>? byMonth;
  final DateTime? until;
  final int? count;
  final String description;
  final bool isValid;

  const RecurrenceInfo({
    required this.frequency,
    required this.interval,
    this.byWeekDay,
    this.byMonthDay,
    this.byMonth,
    this.until,
    this.count,
    required this.description,
    this.isValid = true,
  });

  factory RecurrenceInfo.invalid() {
    return const RecurrenceInfo(
      frequency: 'Invalide',
      interval: 0,
      description: 'Règle de récurrence invalide',
      isValid: false,
    );
  }
}

/// Suggestion de récurrence prédéfinie
class RecurrenceSuggestion {
  final String label;
  final String description;
  final String rrule;

  const RecurrenceSuggestion({
    required this.label,
    required this.description,
    required this.rrule,
  });
}
