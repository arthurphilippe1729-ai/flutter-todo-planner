import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:dynamic_color/dynamic_color.dart';

import 'app_router.dart';
import 'data/database/hive_database.dart';
import 'services/notification_service.dart';
import 'services/timezone_service.dart';
import 'theme/app_theme.dart';
import 'theme/color_schemes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration du système
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configuration des couleurs de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialisation des services
  await _initializeServices();

  runApp(
    const ProviderScope(
      child: TodoApp(),
    ),
  );
}

Future<void> _initializeServices() async {
  try {
    // Initialisation Hive
    await Hive.initFlutter();
    await HiveDatabase.initialize();

    // Initialisation des fuseaux horaires
    tz.initializeTimeZones();
    await TimezoneService.initialize();

    // Initialisation des notifications
    await NotificationService.initialize();

    debugPrint('✅ Tous les services initialisés avec succès');
  } catch (e, stackTrace) {
    debugPrint('❌ Erreur lors de l\'initialisation des services: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

class TodoApp extends ConsumerWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // Utilise Dynamic Color (Material You) si disponible
          lightScheme = lightDynamic.harmonized();
          darkScheme = darkDynamic.harmonized();
        } else {
          // Utilise la palette de repli
          lightScheme = lightColorScheme;
          darkScheme = darkColorScheme;
        }

        return MaterialApp.router(
          title: 'Todo & Planning',
          debugShowCheckedModeBanner: false,
          
          // Configuration du routeur
          routerConfig: router,
          
          // Thèmes Material 3
          theme: AppTheme.light(lightScheme),
          darkTheme: AppTheme.dark(darkScheme),
          themeMode: ThemeMode.system,
          
          // Localisation française
          locale: const Locale('fr', 'FR'),
          supportedLocales: const [
            Locale('fr', 'FR'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          
          // Configuration pour Galaxy S23
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                // Force le format 24h
                alwaysUse24HourFormat: true,
                // Gestion des safe areas pour le poinçon caméra
                textScaler: MediaQuery.of(context).textScaler.clamp(
                  minScaleFactor: 0.8,
                  maxScaleFactor: 1.3,
                ),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}
