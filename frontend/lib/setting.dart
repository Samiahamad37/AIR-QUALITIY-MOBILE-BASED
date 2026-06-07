import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode      = true;
  bool _notifications = true;
  bool _biometric     = true;
  bool _cloudSync     = false;

  static const _appVersion  = 'v1.0.0';
  static const _storageUsed = '2.4 GB';
  static const _language    = 'English';
  static const _region      = 'TZ';

  // ── Dark-mode palette ────────────────────────────────────────────────────
  static const _bg        = Color(0xFF0F172A);  // page background
  static const _cardBg    = Color(0xFF1E293B);  // card / group background
  static const _divider   = Color(0xFF2D3748);  // divider line
  static const _textMain  = Color(0xFFFFFFFF);  // primary text
  static const _textSub   = Color(0xFF94A3B8);  // secondary text
  static const _accent    = Color(0xFFFF2D55);  // pink accent

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: CustomScrollView(
          slivers: [

            // ── App Bar ──────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: _bg,
              elevation: 0,
              pinned: true,
              toolbarHeight: 60,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Settings',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                          color: _textMain, letterSpacing: -0.5)),
                  Row(children: [
                    _iconBtn(CupertinoIcons.search, () {}),
                    const SizedBox(width: 8),
                    _iconBtn(CupertinoIcons.ellipsis, () {}),
                  ]),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 8),

                    // ── Guest card ───────────────────────────────────────
                    _GuestCard(accent: _accent, cardBg: _cardBg,
                        textMain: _textMain, textSub: _textSub),

                    const SizedBox(height: 28),

                    // ── Preferences ──────────────────────────────────────
                    _sectionLabel('Preferences'),
                    const SizedBox(height: 8),
                    _Group(cardBg: _cardBg, dividerColor: _divider, children: [
                      _ToggleRow(icon: CupertinoIcons.moon_fill,
                          iconBg: const Color(0xFF636366),
                          label: 'Dark Mode', value: _darkMode,
                          textMain: _textMain,
                          onChanged: (v) => setState(() => _darkMode = v)),
                      _ToggleRow(icon: CupertinoIcons.bell_fill,
                          iconBg: _accent,
                          label: 'Notifications', value: _notifications,
                          textMain: _textMain,
                          onChanged: (v) => setState(() => _notifications = v)),
                      _ToggleRow(icon: CupertinoIcons.person_crop_circle_fill,
                          iconBg: const Color(0xFF8E8E93),
                          label: 'Biometric Unlock', value: _biometric,
                          textMain: _textMain,
                          onChanged: (v) => setState(() => _biometric = v)),
                      _ToggleRow(icon: CupertinoIcons.arrow_2_circlepath,
                          iconBg: const Color(0xFF636366),
                          label: 'Cloud Sync', value: _cloudSync,
                          textMain: _textMain,
                          onChanged: (v) => setState(() => _cloudSync = v)),
                    ]),

                    const SizedBox(height: 28),

                    // ── General ──────────────────────────────────────────
                    _sectionLabel('General'),
                    const SizedBox(height: 8),
                    _Group(cardBg: _cardBg, dividerColor: _divider, children: [
                      _NavRow(icon: CupertinoIcons.globe,
                          iconBg: const Color(0xFF007AFF),
                          label: 'Language', value: _language,
                          textMain: _textMain, textSub: _textSub,
                          onTap: () => _showPicker('Language',
                              ['English', 'Kiswahili', 'French'])),
                      _NavRow(icon: CupertinoIcons.location_fill,
                          iconBg: const Color(0xFFFF9500),
                          label: 'Region', value: _region,
                          textMain: _textMain, textSub: _textSub,
                          onTap: () => _showPicker('Region',
                              ['TZ', 'KE', 'UG', 'RW'])),
                      _NavRow(icon: CupertinoIcons.device_phone_portrait,
                          iconBg: const Color(0xFF34C759),
                          label: 'Storage', value: _storageUsed,
                          textMain: _textMain, textSub: _textSub,
                          onTap: () {}),
                      _NavRow(icon: CupertinoIcons.info_circle_fill,
                          iconBg: const Color(0xFF007AFF),
                          label: 'About', value: _appVersion,
                          textMain: _textMain, textSub: _textSub,
                          onTap: () => _showAbout()),
                    ]),

                    const SizedBox(height: 28),

                    // ── Air Quality ───────────────────────────────────────
                    _sectionLabel('Air Quality'),
                    const SizedBox(height: 8),
                    _Group(cardBg: _cardBg, dividerColor: _divider, children: [
                      _NavRow(icon: CupertinoIcons.location_circle_fill,
                          iconBg: const Color(0xFF30B0C7),
                          label: 'Default Station', value: 'Kinondoni',
                          textMain: _textMain, textSub: _textSub,
                          onTap: () {}),
                      _NavRow(icon: CupertinoIcons.bell_circle_fill,
                          iconBg: _accent,
                          label: 'AQI Alert Threshold', value: '150',
                          textMain: _textMain, textSub: _textSub,
                          onTap: () => _showThresholdPicker()),
                      _NavRow(icon: CupertinoIcons.refresh_circled_solid,
                          iconBg: const Color(0xFF34C759),
                          label: 'Refresh Interval', value: '5 min',
                          textMain: _textMain, textSub: _textSub,
                          onTap: () {}),
                    ]),

                    const SizedBox(height: 28),

                    // ── Account ──────────────────────────────────────────
                    _sectionLabel('Account'),
                    const SizedBox(height: 8),
                    _Group(cardBg: _cardBg, dividerColor: _divider, children: [
                      _NavRow(icon: CupertinoIcons.shield_fill,
                          iconBg: const Color(0xFF5856D6),
                          label: 'Privacy & Security',
                          textMain: _textMain, textSub: _textSub,
                          onTap: () {}),
                      _NavRow(icon: CupertinoIcons.question_circle_fill,
                          iconBg: const Color(0xFF32ADE6),
                          label: 'Help & Support',
                          textMain: _textMain, textSub: _textSub,
                          onTap: () {}),
                      _NavRow(icon: CupertinoIcons.star_fill,
                          iconBg: const Color(0xFFFF9500),
                          label: 'Rate the App',
                          textMain: _textMain, textSub: _textSub,
                          onTap: () {}),
                    ]),

                    const SizedBox(height: 28),

                    // ── Sign in CTA ───────────────────────────────────────
                    _SignInCta(accent: _accent),

                    const SizedBox(height: 32),

                    Center(child: Text('AirWatch $_appVersion · Dar es Salaam',
                        style: const TextStyle(
                            fontSize: 12, color: _textSub))),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
          color: const Color(0xFF1E293B), shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF334155))),
      child: Icon(icon, size: 16, color: _textSub),
    ),
  );

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(label.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: _textSub, letterSpacing: 0.8)),
  );

  void _showPicker(String title, List<String> options) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(title),
        actions: options.map((o) => CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(o),
        )).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showThresholdPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('AQI Alert Threshold'),
        message: const Text('Get notified when AQI exceeds this value'),
        actions: ['50 — Good', '100 — Moderate', '150 — Sensitive',
          '200 — Unhealthy', '300 — Very Unhealthy']
            .map((o) => CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(o),
        )).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showAbout() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('AirWatch'),
        content: const Text(
            'Air Quality Monitoring App\nVersion 1.0.0\n\n'
            'Monitoring Dar es Salaam\'s air quality in real time.'),
        actions: [CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        )],
      ),
    );
  }
}

// ─── Guest Card ───────────────────────────────────────────────────────────────

class _GuestCard extends StatelessWidget {
  final Color accent, cardBg, textMain, textSub;
  const _GuestCard({required this.accent, required this.cardBg,
      required this.textMain, required this.textSub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: const Icon(CupertinoIcons.person_fill,
              size: 26, color: Color(0xFF475569)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Guest User', style: TextStyle(fontSize: 16,
                fontWeight: FontWeight.w600, color: textMain)),
            const SizedBox(height: 2),
            Text('Sign in to sync your data',
                style: TextStyle(fontSize: 13, color: textSub)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
              color: accent, borderRadius: BorderRadius.circular(99)),
          child: const Text('Sign In',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ),
      ]),
    );
  }
}

// ─── Settings Group ───────────────────────────────────────────────────────────

class _Group extends StatelessWidget {
  final List<Widget> children;
  final Color cardBg, dividerColor;
  const _Group({required this.children, required this.cardBg,
      required this.dividerColor});

  @override
  Widget build(BuildContext context) {
    final divided = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      divided.add(children[i]);
      if (i < children.length - 1) {
        divided.add(Padding(
          padding: const EdgeInsets.only(left: 52),
          child: Divider(height: 0.5, thickness: 0.5, color: dividerColor),
        ));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155), width: 0.5),
      ),
      child: Column(children: divided),
    );
  }
}

// ─── Toggle Row ───────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final bool value;
  final Color textMain;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.icon, required this.iconBg,
      required this.label, required this.value,
      required this.textMain, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        _iconBox(icon, iconBg),
        const SizedBox(width: 14),
        Expanded(child: Text(label,
            style: TextStyle(fontSize: 15, color: textMain))),
        CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFFF2D55),
        ),
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
  final Color textMain, textSub;
  final VoidCallback onTap;

  const _NavRow({required this.icon, required this.iconBg,
      required this.label, required this.onTap,
      required this.textMain, required this.textSub, this.value});

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
              style: TextStyle(fontSize: 15, color: textMain))),
          if (value != null)
            Text(value!, style: TextStyle(fontSize: 14, color: textSub)),
          const SizedBox(width: 6),
          const Icon(CupertinoIcons.chevron_right,
              size: 14, color: Color(0xFF475569)),
        ]),
      ),
    );
  }
}

// ─── Sign In CTA ──────────────────────────────────────────────────────────────

class _SignInCta extends StatelessWidget {
  final Color accent;
  const _SignInCta({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, const Color(0xFFFF6B81)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create an account',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: Colors.white)),
            SizedBox(height: 4),
            Text('Save stations, history\nand personalized alerts.',
                style: TextStyle(fontSize: 12, color: Colors.white70,
                    height: 1.4)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(99)),
          child: Text('Get Started',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: accent)),
        ),
      ]),
    );
  }
}

// ─── Icon Box ─────────────────────────────────────────────────────────────────

Widget _iconBox(IconData icon, Color bg) => Container(
  width: 32, height: 32,
  decoration: BoxDecoration(
      color: bg, borderRadius: BorderRadius.circular(8)),
  child: Icon(icon, size: 17, color: Colors.white),
);