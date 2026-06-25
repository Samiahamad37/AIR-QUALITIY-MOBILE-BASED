
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'L10n/app_localizations.dart';
import 'app_theme.dart';
import 'screens.dart';
import 'health_screen.dart';
import 'map_screen.dart';
import 'screen2.dart';
import 'setting.dart';
import 'shared_data_service.dart';
// import 'login_screen.dart'; -
// import 'register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  runApp(const AirQualityApp());
}

// ─── Global app-wide settings — the ONLY source of truth ──────────────────────

class AppSettingsModel extends ChangeNotifier {
  bool _darkMode = true;
  String _language = 'English';

  bool get darkMode => _darkMode;
  String get language => _language;

  void setDarkMode(bool value) {
    if (_darkMode == value) return;
    _darkMode = value;
    notifyListeners();          // triggers MaterialApp rebuild below
  }

  void setLanguage(String value) {
    if (_language == value) return;
    _language = value;
    notifyListeners();
  }
}

// Single global instance — every screen reads/writes through this
final appSettings = AppSettingsModel();

// Lets any widget call AppState.of(context) to read/write settings
class AppState extends InheritedNotifier<AppSettingsModel> {
  const AppState({super.key, required super.notifier, required super.child});

  static AppSettingsModel of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppState>()!.notifier!;
}

// ─── Root widget ──────────────────────────────────────────────────────────────

class AirQualityApp extends StatelessWidget {
  const AirQualityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppState(
      notifier: appSettings,
      child: ChangeNotifierProvider<SharedDataService>.value(
        value: sharedDataService,
        child: AnimatedBuilder(
        // ✅ This rebuild is what makes theme/language actually apply
        animation: appSettings,
        builder: (context, _) {
          return MaterialApp(
            title: 'AirQuality',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: appSettings.darkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            locale: _localeFor(appSettings.language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const MainShell(),
          );
        },
      ),
      ),
    );
  }

  Locale _localeFor(String language) {
    switch (language) {
      case 'Kiswahili': return const Locale('sw');
      default:          return const Locale('en');
    }
  }
}

// ─── Shell with bottom nav ────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ForecastScreen(),
    HealthScreen(),
    MapScreen(),
    SettingsScreen(),
  ];

  static const _icons = [
    Icons.home_rounded,
    Icons.show_chart_rounded,
    Icons.favorite_border_rounded,
    Icons.map_outlined,
    Icons.settings_rounded,
  ];

  static const _labelsEn = ['Home', 'Forecast', 'Health', 'Map', 'Settings'];
  static const _labelsSw = ['Nyumbani', 'Utabiri', 'Afya', 'Ramani', 'Mipangilio'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = const Color(0xFF4ADE80);
    final inactive = isDark ? const Color(0xFF475569) : const Color(0xFF9CA3AF);
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);

    // Reads the SAME global state Settings writes to
    final labels = AppState.of(context).language == 'Kiswahili'
        ? _labelsSw : _labelsEn;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: bgColor,
            border: Border(top: BorderSide(color: border, width: 0.5))),
        child: SafeArea(top: false, child: SizedBox(
          height: 60,
          child: Row(children: List.generate(5, (i) {
            final isActive = i == _currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? active.withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Icon(_icons[i], size: 22,
                          color: isActive ? active : inactive),
                    ),
                    const SizedBox(height: 2),
                    Text(labels[i], style: TextStyle(
                      fontSize: 10,
                      color: isActive ? active : inactive,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    )),
                  ],
                ),
              ),
            );
          })),
        )),
      ),
    );
  }
}