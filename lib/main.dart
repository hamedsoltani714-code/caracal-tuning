import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CaracalApp());
}

const Color bg = Color(0xFF08090B);
const Color panel = Color(0xFF15171B);
const Color silver = Color(0xFFC5CBD2);
const Color red = Color(0xFFFF3038);

class CaracalApp extends StatefulWidget {
  const CaracalApp({super.key});

  @override
  State<CaracalApp> createState() => _CaracalAppState();
}

class _CaracalAppState extends State<CaracalApp> {
  bool english = false;
  bool haptics = true;
  bool redline = true;
  bool animations = true;
  bool engineSound = true;
  bool compact = false;
  int selectedTab = 0;
  bool ready = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => ready = true);
    });
  }

  Future<void> _loadSettings() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      english = p.getBool('english') ?? false;
      haptics = p.getBool('haptics') ?? true;
      redline = p.getBool('redline') ?? true;
      animations = p.getBool('animations') ?? true;
      engineSound = p.getBool('engineSound') ?? true;
      compact = p.getBool('compact') ?? false;
    });
  }

  Future<void> save(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  String t(String fa, String en) => english ? en : fa;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CARACAL TUNING',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: red,
          surface: panel,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: ready ? _mainScreen() : const IntroScreen(),
    );
  }

  Widget _mainScreen() {
    final pages = [
      HomeScreen(
        english: english,
        compact: compact,
        redline: redline,
        animations: animations,
        onNavigate: (i) => setState(() => selectedTab = i),
      ),
      LearnScreen(english: english),
      GarageScreen(english: english),
      SettingsScreen(
        english: english,
        haptics: haptics,
        redline: redline,
        animations: animations,
        engineSound: engineSound,
        compact: compact,
        onChange: (key, value) async {
          await save(key, value);
          setState(() {
            switch (key) {
              case 'english':
                english = value;
                break;
              case 'haptics':
                haptics = value;
                break;
              case 'redline':
                redline = value;
                break;
              case 'animations':
                animations = value;
                break;
              case 'engineSound':
                engineSound = value;
                break;
              case 'compact':
                compact = value;
                break;
            }
          });
        },
      ),
    ];

    return Directionality(
      textDirection: english ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: selectedTab,
            children: pages,
          ),
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: const Color(0xFF101114),
          indicatorColor: red.withOpacity(.18),
          selectedIndex: selectedTab,
          onDestinationSelected: (i) {
            if (haptics) HapticFeedback.selectionClick();
            setState(() => selectedTab = i);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard, color: red),
              label: t('خانه', 'Home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.school_outlined),
              selectedIcon: const Icon(Icons.school, color: red),
              label: t('آموزش', 'Learn'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.directions_car_outlined),
              selectedIcon: const Icon(Icons.directions_car, color: red),
              label: t('گاراژ', 'Garage'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.tune_outlined),
              selectedIcon: const Icon(Icons.tune, color: red),
              label: t('تنظیمات', 'Control'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- INTRO ----------------

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final v = Curves.easeOutCubic.transform(controller.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: IntroLinesPainter(progress: v),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: .65 + v * .35,
                    child: Opacity(
                      opacity: v.clamp(0, 1),
                      child: const SizedBox(
                        width: 230,
                        height: 190,
                        child: CustomPaint(painter: CaracalPainter()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'CARACAL',
                    style: TextStyle(
                      fontSize: 37,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 7,
                      color: silver.withOpacity(v),
                    ),
                  ),
                  const Text(
                    'T U N I N G',
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: 8,
                      color: red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 220,
                    height: 7,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: v,
                        backgroundColor: Colors.white12,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'DRIVE • LEARN • UPGRADE',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class IntroLinesPainter extends CustomPainter {
  final double progress;
  IntroLinesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = red.withOpacity(.12)
      ..strokeWidth = 1;

    for (int i = 0; i < 12; i++) {
      final y = size.height * (i / 12);
      canvas.drawLine(
        Offset(0, y + progress * 30),
        Offset(size.width, y - progress * 30),
        p,
      );
    }

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [red.withOpacity(.15), Colors.transparent],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width * .7,
        ),
      );

    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant IntroLinesPainter oldDelegate) => true;
}

// ---------------- HOME ----------------

class HomeScreen extends StatelessWidget {
  final bool english;
  final bool compact;
  final bool redline;
  final bool animations;
  final ValueChanged<int> onNavigate;

  const HomeScreen({
    super.key,
    required this.english,
    required this.compact,
    required this.redline,
    required this.animations,
    required this.onNavigate,
  });

  String t(String fa, String en) => english ? en : fa;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        Row(
          children: [
            const SizedBox(
              width: 52,
              height: 48,
              child: CustomPaint(painter: CaracalPainter()),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CARACAL TUNING',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'DRIVE • LEARN • UPGRADE',
                    style: TextStyle(
                      color: red,
                      fontSize: 9,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none, color: silver),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t('آماده‌ای؟', 'READY TO DRIVE?'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const Icon(Icons.bolt, color: red, size: 25),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 210,
                child: AnimatedGauge(
                  redline: redline,
                  animations: animations,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t('قدرت را بشناس؛ دقیق‌تر تنظیم کن',
                    'Understand power. Tune smarter.'),
                style: const TextStyle(
                  color: silver,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Text(
          t('دسترسی سریع', 'QUICK ACCESS'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 13),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            QuickCard(
              icon: Icons.school,
              title: t('آموزش تخصصی', 'Technical Learning'),
              subtitle: t('دانش فنی خودرو', 'Automotive knowledge'),
              onTap: () => onNavigate(1),
            ),
            QuickCard(
              icon: Icons.memory,
              title: t('ریمپ و ECU', 'ECU & Remap'),
              subtitle: t('مفاهیم و آموزش', 'Concepts & tutorials'),
              onTap: () => onNavigate(1),
            ),
            QuickCard(
              icon: Icons.car_repair,
              title: t('گاراژ من', 'My Garage'),
              subtitle: t('خودروهای من', 'My vehicles'),
              onTap: () => onNavigate(2),
            ),
            QuickCard(
              icon: Icons.settings,
              title: t('مرکز کنترل', 'Control Center'),
              subtitle: t('شخصی‌سازی برنامه', 'App customization'),
              onTap: () => onNavigate(3),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Text(
          t('آخرین بخش‌ها', 'FEATURED TOPICS'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        FeatureTile(
          icon: Icons.speed,
          title: t('اصول عملکرد موتور', 'Engine Fundamentals'),
          subtitle: t('آشنایی با پارامترهای اصلی موتور',
              'Understanding core engine parameters'),
        ),
        FeatureTile(
          icon: Icons.developer_board,
          title: t('آشنایی با ECU', 'Getting to Know ECU'),
          subtitle: t('ساختار و وظایف واحد کنترل موتور',
              'Engine control unit architecture'),
        ),
        FeatureTile(
          icon: Icons.analytics_outlined,
          title: t('مبانی تحلیل داده', 'Data Analysis Basics'),
          subtitle: t('شناخت داده‌ها و پارامترهای خودرو',
              'Understanding vehicle data'),
        ),
      ],
    );
  }
}

class QuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const QuickCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: red, size: 25),
            const SizedBox(height: 9),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const FeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icon, color: red, size: 26),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: silver),
        ],
      ),
    );
  }
}

// ---------------- RPM GAUGE ----------------

class AnimatedGauge extends StatefulWidget {
  final bool redline;
  final bool animations;

  const AnimatedGauge({
    super.key,
    required this.redline,
    required this.animations,
  });

  @override
  State<AnimatedGauge> createState() => _AnimatedGaugeState();
}

class _AnimatedGaugeState extends State<AnimatedGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> rpm;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    rpm = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0, end: 6500)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 6500, end: 2200)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
    ]).animate(controller);

    if (widget.animations) {
      controller.repeat();
    } else {
      controller.value = .65;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animations && !controller.isAnimating) {
      controller.repeat();
    } else if (!widget.animations && controller.isAnimating) {
      controller.stop();
      controller.value = .65;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rpm,
      builder: (context, child) {
        return CustomPaint(
          painter: GaugePainter(
            value: rpm.value,
            redline: widget.redline,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class GaugePainter extends CustomPainter {
  final double value;
  final bool redline;

  GaugePainter({
    required this.value,
    required this.redline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .78);
    final radius = math.min(size.width * .43, size.height * .72);
    const start = math.pi * 1.12;
    const sweep = math.pi * .76;

    final base = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      base,
    );

    final active = Paint()
      ..shader = const SweepGradient(
        colors: [silver, Colors.white, red],
        stops: [0, .72, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep * (value / 8000).clamp(0, 1),
      false,
      active,
    );

    final tickPaint = Paint()
      ..color = silver
      ..strokeWidth = 2;

    for (int i = 0; i <= 40; i++) {
      final angle = start + sweep * i / 40;
      final outer = Offset(
        center.dx + math.cos(angle) * (radius + 12),
        center.dy + math.sin(angle) * (radius + 12),
      );
      final inner = Offset(
        center.dx + math.cos(angle) * (radius - (i % 5 == 0 ? 12 : 6)),
        center.dy + math.sin(angle) * (radius - (i % 5 == 0 ? 12 : 6)),
      );

      tickPaint.color =
          i >= 34 && redline ? red : silver.withOpacity(.75);
      canvas.drawLine(inner, outer, tickPaint);
    }

    for (int i = 0; i <= 8; i++) {
      final angle = start + sweep * i / 8;
      final pos = Offset(
        center.dx + math.cos(angle) * (radius - 30),
        center.dy + math.sin(angle) * (radius - 30),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: '$i',
          style: TextStyle(
            color: i >= 7 && redline ? red : silver,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    final needleAngle = start + sweep * (value / 8000).clamp(0, 1);
    final needleEnd = Offset(
      center.dx + math.cos(needleAngle) * (radius - 22),
      center.dy + math.sin(needleAngle) * (radius - 22),
    );

    if (redline && value > 6000) {
      canvas.drawLine(
        center,
        needleEnd,
        Paint()
          ..color = red.withOpacity(.4)
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = red
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      center,
      10,
      Paint()..color = const Color(0xFF555B63),
    );
    canvas.drawCircle(
      center,
      5,
      Paint()..color = red,
    );

    final valueText = TextPainter(
      text: TextSpan(
        text: (value / 1000).toStringAsFixed(1),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 29,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    valueText.paint(
      canvas,
      Offset(center.dx - valueText.width / 2, center.dy - 48),
    );

    final unit = TextPainter(
      text: const TextSpan(
        text: 'x1000 RPM',
        style: TextStyle(
          color: silver,
          fontSize: 10,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    unit.paint(
      canvas,
      Offset(center.dx - unit.width / 2, center.dy - 15),
    );
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.redline != redline;
}

// ---------------- CARACAL LOGO ----------------

class CaracalPainter extends CustomPainter {
  const CaracalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 220;
    final sy = size.height / 180;

    canvas.save();
    canvas.scale(sx, sy);

    final metal = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFF9EA5AD),
          Color(0xFF353A40),
        ],
      ).createShader(const Rect.fromLTWH(0, 0, 220, 180));

    final dark = Paint()..color = const Color(0xFF171A1E);
    final eye = Paint()..color = red;
    final outline = Paint()
      ..color = const Color(0xFFD9DEE3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final head = Path()
      ..moveTo(38, 48)
      ..lineTo(26, 4)
      ..lineTo(72, 35)
      ..quadraticBezierTo(110, 17, 148, 35)
      ..lineTo(194, 4)
      ..lineTo(182, 51)
      ..quadraticBezierTo(205, 90, 176, 130)
      ..quadraticBezierTo(151, 164, 110, 174)
      ..quadraticBezierTo(69, 164, 44, 130)
      ..quadraticBezierTo(15, 90, 38, 48)
      ..close();

    canvas.drawPath(head, metal);
    canvas.drawPath(head, outline);

    final innerLeft = Path()
      ..moveTo(39, 18)
      ..lineTo(67, 42)
      ..lineTo(53, 76)
      ..close();

    final innerRight = Path()
      ..moveTo(181, 18)
      ..lineTo(153, 42)
      ..lineTo(167, 76)
      ..close();

    canvas.drawPath(innerLeft, dark);
    canvas.drawPath(innerRight, dark);

    final face = Path()
      ..moveTo(49, 70)
      ..quadraticBezierTo(110, 37, 171, 70)
      ..lineTo(158, 127)
      ..quadraticBezierTo(110, 170, 62, 127)
      ..close();

    canvas.drawPath(face, dark);

    final browLeft = Path()
      ..moveTo(52, 78)
      ..lineTo(103, 87)
      ..lineTo(84, 103)
      ..lineTo(49, 94)
      ..close();

    final browRight = Path()
      ..moveTo(168, 78)
      ..lineTo(117, 87)
      ..lineTo(136, 103)
      ..lineTo(171, 94)
      ..close();

    canvas.drawPath(browLeft, metal);
    canvas.drawPath(browRight, metal);

    final eyeLeft = Path()
      ..moveTo(59, 91)
      ..lineTo(96, 95)
      ..lineTo(81, 105)
      ..close();

    final eyeRight = Path()
      ..moveTo(161, 91)
      ..lineTo(124, 95)
      ..lineTo(139, 105)
      ..close();

    canvas.drawPath(eyeLeft, eye);
    canvas.drawPath(eyeRight, eye);

    final nose = Path()
      ..moveTo(91, 119)
      ..quadraticBezierTo(110, 108, 129, 119)
      ..lineTo(110, 134)
      ..close();

    canvas.drawPath(nose, metal);

    final mouth = Paint()
      ..color = silver
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawLine(const Offset(110, 134), const Offset(110, 148), mouth);
    canvas.drawLine(const Offset(110, 148), const Offset(88, 140), mouth);
    canvas.drawLine(const Offset(110, 148), const Offset(132, 140), mouth);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CaracalPainter oldDelegate) => false;
}

// ---------------- LEARN ----------------

class LearnScreen extends StatelessWidget {
  final bool english;
  const LearnScreen({super.key, required this.english});

  String t(String fa, String en) => english ? en : fa;

  @override
  Widget build(BuildContext context) {
    final items = [
      [Icons.memory, 'آشنایی با ECU', 'ECU Fundamentals'],
      [Icons.speed, 'اصول ریمپ', 'Remapping Basics'],
      [Icons.electric_bolt, 'سیستم جرقه', 'Ignition System'],
      [Icons.local_gas_station, 'سیستم سوخت‌رسانی', 'Fuel System'],
      [Icons.analytics, 'تحلیل پارامترها', 'Parameter Analysis'],
      [Icons.build, 'عیب‌یابی خودرو', 'Vehicle Diagnostics'],
      [Icons.settings_suggest, 'ساختار موتور', 'Engine Architecture'],
      [Icons.show_chart, 'مبانی جداول موتور', 'Engine Maps Basics'],
    ];

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          t('آموزش تخصصی', 'TECHNICAL ACADEMY'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t('دانش فنی، از پایه تا پیشرفته',
              'Automotive knowledge from basic to advanced'),
          style: const TextStyle(color: silver, fontSize: 12),
        ),
        const SizedBox(height: 20),
        for (final item in items)
          FeatureTile(
            icon: item[0] as IconData,
            title: t(item[1] as String, item[2] as String),
            subtitle: t('برای مشاهده و یادگیری انتخاب کنید',
                'Select to explore this topic'),
          ),
      ],
    );
  }
}

// ---------------- GARAGE ----------------

class GarageScreen extends StatelessWidget {
  final bool english;
  const GarageScreen({super.key, required this.english});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            english ? 'MY GARAGE' : 'گاراژ من',
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.directions_car_filled,
                  size: 65,
                  color: silver,
                ),
                const SizedBox(height: 15),
                Text(
                  english ? 'Your garage is ready' : 'گاراژ شما آماده است',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  english
                      ? 'Vehicle management will be available after connecting your account.'
                      : 'مدیریت خودروها پس از اتصال حساب کاربری فعال می‌شود.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          english
                              ? 'Vehicle registration requires account setup.'
                              : 'ثبت خودرو به راه‌اندازی حساب کاربری نیاز دارد.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: Text(english ? 'ADD VEHICLE' : 'افزودن خودرو'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- SETTINGS ----------------

class SettingsScreen extends StatelessWidget {
  final bool english;
  final bool haptics;
  final bool redline;
  final bool animations;
  final bool engineSound;
  final bool compact;
  final Future<void> Function(String, bool) onChange;

  const SettingsScreen({
    super.key,
    required this.english,
    required this.haptics,
    required this.redline,
    required this.animations,
    required this.engineSound,
    required this.compact,
    required this.onChange,
  });

  String t(String fa, String en) => english ? en : fa;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'CARACAL CONTROL CENTER',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          t('مرکز کنترل و شخصی‌سازی', 'Personalization & Controls'),
          style: const TextStyle(color: silver, fontSize: 12),
        ),
        const SizedBox(height: 20),
        _section(t('ظاهر و نمایش', 'DISPLAY & APPEARANCE')),
        _switch(
          t('افکت‌های حرکتی', 'Motion Effects'),
          t('فعال‌سازی انیمیشن‌ها', 'Enable animations'),
          animations,
          (v) => onChange('animations', v),
          Icons.animation,
        ),
        _switch(
          t('نور ردلاین', 'Redline Glow'),
          t('افکت نور قرمز دور موتور', 'RPM redline lighting'),
          redline,
          (v) => onChange('redline', v),
          Icons.brightness_high,
        ),
        _switch(
          t('داشبورد فشرده', 'Compact Dashboard'),
          t('نمایش فشرده‌تر اطلاعات', 'Use a compact dashboard'),
          compact,
          (v) => onChange('compact', v),
          Icons.dashboard_customize,
        ),
        const SizedBox(height: 12),
        _section(t('صدا و بازخورد', 'SOUND & FEEDBACK')),
        _switch(
          t('صدای موتور', 'Engine Sound'),
          t('تنظیم صدای موتور', 'Engine sound preference'),
          engineSound,
          (v) => onChange('engineSound', v),
          Icons.volume_up,
        ),
        _switch(
          t('بازخورد لمسی', 'Haptic Feedback'),
          t('لرزش هنگام لمس کنترل‌ها', 'Touch feedback'),
          haptics,
          (v) => onChange('haptics', v),
          Icons.vibration,
        ),
        const SizedBox(height: 12),
        _section(t('زبان برنامه', 'APP LANGUAGE')),
        ListTile(
          leading: const Icon(Icons.language, color: red),
          title: Text(t('زبان فارسی', 'Persian Language')),
          subtitle: Text(t('تغییر زبان برنامه', 'Change application language')),
          trailing: Switch(
            value: english,
            activeColor: red,
            onChanged: (v) => onChange('english', v),
          ),
        ),
        const SizedBox(height: 15),
        _section(t('حساب و امنیت', 'ACCOUNT & SECURITY')),
        ListTile(
          leading: const Icon(Icons.lock_outline, color: silver),
          title: Text(t('امنیت حساب', 'Account Security')),
          subtitle: Text(
            t('پس از راه‌اندازی سامانه حساب فعال می‌شود',
                'Available after account integration'),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.devices, color: silver),
          title: Text(t('دستگاه‌های متصل', 'Connected Devices')),
          subtitle: Text(
            t('مدیریت دستگاه‌ها پس از اتصال حساب',
                'Manage devices after account setup'),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              const SizedBox(
                width: 75,
                height: 65,
                child: CustomPaint(painter: CaracalPainter()),
              ),
              const SizedBox(height: 10),
              const Text(
                'CARACAL TUNING',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'DRIVE • LEARN • UPGRADE',
                style: TextStyle(
                  color: red,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: red,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _switch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: silver),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 10, color: Colors.white54),
      ),
      value: value,
      activeColor: red,
      onChanged: onChanged,
    );
  }
}
