import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'forecast_data.dart';
import 'air_quality_data.dart';
import 'app_theme.dart';
import 'common_widget.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen>
    with SingleTickerProviderStateMixin {
  late List<DailyForecast> _daily;
  late List<HourlyForecast> _hourly;
  late List<ForecastInsight> _insights;
  int _selectedDayIndex = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _daily = getMockDailyForecast();
    _hourly = getMockHourlyForecast();
    _insights = getMockInsights();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _selectDay(int index) {
    setState(() => _selectedDayIndex = index);
    _fadeCtrl
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _daily[_selectedDayIndex];
    final level = selected.level;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: CustomScrollView(
          slivers: [
            // ─── Header ──────────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(selected, level)),

            // ─── 7-Day Forecast Strip ─────────────────────────────────────
            const SliverToBoxAdapter(
              child: SectionHeader(title: '7-Day Forecast'),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 116,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _daily.length,
                  itemBuilder: (_, i) => _DayCard(
                    forecast: _daily[i],
                    isSelected: i == _selectedDayIndex,
                    onTap: () => _selectDay(i),
                    index: i,
                  ),
                ),
              ),
            ),

            // ─── Hourly AQI Chart ─────────────────────────────────────────
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'Hourly AQI — Today'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Column(
                    children: [
                      _HourlyChart(hourly: _hourly),
                      const SizedBox(height: 12),
                      _AqiLegendRow(),
                    ],
                  ),
                ),
              ),
            ),

            // ─── AQI Range Card for selected day ─────────────────────────
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'Selected Day Detail'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: _DayDetailCard(forecast: selected, level: level),
                ),
              ),
            ),

            // ─── Insights ─────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'Smart Insights'),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding:
                      EdgeInsets.fromLTRB(16, 0, 16, i == _insights.length - 1 ? 0 : 10),
                  child: _InsightCard(insight: _insights[i], index: i),
                ),
                childCount: _insights.length,
              ),
            ),

            // ─── Model Info Footer ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7F77DD).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.psychology_rounded,
                            size: 20, color: Color(0xFF7F77DD)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ML Prediction Model',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            SizedBox(height: 2),
                            Text(
                              'Forecasts powered by your trained model · Updated every 3 hours',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(DailyForecast selected, AqiLevel level) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AQI Forecast',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7F77DD).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                          color: const Color(0xFF7F77DD).withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.psychology_rounded,
                            size: 13, color: Color(0xFF7F77DD)),
                        SizedBox(width: 4),
                        Text('AI Powered',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7F77DD))),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Today's big summary
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today · May 14',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_daily[0].aqiAvg}',
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w800,
                                color: _daily[0].level.color,
                                height: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10, left: 6),
                              child: Text(
                                'AQI',
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _daily[0].level.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                                color: _daily[0].level.color.withOpacity(0.3)),
                          ),
                          child: Text(
                            _daily[0].level.name,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _daily[0].level.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mini 5-day sparkline preview
                  _MiniSparkline(daily: _daily.take(5).toList()),
                ],
              ),

              const SizedBox(height: 16),

              // Min/Max/Trend row
              Row(
                children: [
                  _headerStat(
                      'Min Today',
                      '${_daily[0].aqiMin}',
                      const Color(0xFF4ADE80)),
                  const SizedBox(width: 20),
                  _headerStat(
                      'Max Today',
                      '${_daily[0].aqiMax}',
                      const Color(0xFFF87171)),
                  const SizedBox(width: 20),
                  _headerStat(
                      'Trend',
                      '↓ Improving',
                      const Color(0xFF4ADE80)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

// ─── Day Card ─────────────────────────────────────────────────────────────────

class _DayCard extends StatefulWidget {
  final DailyForecast forecast;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const _DayCard({
    required this.forecast,
    required this.isSelected,
    required this.onTap,
    required this.index,
  });

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    Future.delayed(Duration(milliseconds: widget.index * 70), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.forecast;
    final level = f.level;

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 80,
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: widget.isSelected ? level.bgColor : AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? level.color.withOpacity(0.6)
                  : AppColors.border.withOpacity(0.4),
              width: widget.isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                f.dayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.isSelected
                      ? level.textColor
                      : AppColors.textSecondary,
                ),
              ),
              Icon(f.weatherIcon,
                  size: 22,
                  color: widget.isSelected ? level.color : AppColors.textMuted),
              Text(
                '${f.aqiAvg}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: level.color,
                ),
              ),
              Container(
                height: 4,
                width: 32,
                decoration: BoxDecoration(
                  color: level.color.withOpacity(widget.isSelected ? 0.8 : 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hourly Chart ─────────────────────────────────────────────────────────────

class _HourlyChart extends StatefulWidget {
  final List<HourlyForecast> hourly;
  const _HourlyChart({required this.hourly});

  @override
  State<_HourlyChart> createState() => _HourlyChartState();
}

class _HourlyChartState extends State<_HourlyChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxAqi =
        widget.hourly.map((h) => h.aqi).reduce((a, b) => a > b ? a : b);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return SizedBox(
          height: 130,
          child: CustomPaint(
            painter: _LineChartPainter(
              hourly: widget.hourly,
              maxAqi: maxAqi,
              progress: _anim.value,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: widget.hourly.map((h) {
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (h.isCurrent)
                        Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: h.level.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${h.aqi}',
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.black),
                          ),
                        ),
                      Text(
                        h.time,
                        style: TextStyle(
                          fontSize: 9,
                          color: h.isCurrent
                              ? h.level.color
                              : AppColors.textMuted,
                          fontWeight: h.isCurrent
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<HourlyForecast> hourly;
  final int maxAqi;
  final double progress;

  _LineChartPainter(
      {required this.hourly, required this.maxAqi, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (hourly.isEmpty) return;

    final chartH = size.height - 28;
    final stepX = size.width / (hourly.length - 1);

    List<Offset> points = [];
    for (int i = 0; i < hourly.length; i++) {
      final x = i * stepX;
      final y = chartH - (hourly[i].aqi / maxAqi) * chartH * 0.85;
      points.add(Offset(x, y));
    }

    final visibleCount = (points.length * progress).ceil().clamp(2, points.length);
    final visiblePoints = points.sublist(0, visibleCount);

    // Draw filled area
    final fillPath = Path();
    fillPath.moveTo(visiblePoints.first.dx, chartH);
    for (final pt in visiblePoints) {
      fillPath.lineTo(pt.dx, pt.dy);
    }
    fillPath.lineTo(visiblePoints.last.dx, chartH);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFB923C).withOpacity(0.25),
            const Color(0xFFFB923C).withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Draw line
    final linePath = Path();
    linePath.moveTo(visiblePoints.first.dx, visiblePoints.first.dy);
    for (int i = 1; i < visiblePoints.length; i++) {
      final prev = visiblePoints[i - 1];
      final curr = visiblePoints[i];
      final cpX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFFFB923C)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Draw dots
    for (int i = 0; i < visiblePoints.length; i++) {
      final h = hourly[i];
      final level = getAqiLevel(h.aqi);
      if (h.isCurrent) {
        canvas.drawCircle(
          visiblePoints[i],
          6,
          Paint()..color = level.color,
        );
        canvas.drawCircle(
          visiblePoints[i],
          3,
          Paint()..color = Colors.white,
        );
      } else {
        canvas.drawCircle(
          visiblePoints[i],
          3,
          Paint()..color = level.color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.progress != progress;
}

// ─── AQI Legend Row ───────────────────────────────────────────────────────────

class _AqiLegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final levels = [
      ('Good', const Color(0xFF4ADE80)),
      ('Moderate', const Color(0xFFFACC15)),
      ('Sensitive', const Color(0xFFFB923C)),
      ('Unhealthy', const Color(0xFFF87171)),
      ('Very', const Color(0xFFC084FC)),
    ];

    return Row(
      children: levels
          .map((l) => Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: l.$2,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.$1,
                      style: const TextStyle(
                          fontSize: 8, color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

// ─── Day Detail Card ──────────────────────────────────────────────────────────

class _DayDetailCard extends StatelessWidget {
  final DailyForecast forecast;
  final AqiLevel level;

  const _DayDetailCard({required this.forecast, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: level.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: level.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(forecast.weatherIcon, color: level.color, size: 22),
              const SizedBox(width: 10),
              Text(
                '${forecast.dayName} · ${forecast.date}',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: level.textColor),
              ),
              const Spacer(),
              Text(
                forecast.condition,
                style: TextStyle(fontSize: 12, color: level.textColor.withOpacity(0.7)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _rangeBlock('Average AQI', '${forecast.aqiAvg}', level.color),
              const SizedBox(width: 12),
              _rangeBlock('Min', '${forecast.aqiMin}', const Color(0xFF4ADE80)),
              const SizedBox(width: 12),
              _rangeBlock('Max', '${forecast.aqiMax}', const Color(0xFFF87171)),
            ],
          ),
          const SizedBox(height: 14),
          // AQI range bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: AppColors.bgCardLight),
                  FractionallySizedBox(
                    widthFactor: forecast.aqiMax / 300,
                    child: Container(color: level.color.withOpacity(0.3)),
                  ),
                  FractionallySizedBox(
                    widthFactor: forecast.aqiAvg / 300,
                    child: Container(color: level.color),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Min: ${forecast.aqiMin}',
                  style: TextStyle(
                      fontSize: 10, color: level.textColor.withOpacity(0.7))),
              Text('Max: ${forecast.aqiMax}',
                  style: TextStyle(
                      fontSize: 10, color: level.textColor.withOpacity(0.7))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rangeBlock(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─── Insight Card ─────────────────────────────────────────────────────────────

class _InsightCard extends StatefulWidget {
  final ForecastInsight insight;
  final int index;

  const _InsightCard({required this.insight, required this.index});

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ins = widget.insight;
    return SlideTransition(
      position: _slideAnim,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: ins.color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ins.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(ins.icon, color: ins.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ins.title,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(ins.value,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: ins.color)),
                  const SizedBox(height: 2),
                  Text(ins.subtitle,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.4)),
                ],
              ),
            ),
            Icon(
              ins.isPositive
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: ins.isPositive
                  ? const Color(0xFF4ADE80)
                  : const Color(0xFFF87171),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mini Sparkline ───────────────────────────────────────────────────────────

class _MiniSparkline extends StatelessWidget {
  final List<DailyForecast> daily;
  const _MiniSparkline({required this.daily});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 60,
      child: CustomPaint(painter: _SparklinePainter(daily: daily)),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<DailyForecast> daily;
  _SparklinePainter({required this.daily});

  @override
  void paint(Canvas canvas, Size size) {
    if (daily.length < 2) return;

    final maxAqi = daily.map((d) => d.aqiAvg).reduce((a, b) => a > b ? a : b);
    final minAqi = daily.map((d) => d.aqiAvg).reduce((a, b) => a < b ? a : b);
    final range = (maxAqi - minAqi).toDouble();

    List<Offset> pts = [];
    for (int i = 0; i < daily.length; i++) {
      final x = i / (daily.length - 1) * size.width;
      final y = range == 0
          ? size.height / 2
          : size.height - ((daily[i].aqiAvg - minAqi) / range) * size.height * 0.8 - 4;
      pts.add(Offset(x, y));
    }

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cp = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i - 1].dy);
      path.quadraticBezierTo(cp.dx, cp.dy, pts[i].dx, pts[i].dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF4ADE80)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    for (int i = 0; i < pts.length; i++) {
      canvas.drawCircle(
          pts[i], i == 0 ? 4 : 2.5, Paint()..color = daily[i].level.color);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => false;
}