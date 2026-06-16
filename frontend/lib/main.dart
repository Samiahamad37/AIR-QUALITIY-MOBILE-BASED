// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter/foundation.dart';
// import 'package:provider/provider.dart';
// import 'app_theme.dart';
// import 'screens.dart';
// import 'health_screen.dart';
// import 'map_screen.dart';
// import 'screen2.dart';
// import 'setting.dart';
// import 'shared_data_service.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Only set orientation on non-web platforms
//   if (!kIsWeb) {
//     await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//   }

//   runApp(const AirQualityApp());
// }

// class AirQualityApp extends StatelessWidget {
//   const AirQualityApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider<SharedDataService>(
//       create: (_) => SharedDataService()..loadData(),
//       child: MaterialApp(
//         title: 'AirQuality',
//         debugShowCheckedModeBanner: false,
//         theme: AppTheme.dark,
//         darkTheme: AppTheme.dark,
//         themeMode: ThemeMode.dark,
//         home: const MainShell(),
//       ),
//     );
//   }
// }

// class MainShell extends StatefulWidget {
//   const MainShell({super.key});

//   @override
//   State<MainShell> createState() => _MainShellState();
// }

// class _MainShellState extends State<MainShell> {
//   int _currentIndex = 0;

//   // Screens will be added as we build each one
//   final List<Widget> _screens = [
//     const HomeScreen(),
//     const ForecastScreen(),
//     const HealthScreen(),
//     const MapScreen(),
//     const SettingsScreen()
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.bgDark,
//       body: IndexedStack(
//         index: _currentIndex,
//         children: _screens,
//       ),
//       bottomNavigationBar: _buildNavBar(),
//     );
//   }

//   Widget _buildNavBar() {
//     const items = [
//       _NavItem(icon: Icons.home_rounded, label: 'Home'),
//       _NavItem(icon: Icons.show_chart_rounded, label: 'Forecast'),
//       _NavItem(icon: Icons.favorite_border_rounded, label: 'Health'),
//       _NavItem(icon: Icons.map_outlined, label: 'Map'),
//       _NavItem(icon: Icons.settings, label: 'Settings'),
//     ];

//     return Container(
//       decoration: BoxDecoration(
//         color: AppColors.bgCard,
//         border:
//             Border(top: BorderSide(color: AppColors.border.withOpacity(0.5))),
//       ),
//       child: SafeArea(
//         top: false,
//         child: SizedBox(
//           height: 60,
//           child: Row(
//             children: items.asMap().entries.map((e) {
//               final isActive = e.key == _currentIndex;
//               final item = e.value;
//               return Expanded(
//                 child: GestureDetector(
//                   onTap: () => setState(() => _currentIndex = e.key),
//                   behavior: HitTestBehavior.opaque,
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 200),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         AnimatedContainer(
//                           duration: const Duration(milliseconds: 200),
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 16, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: isActive
//                                 ? const Color(0xFF4ADE80).withOpacity(0.12)
//                                 : Colors.transparent,
//                             borderRadius: BorderRadius.circular(99),
//                           ),
//                           child: Icon(
//                             item.icon,
//                             size: 22,
//                             color: isActive
//                                 ? const Color(0xFF4ADE80)
//                                 : AppColors.textMuted,
//                           ),
//                         ),
//                         const SizedBox(height: 2),
//                         Text(
//                           item.label,
//                           style: TextStyle(
//                             fontSize: 10,
//                             color: isActive
//                                 ? const Color(0xFF4ADE80)
//                                 : AppColors.textMuted,
//                             fontWeight:
//                                 isActive ? FontWeight.w600 : FontWeight.w400,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _NavItem {
//   final IconData icon;
//   final String label;
//   const _NavItem({required this.icon, required this.label});
// }


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'screens.dart';
import 'health_screen.dart';
import 'map_screen.dart';
import 'screen2.dart';
import 'setting.dart';
import 'shared_data_service.dart';

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
            theme: AppTheme.light,           // must exist in app_theme.dart
            darkTheme: AppTheme.dark,
            themeMode: appSettings.darkMode
                ? ThemeMode.dark
                : ThemeMode.light,           // ✅ switches here
            locale: _localeFor(appSettings.language),
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