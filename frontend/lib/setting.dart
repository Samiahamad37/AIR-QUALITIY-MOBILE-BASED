import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────

const _bg       = Color(0xFF0F172A);
const _cardBg   = Color(0xFF1E293B);
const _border   = Color(0xFF334155);
const _divider  = Color(0xFF2D3748);
const _textMain = Color(0xFFFFFFFF);
const _textSub  = Color(0xFF94A3B8);
const _accent   = Color(0xFFFF2D55);

// ─── App Settings State ───────────────────────────────────────────────────────

class AppSettingsState extends ChangeNotifier {
  bool darkMode         = true;
  bool notifications    = true;
  bool biometric        = true;
  bool cloudSync        = false;
  String language       = 'English';
  String region         = 'TZ';
  String station        = 'Kinondoni';
  String aqiThreshold   = '150 — Sensitive';
  String refreshInterval= '5 min';

  void toggle(String key, bool value) {
    switch (key) {
      case 'darkMode':      darkMode      = value; break;
      case 'notifications': notifications = value; break;
      case 'biometric':     biometric     = value; break;
      case 'cloudSync':     cloudSync     = value; break;
    }
    notifyListeners();
  }

  void set(String key, String value) {
    switch (key) {
      case 'language':        language        = value; break;
      case 'region':          region          = value; break;
      case 'station':         station         = value; break;
      case 'aqiThreshold':    aqiThreshold    = value; break;
      case 'refreshInterval': refreshInterval = value; break;
    }
    notifyListeners();
  }
}

// ─── Settings Screen ──────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = AppSettingsState();
  static const _appVersion = 'v1.0.0';

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: AnimatedBuilder(
        animation: _settings,
        builder: (context, _) => Scaffold(
          backgroundColor: _bg,
          body: CustomScrollView(slivers: [

            // ── App Bar ──────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: _bg,
              elevation: 0,
              pinned: true,
              toolbarHeight: 60,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Settings',
                      style: TextStyle(fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _textMain, letterSpacing: -0.5)),
                  _iconBtn(CupertinoIcons.search, () {}),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Guest card ─────────────────────────────────
                    _GuestCard(),
                    const SizedBox(height: 28),

                    // ── Preferences ────────────────────────────────
                    _label('Preferences'),
                    const SizedBox(height: 8),
                    _Group(children: [
                      _ToggleRow(
                        icon: CupertinoIcons.moon_fill,
                        iconBg: const Color(0xFF636366),
                        label: 'Dark Mode',
                        subtitle: 'App appearance',
                        value: _settings.darkMode,
                        onChanged: (v) {
                          _settings.toggle('darkMode', v);
                          _toast('Dark mode ${v ? "on" : "off"}');
                        },
                      ),
                      _ToggleRow(
                        icon: CupertinoIcons.bell_fill,
                        iconBg: _accent,
                        label: 'Notifications',
                        subtitle: 'AQI alerts & updates',
                        value: _settings.notifications,
                        onChanged: (v) {
                          _settings.toggle('notifications', v);
                          _toast('Notifications ${v ? "enabled" : "disabled"}');
                        },
                      ),
                      _ToggleRow(
                        icon: CupertinoIcons.person_crop_circle_fill,
                        iconBg: const Color(0xFF8E8E93),
                        label: 'Biometric Unlock',
                        subtitle: 'Fingerprint / Face ID',
                        value: _settings.biometric,
                        onChanged: (v) {
                          _settings.toggle('biometric', v);
                          _toast('Biometric ${v ? "enabled" : "disabled"}');
                        },
                      ),
                      _ToggleRow(
                        icon: CupertinoIcons.arrow_2_circlepath,
                        iconBg: const Color(0xFF30B0C7),
                        label: 'Cloud Sync',
                        subtitle: 'Sync data across devices',
                        value: _settings.cloudSync,
                        onChanged: (v) {
                          _settings.toggle('cloudSync', v);
                          _toast('Cloud sync ${v ? "on" : "off"}');
                        },
                      ),
                    ]),                          // ← closes Preferences _Group

                    const SizedBox(height: 28),

                    // ── General ────────────────────────────────────
                    _label('General'),
                    const SizedBox(height: 8),
                    _Group(children: [
                      _NavRow(
                        icon: CupertinoIcons.globe,
                        iconBg: const Color(0xFF007AFF),
                        label: 'Language',
                        value: _settings.language,
                        onTap: () => _pick(
                          title: 'Language',
                          options: ['English', 'Kiswahili'],
                          current: _settings.language,
                          onSelect: (v) => _settings.set('language', v),
                        ),
                      ),
                      _NavRow(
                        icon: CupertinoIcons.location_fill,
                        iconBg: const Color(0xFFFF9500),
                        label: 'Region',
                        value: _settings.region,
                        onTap: () => _pick(
                          title: 'Region',
                          options: ['TZ', 'KE', 'UG', 'RW', 'ZM', 'MZ'],
                          current: _settings.region,
                          onSelect: (v) => _settings.set('region', v),
                        ),
                      ),
                      _NavRow(
                        icon: CupertinoIcons.info_circle_fill,
                        iconBg: const Color(0xFF007AFF),
                        label: 'About',
                        value: _appVersion,
                        onTap: () => _aboutDialog(),
                      ),
                    ]),                          // ← closes General _Group

                    const SizedBox(height: 28),

                    // ── Air Quality ────────────────────────────────
                    _label('Air Quality'),
                    const SizedBox(height: 8),
                    _Group(children: [
                      _NavRow(
                        icon: CupertinoIcons.location_circle_fill,
                        iconBg: const Color(0xFF30B0C7),
                        label: 'Default Station',
                        value: _settings.station,
                        onTap: () => _pick(
                          title: 'Default Station',
                          options: ['Kinondoni', 'Ilala', 'Temeke',
                                    'Ubungo', 'Kigamboni'],
                          current: _settings.station,
                          onSelect: (v) => _settings.set('station', v),
                        ),
                      ),
                      _NavRow(
                        icon: CupertinoIcons.bell_circle_fill,
                        iconBg: _accent,
                        label: 'AQI Alert Threshold',
                        value: _settings.aqiThreshold.split(' ').first,
                        onTap: () => _pick(
                          title: 'AQI Alert Threshold',
                          options: ['50 — Good', '100 — Moderate',
                                    '150 — Sensitive', '200 — Unhealthy',
                                    '300 — Very Unhealthy'],
                          current: _settings.aqiThreshold,
                          onSelect: (v) => _settings.set('aqiThreshold', v),
                        ),
                      ),
                      _NavRow(
                        icon: CupertinoIcons.refresh_circled_solid,
                        iconBg: const Color(0xFF34C759),
                        label: 'Refresh Interval',
                        value: _settings.refreshInterval,
                        onTap: () => _pick(
                          title: 'Refresh Interval',
                          options: ['1 min', '2 min', '5 min',
                                    '10 min', '30 min'],
                          current: _settings.refreshInterval,
                          onSelect: (v) => _settings.set('refreshInterval', v),
                        ),
                      ),
                    ]),                          // ← closes Air Quality _Group

                    const SizedBox(height: 28),

                    // ── Account ────────────────────────────────────
                    _label('Account'),
                    const SizedBox(height: 8),
                    _Group(children: [
                      _NavRow(
                        icon: CupertinoIcons.shield_fill,
                        iconBg: const Color(0xFF5856D6),
                        label: 'Privacy & Security',
                        onTap: () {},
                      ),
                      _NavRow(
                        icon: CupertinoIcons.question_circle_fill,
                        iconBg: const Color(0xFF32ADE6),
                        label: 'Help & Support',
                        onTap: () {},
                      ),
                      _NavRow(
                        icon: CupertinoIcons.star_fill,
                        iconBg: const Color(0xFFFF9500),
                        label: 'Rate the App',
                        onTap: () => _toast('Thank you! 🌟'),
                      ),
                    ]),                          // ← closes Account _Group

                    const SizedBox(height: 28),

                    // ── Sign in CTA ────────────────────────────────
                    _SignInCta(),
                    const SizedBox(height: 32),

                    Center(child: Text(
                      'AirWatch $_appVersion · Dar es Salaam',
                      style: const TextStyle(fontSize: 12, color: _textSub),
                    )),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void _pick({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: _border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Align(alignment: Alignment.centerLeft,
              child: Text(title, style: const TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w700, color: _textMain))),
          ),
          const Divider(color: _divider, height: 1),
          ...options.map((o) {
            final isSelected = o == current;
            return ListTile(
              onTap: () {
                onSelect(o);
                setState(() {});
                Navigator.pop(context);
                _toast('$title set to $o');
              },
              title: Text(o, style: TextStyle(
                  fontSize: 15,
                  color: isSelected ? _accent : _textMain,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
              trailing: isSelected
                  ? const Icon(Icons.check_rounded, color: _accent, size: 18)
                  : null,
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _aboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('AirWatch',
            style: TextStyle(color: _textMain, fontWeight: FontWeight.w700)),
        content: const Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Air Quality Monitoring App',
                style: TextStyle(color: _textSub, fontSize: 13)),
            SizedBox(height: 4),
            Text('Version 1.0.0',
                style: TextStyle(color: _textSub, fontSize: 13)),
            SizedBox(height: 12),
            Text('Monitoring Dar es Salaam\'s air quality in real time '
                'using IoT sensors and ML-powered forecasting.',
                style: TextStyle(color: _textSub, fontSize: 13, height: 1.5)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: _accent)),
          ),
        ],
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: _cardBg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(color: _cardBg, shape: BoxShape.circle,
          border: Border.all(color: _border)),
      child: Icon(icon, size: 16, color: _textSub),
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(text.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: _textSub, letterSpacing: 0.8)),
  );
}

// ─── Group ────────────────────────────────────────────────────────────────────

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(const Padding(
          padding: EdgeInsets.only(left: 58),
          child: Divider(height: 0.5, thickness: 0.5, color: _divider),
        ));
      }
    }
    return Container(
      decoration: BoxDecoration(color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border, width: 0.5)),
      child: Column(children: rows),
    );
  }
}

// ─── Toggle Row ───────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.icon, required this.iconBg,
      required this.label, required this.subtitle,
      required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        _iconBox(icon, iconBg),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 15, color: _textMain)),
            Text(subtitle,
                style: const TextStyle(fontSize: 11, color: _textSub)),
          ],
        )),
        CupertinoSwitch(
            value: value, onChanged: onChanged, activeColor: _accent),
      ]),
    );
  }
}

// ─── Nav Row ─────────────────────────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _NavRow({required this.icon, required this.iconBg,
      required this.label, required this.onTap, this.value});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          _iconBox(icon, iconBg),
          const SizedBox(width: 14),
          Expanded(child: Text(label,
              style: const TextStyle(fontSize: 15, color: _textMain))),
          if (value != null)
            Text(value!,
                style: const TextStyle(fontSize: 13, color: _textSub)),
          const SizedBox(width: 6),
          const Icon(CupertinoIcons.chevron_right,
              size: 14, color: Color(0xFF475569)),
        ]),
      ),
    );
  }
}

// ─── Guest Card ───────────────────────────────────────────────────────────────

class _GuestCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border)),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: _bg, shape: BoxShape.circle,
              border: Border.all(color: _border)),
          child: const Icon(CupertinoIcons.person_fill,
              size: 26, color: Color(0xFF475569)),
        ),
        const SizedBox(width: 14),
        const Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Guest User', style: TextStyle(fontSize: 16,
                fontWeight: FontWeight.w600, color: _textMain)),
            SizedBox(height: 2),
            Text('Sign in to sync your data',
                style: TextStyle(fontSize: 13, color: _textSub)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(color: _accent,
              borderRadius: BorderRadius.circular(99)),
          child: const Text('Sign In',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
      ]),
    );
  }
}

// ─── Sign In CTA ──────────────────────────────────────────────────────────────

class _SignInCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_accent, Color(0xFFFF6B81)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create an account', style: TextStyle(fontSize: 15,
                fontWeight: FontWeight.w700, color: Colors.white)),
            SizedBox(height: 4),
            Text('Save stations, history\nand personalized alerts.',
                style: TextStyle(fontSize: 12, color: Colors.white70,
                    height: 1.4)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(99)),
          child: const Text('Get Started', style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: _accent)),
        ),
      ]),
    );
  }
}

// ─── Icon Box ─────────────────────────────────────────────────────────────────

Widget _iconBox(IconData icon, Color bg) => Container(
  width: 32, height: 32,
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
  child: Icon(icon, size: 17, color: Colors.white),
);