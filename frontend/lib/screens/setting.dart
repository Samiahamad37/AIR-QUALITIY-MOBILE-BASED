import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '/main.dart' show AppState;
import '/services/auth_service.dart';
import '/screens/login_screen.dart';
import '/screens/register_screen.dart';
import '/screens/report_analysis_screen.dart';
import 'package:air_quality_monitor/L10n/app_localizations.dart';  

// ─── Theme-aware colors — work in both light & dark ────────────────────────────

Color _bg(BuildContext c)       => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c)     => Theme.of(c).brightness == Brightness.dark
    ? const Color(0xFF1E293B) : Colors.white;
Color _border(BuildContext c)   => Theme.of(c).brightness == Brightness.dark
    ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
Color _div(BuildContext c)      => Theme.of(c).brightness == Brightness.dark
    ? const Color(0xFF2D3748) : const Color(0xFFF3F4F6);
Color _textMain(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? Colors.white : const Color(0xFF1C1C1E);
Color _textSub(BuildContext c)  => Theme.of(c).brightness == Brightness.dark
    ? const Color(0xFF94A3B8) : const Color(0xFF8E8E93);

const _accent = Color(0xFFFF2D55);

// ─── Local-only settings (region/station/etc — not theme/language) ────────────

class _Local extends ChangeNotifier {
  bool notifications      = true;
  // bool biometric          = true;
  bool cloudSync          = false;
  String region           = 'TZ';
  String station          = 'Kinondoni';
  String aqiThreshold     = '150 — Sensitive';
  String refreshInterval  = '5 min';

  void toggle(String k, bool v) {
    if (k == 'notifications') notifications = v;
    // if (k == 'biometric')     biometric     = v;
    if (k == 'cloudSync')     cloudSync     = v;
    notifyListeners();
  }

  void set(String k, String v) {
    if (k == 'region')          region          = v;
    if (k == 'station')         station         = v;
    if (k == 'aqiThreshold')    aqiThreshold    = v;
    if (k == 'refreshInterval') refreshInterval = v;
    notifyListeners();
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _local = _Local();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: AnimatedBuilder(
        animation: _local,
        builder: (ctx, _) {
          //  Read directly from the SAME global model main.dart uses
          final global = AppState.of(ctx);
          final auth = context.watch<AuthService>();

          return Scaffold(
            backgroundColor: _bg(ctx),
            body: CustomScrollView(slivers: [

              SliverAppBar(
                backgroundColor: _bg(ctx),
                elevation: 0, pinned: true, toolbarHeight: 60,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(ctx).settingsTitle, style: TextStyle(fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _textMain(ctx), letterSpacing: -0.5)),
                    _iconBtn(ctx, CupertinoIcons.search, () {}),
                  ],
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      _GuestCard(
                        ctx: ctx,
                        auth: auth,
                        onTap: () => auth.isLoggedIn
                            ? _openReports(ctx)
                            : _openLogin(ctx),
                      ),
                      const SizedBox(height: 28),

                      // ── Preferences ──────────────────────────────
                      _label(ctx, AppLocalizations.of(ctx).settingsPreferences),
                      const SizedBox(height: 8),
                      _Group(ctx: ctx, children: [
                        _Toggle(ctx: ctx,
                          icon: CupertinoIcons.moon_fill,
                          iconBg: const Color(0xFF636366),
                          label: AppLocalizations.of(ctx).settingsDarkMode,
                          sub: AppLocalizations.of(ctx).settingsDarkModeSub,
                          value: global.darkMode,
                          onChanged: (v) {
                            global.setDarkMode(v);
                            _snack(ctx, v ? AppLocalizations.of(ctx).settingsDarkModeOn : AppLocalizations.of(ctx).settingsDarkModeOff);
                          },
                        ),
                        _Toggle(ctx: ctx,
                          icon: CupertinoIcons.bell_fill,
                          iconBg: _accent,
                          label: AppLocalizations.of(ctx).settingsNotifications,
                          sub: AppLocalizations.of(ctx).settingsNotifSub,
                          value: _local.notifications,
                          onChanged: (v) {
                            _local.toggle('notifications', v);
                            _snack(ctx, v ? AppLocalizations.of(ctx).settingsNotifOn : AppLocalizations.of(ctx).settingsNotifOff);
                          },
                        ),
                        // _Toggle(ctx: ctx,
                        //   icon: CupertinoIcons.person_crop_circle_fill,
                        //   iconBg: const Color(0xFF8E8E93),
                        //   label: AppLocalizations.of(ctx)!.settingsBiometric,
                        //   sub: AppLocalizations.of(ctx)!.settingsBiometricSub,
                        //   value: _local.biometric,
                        //   onChanged: (v) {
                        //     _local.toggle('biometric', v);
                        //     _snack(ctx, v ? AppLocalizations.of(ctx)!.settingsBiometricOn : AppLocalizations.of(ctx)!.settingsBiometricOff);
                        //   },
                        // ),
                        _Toggle(ctx: ctx,
                          icon: CupertinoIcons.arrow_2_circlepath,
                          iconBg: const Color(0xFF30B0C7),
                          label: AppLocalizations.of(ctx).settingsCloudSync,
                          sub: AppLocalizations.of(ctx).settingsCloudSyncSub,
                          value: _local.cloudSync,
                          onChanged: (v) {
                            _local.toggle('cloudSync', v);
                            _snack(ctx, v ? AppLocalizations.of(ctx).settingsCloudSyncOn : AppLocalizations.of(ctx).settingsCloudSyncOff);
                          },
                        ),
                      ]),

                      const SizedBox(height: 28),

                      // ── General ──────────────────────────────────
                      _label(ctx, AppLocalizations.of(ctx).settingsGeneral),
                      const SizedBox(height: 8),
                      _Group(ctx: ctx, children: [
                        _Nav(ctx: ctx,
                          icon: CupertinoIcons.globe,
                          iconBg: const Color(0xFF007AFF),
                          label: AppLocalizations.of(ctx).settingsLanguage,
                          value: global.language,
                          onTap: () => _pick(ctx,
                            title: AppLocalizations.of(ctx).settingsLanguage,
                            options: const ['English', 'Kiswahili'],
                            current: global.language,
                            onSelect: (v) {
                              global.setLanguage(v);
                              _snack(ctx, AppLocalizations.of(ctx).settingsLanguageSelected(v));
                            },
                          ),
                        ),
                        _Nav(ctx: ctx,
                          icon: CupertinoIcons.location_fill,
                          iconBg: const Color(0xFFFF9500),
                          label: AppLocalizations.of(ctx).settingsRegion,
                          value: _local.region,
                          onTap: () => _pick(ctx,
                            title: AppLocalizations.of(ctx).settingsRegion,
                            options: const ['TZ', 'KE', 'UG', 'RW', 'ZM'],
                            current: _local.region,
                            onSelect: (v) {
                              _local.set('region', v);
                              _snack(ctx, AppLocalizations.of(ctx).settingsRegionSelected(v));
                            },
                          ),
                        ),
                        _Nav(ctx: ctx,
                          icon: CupertinoIcons.info_circle_fill,
                          iconBg: const Color(0xFF007AFF),
                          label: AppLocalizations.of(ctx).settingsAbout,
                          value: 'v1.0.0',
                          onTap: () => _aboutDialog(ctx),
                        ),
                      ]),

                      const SizedBox(height: 28),

                      // ── Air Quality ───────────────────────────────
                      _label(ctx, AppLocalizations.of(ctx).settingsAirQuality),
                      const SizedBox(height: 8),
                      _Group(ctx: ctx, children: [
                        _Nav(ctx: ctx,
                          icon: CupertinoIcons.location_circle_fill,
                          iconBg: const Color(0xFF30B0C7),
                          label: AppLocalizations.of(ctx).settingsDefaultStation,
                          value: _local.station,
                          onTap: () => _pick(ctx,
                            title: AppLocalizations.of(ctx).settingsDefaultStation,
                            options: const ['Kinondoni', 'Ilala', 'Temeke',
                                            'Ubungo', 'Kigamboni'],
                            current: _local.station,
                            onSelect: (v) {
                              _local.set('station', v);
                              _snack(ctx, AppLocalizations.of(ctx).settingsStationSelected(v));
                            },
                          ),
                        ),
                        _Nav(ctx: ctx,
                          icon: CupertinoIcons.bell_circle_fill,
                          iconBg: _accent,
                          label: AppLocalizations.of(ctx).settingsAqiThreshold,
                          value: _local.aqiThreshold.split(' ').first,
                          onTap: () => _pick(ctx,
                            title: AppLocalizations.of(ctx).settingsAqiThreshold,
                            options: const ['50 — Good', '100 — Moderate',
                                            '150 — Sensitive', '200 — Unhealthy',
                                            '300 — Very Unhealthy'],
                            current: _local.aqiThreshold,
                            onSelect: (v) {
                              _local.set('aqiThreshold', v);
                              _snack(ctx, AppLocalizations.of(ctx).settingsThresholdSelected(v));
                            },
                          ),
                        ),
                        _Nav(ctx: ctx,
                          icon: CupertinoIcons.refresh_circled_solid,
                          iconBg: const Color(0xFF34C759),
                          label: AppLocalizations.of(ctx).settingsRefreshInterval,
                          value: _local.refreshInterval,
                          onTap: () => _pick(ctx,
                            title: AppLocalizations.of(ctx).settingsRefreshInterval,
                            options: const ['1 min', '2 min', '5 min',
                                            '10 min', '30 min'],
                            current: _local.refreshInterval,
                            onSelect: (v) {
                              _local.set('refreshInterval', v);
                              _snack(ctx, AppLocalizations.of(ctx).settingsRefreshSelected(v));
                            },
                          ),
                        ),
                      ]),

                      const SizedBox(height: 28),

                      // ── Account ────────────────────────────────────
                      _label(ctx, AppLocalizations.of(ctx).settingsAccount),
                      const SizedBox(height: 8),
                      _Group(ctx: ctx, children: [
                        _Nav(ctx: ctx,
                          icon: CupertinoIcons.chart_bar_alt_fill,
                          iconBg: const Color(0xFF34C759),
                          label: 'Reports & Analysis',
                          value: auth.isLoggedIn ? null : 'Sign in',
                          onTap: () => _openReports(ctx)),
                        _Nav(ctx: ctx,
                          icon: CupertinoIcons.shield_fill,
                          iconBg: const Color(0xFF5856D6),
                          label: AppLocalizations.of(ctx).settingsPrivacy, onTap: () {}),
                        _Nav(ctx: ctx,
                          icon: CupertinoIcons.question_circle_fill,
                          iconBg: const Color(0xFF32ADE6),
                          label: AppLocalizations.of(ctx).settingsHelp, onTap: () {}),
                        _Nav(ctx: ctx,
                          icon: CupertinoIcons.star_fill,
                          iconBg: const Color(0xFFFF9500),
                          label: AppLocalizations.of(ctx).settingsRate,
                          onTap: () => _snack(ctx, AppLocalizations.of(ctx).settingsRateThanks)),
                        if (auth.isLoggedIn)
                          _Nav(ctx: ctx,
                            icon: CupertinoIcons.square_arrow_right,
                            iconBg: _accent,
                            label: 'Sign Out',
                            onTap: () => _logout(ctx, auth)),
                      ]),

                      if (!auth.isLoggedIn) ...[
                        const SizedBox(height: 28),
                        _Cta(ctx: ctx, onTap: () => _openRegister(ctx)),
                      ],
                      const SizedBox(height: 32),

                      Center(child: Text(AppLocalizations.of(ctx).settingsFooter,
                          style: TextStyle(fontSize: 12, color: _textSub(ctx)))),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _iconBtn(BuildContext c, IconData icon, VoidCallback fn) =>
      GestureDetector(onTap: fn, child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: _card(c), shape: BoxShape.circle,
            border: Border.all(color: _border(c))),
        child: Icon(icon, size: 16, color: _textSub(c)),
      ));

  Widget _label(BuildContext c, String text) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(text.toUpperCase(), style: TextStyle(fontSize: 11,
        fontWeight: FontWeight.w600, color: _textSub(c), letterSpacing: 0.8)),
  );

  void _pick(BuildContext c, {
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet(
      context: c,
      backgroundColor: _card(c),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36, height: 4,
              decoration: BoxDecoration(color: _border(c),
                  borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Align(alignment: Alignment.centerLeft,
                child: Text(title, style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w700, color: _textMain(c))))),
          Divider(color: _div(c), height: 1),
          ...options.map((o) => ListTile(
            onTap: () { onSelect(o); Navigator.pop(c); },
            title: Text(o, style: TextStyle(fontSize: 15,
                color: o == current ? _accent : _textMain(c),
                fontWeight: o == current ? FontWeight.w600 : FontWeight.w400)),
            trailing: o == current
                ? const Icon(Icons.check_rounded, color: _accent, size: 18)
                : null,
          )),
          const SizedBox(height: 8),
        ],
      )),
    );
  }

  void _aboutDialog(BuildContext c) {
    final l10n = AppLocalizations.of(c);
    showDialog(context: c, builder: (_) => AlertDialog(
      backgroundColor: _card(c),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('AirWatch',
          style: TextStyle(color: _textMain(c), fontWeight: FontWeight.w700)),
      content: Text(
          l10n.settingsAboutContent,
          style: TextStyle(color: _textSub(c), fontSize: 13, height: 1.5)),
      actions: [TextButton(onPressed: () => Navigator.pop(c),
          child: Text(l10n.settingsClose, style: TextStyle(color: _accent)))],
    ));
  }

  void _openLogin(BuildContext c) => Navigator.of(c).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()));

  void _openRegister(BuildContext c) => Navigator.of(c).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()));

  void _openReports(BuildContext c) {
    if (c.read<AuthService>().isLoggedIn) {
      Navigator.of(c).push(
          MaterialPageRoute(builder: (_) => const ReportAnalysisScreen()));
    } else {
      _snack(c, 'Please sign in to access Reports & Analysis');
      _openLogin(c);
    }
  }

  Future<void> _logout(BuildContext c, AuthService auth) async {
    await auth.logout();
    if (!mounted) return;
    _snack(c, 'Signed out');
  }

  void _snack(BuildContext c, String msg) {
    ScaffoldMessenger.of(c).clearSnackBars();
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _GuestCard extends StatelessWidget {
  final BuildContext ctx;
  final AuthService auth;
  final VoidCallback onTap;
  const _GuestCard({required this.ctx, required this.auth, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final loggedIn = auth.isLoggedIn;
    final name = loggedIn
        ? (auth.username ?? 'Account')
        : AppLocalizations.of(ctx).settingsGuestName;
    final sub = loggedIn
        ? (auth.email ?? 'Signed in')
        : AppLocalizations.of(ctx).settingsGuestSub;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _card(ctx),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border(ctx))),
        child: Row(children: [
          Container(width: 52, height: 52,
              decoration: BoxDecoration(
                  color: loggedIn ? _accent : _bg(ctx),
                  shape: BoxShape.circle,
                  border: Border.all(color: _border(ctx))),
              child: Icon(CupertinoIcons.person_fill, size: 26,
                  color: loggedIn ? Colors.white : _textSub(ctx))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w600, color: _textMain(ctx))),
                const SizedBox(height: 2),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: _textSub(ctx))),
              ])),
          if (!loggedIn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: _accent,
                  borderRadius: BorderRadius.circular(99)),
              child: Text(AppLocalizations.of(ctx).settingsSignIn,
                  style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600, color: Colors.white)),
            )
          else
            Icon(CupertinoIcons.chevron_right, size: 16, color: _textSub(ctx)),
        ]),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  final BuildContext ctx;
  const _Group({required this.children, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(Padding(padding: const EdgeInsets.only(left: 58),
            child: Divider(height: 0.5, thickness: 0.5, color: _div(ctx))));
      }
    }
    return Container(
      decoration: BoxDecoration(color: _card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border(context), width: 0.5)),
      child: Column(children: rows),
    );
  }
}

class _Toggle extends StatelessWidget {
  final BuildContext ctx;
  final IconData icon;
  final Color iconBg;
  final String label, sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({required this.ctx, required this.icon, required this.iconBg,
      required this.label, required this.sub,
      required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(children: [
      _iconBox(icon, iconBg),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 15, color: _textMain(ctx))),
            Text(sub,   style: TextStyle(fontSize: 11, color: _textSub(ctx))),
          ])),
      CupertinoSwitch(value: value, onChanged: onChanged, activeColor: _accent),
    ]),
  );
}

class _Nav extends StatelessWidget {
  final BuildContext ctx;
  final IconData icon;
  final Color iconBg;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _Nav({required this.ctx, required this.icon, required this.iconBg,
      required this.label, required this.onTap, this.value});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        _iconBox(icon, iconBg),
        const SizedBox(width: 14),
        Expanded(child: Text(label,
            style: TextStyle(fontSize: 15, color: _textMain(ctx)))),
        if (value != null)
          Text(value!, style: TextStyle(fontSize: 13, color: _textSub(ctx))),
        const SizedBox(width: 6),
        Icon(CupertinoIcons.chevron_right, size: 14, color: _textSub(ctx)),
      ]),
    ),
  );
}

class _Cta extends StatelessWidget {
  final BuildContext ctx;
  final VoidCallback onTap;
  const _Cta({required this.ctx, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [_accent, Color(0xFFFF6B81)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(ctx).settingsCreateAccount, style: TextStyle(fontSize: 15,
                fontWeight: FontWeight.w700, color: Colors.white)),
            SizedBox(height: 4),
            Text(AppLocalizations.of(ctx).settingsCtaSub,
                style: TextStyle(fontSize: 12, color: Colors.white70,
                    height: 1.4)),
          ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(99)),
        child: Text(AppLocalizations.of(ctx).settingsGetStarted, style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w700, color: _accent)),
      ),
    ]),
    ),
  );
}

Widget _iconBox(IconData icon, Color bg) => Container(
  width: 32, height: 32,
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
  child: Icon(icon, size: 17, color: Colors.white),
);