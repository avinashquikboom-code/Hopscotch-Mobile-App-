import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/firebase/firebase_config.dart';
import 'package:hopscotch/routes/app_pages.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/theme/theme_provider.dart';
import 'package:hopscotch/providers/language_provider.dart';
import 'package:hopscotch/l10n/app_localizations.dart';
import 'package:hopscotch/core/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseConfig.initialize();
  
  // Resolve startup state before running the app
  final container = ProviderContainer();
  final startupState = await container.read(startupStateProvider.future);
  
  // Initialize AppPages router with initial startup state
  AppPages.init(startupState);
  
  // Set transparent status bar globally
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'FCISeller',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppPages.router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: language.locale,
    );
  }
}
