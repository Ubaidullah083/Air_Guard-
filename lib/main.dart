import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';

// ── Theme mode notifier ───────────────────────────────
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _save();
  }

  void setMode(ThemeMode mode) {
    state = mode;
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', state == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme');
    if (saved == 'dark') state = ThemeMode.dark;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

// ── Entry point ───────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase init
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: AirGuardApp()));
}

class AirGuardApp extends ConsumerWidget {
  const AirGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load saved theme on first build
    ref.read(themeModeProvider.notifier).load();

    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Air Guard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
