import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

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
  bool engineSound = true;
  bool animations = true;
  bool redline = true;
  bool haptics = true;
  int tab = 0;
  bool ready = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
    Future.delayed(const Duration(milliseconds: 4200), () {
      if (mounted) setState(() => ready = true);
    });
  }

  Future<void> loadSettings() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      english = p.getBool('english') ?? false;
      engineSound = p.getBool('engineSound') ?? true;
      animations = p.getBool('animations') ?? true;
      redline = p.getBool('redline') ?? true;
      haptics = p.getBool('haptics') ?? true;
    });
  }

  Future<void> save(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
    if (!mounted) return;
    setState(() {
      switch (key) {
        case 'english':
          english = value;
          break;
        case 'engineSound':
          engineSound = value;
          break;
        case 'animations':
          animations = value;
          break;
        case 'redline':
          redline = value;
          break;
        case 'haptics':
          haptics = value;
          break;
      }
    });
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
        useMaterial3: true,
      ),
      home: ready
          ? Directionality(
              textDirection:
                  english ? TextDirection.ltr : TextDirection.rtl,
              child: Scaffold(
                body: SafeArea(
                  child: IndexedStack(
                    index: tab,
                    children: [
                      HomeScreen(
                        english: english,
                        redline: redline,
                        animations: animations,
                        onNavigate: (i) => setState(() => tab = i),
                      ),
                      LearnScreen(english: english),
                      GarageScreen(english: english),
                      SettingsScreen(
                        english: english,
                        engineSound: engineSound,
                        animations: animations,
                        redline: redline,
                        haptics: haptics,
                        onChange: save,
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: NavigationBar(
                  backgroundColor: const Color(0xFF101114),
                  indicatorColor: red.withOpacity(.2),
                  selectedIndex: tab,
                  onDestinationSelected: (i) {
                    if (haptics) HapticFeedback.selectionClick();
                    setState(() => tab = i);
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
                      selectedIcon:
                          const Icon(Icons.directions_car, color: red),
                      label: t('گاراژ', 'Garage'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.tune_outlined),
                      selectedIcon: const Icon(Icons.tune, color: red),
                      label: t('تنظیمات', 'Settings'),
                    ),
                  ],
                ),
              ),
            )
          : IntroScreen(engineSound: engineSound),
    );
  }
}

// INTRO

class IntroScreen extends StatefulWidget {
  final bool engineSound;

  const IntroScreen({super.key, required this.engineSound});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  final AudioPlayer enginePlayer = AudioPlayer();
  final AudioPlayer roarPlayer = AudioPlayer();
  Timer? roarTimer;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..forward();

    if (widget.engineSound) {
      playIntroSounds();
    }
  }

  Future<void> playIntroSounds() async {
    try {
      await enginePlayer.setVolume(1);
      await roarPlayer.setVolume(1);

      await enginePlayer.play(
        AssetSource('Pagani-Zonda (2).mp3'),
      );

      roarTimer = Timer(
        const Duration(milliseconds: 1700),
        () async {
          if (!mounted) return;
          try {
            await roarPlayer.play(
              AssetSource('Caracal (1).mp3'),
            );
          } catch (_) {}
        },
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    roarTimer?.cancel();
    enginePlayer.dispose();
    roarPlayer.dispose();
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
                  painter: IntroBackground(progress: v),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: .55 + v * .45,
                    child: Opacity(
                      opacity: v.clamp(0.0, 1.0),
                      child: const SizedBox(
                        width: 260,
                        height: 210,
                        child: CustomPaint(painter: CaracalPainter()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'CARACAL',
                    style: TextStyle(
                      fontSize: 39,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      color: silver.withOpacity(v),
                    ),
                  ),
                  const Text(
                    'T U N I N G',
                    style: TextStyle(
                      color: red,
                      fontSize: 15,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: 310,
                    height: 165,
                    child: AnimatedGauge(
                      redline: true,
                      animations: true,
                      intro: true,
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: 230,
                    height: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: v,
                        backgroundColor: Colors.white12,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'DRIVE • LEARN • UPGRADE',
                    style: TextStyle(
                      color: Colors.white54,
                      letterSpacing: 2,
                      fontSize: 10,
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

class IntroBackground extends CustomPainter {
  final double progress;
  IntroBackground({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = red.withOpacity(.13)
      ..strokeWidth = 1;

    for (int i = 0; i < 18; i++) {
      final y = size.height * i / 18;
      canvas.drawLine(
        Offset(0, y + progress * 35),
        Offset(size.width, y - progress * 35),
        line,
      );
    }

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          red.withOpacity(.2),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width * .8,
        ),
      );

    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant IntroBackground oldDelegate) => true;
}

// HOME

class HomeScreen extends StatelessWidget {
  final bool english;
  final bool redline;
  final bool animations;
  final ValueChanged<int> onNavigate;

  const HomeScreen({
    super.key,
    required this.english,
    required this.redline,
    required this.animations,
    required this.onNavigate,
  });

  String t(String fa, String en) => english ? en : fa;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            const SizedBox(
              width: 58,
              height: 52,
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
              icon: const Icon(
                Icons.notifications_none,
                color: silver,
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(20),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.bolt, color: red, size: 27),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: AnimatedGauge(
                  redline: redline,
                  animations: animations,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                t(
                  'قدرت را بشناس؛ دقیق‌تر تنظیم کن',
                  'Understand power. Tune smarter.',
                ),
                style: const TextStyle(color: silver, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Text(
          t('دسترسی سریع', 'QUICK ACCESS'),
          style: const TextStyle(
            fontSize: 17,
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
          childAspectRatio: 1.45,
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
              subtitle: t('تنظیمات برنامه', 'App settings'),
              onTap: () => onNavigate(3),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Text(
          t('موضوعات منتخب', 'FEATURED TOPICS'),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        FeatureTile(
          icon: Icons.speed,
          title: t('اصول عملکرد موتور', 'Engine Fundamentals'),
          subtitle: t(
            'آشنایی با پارامترهای اصلی موتور',
            'Understanding core engine parameters',
          ),
        ),
        FeatureTile(
          icon: Icons.developer_board,
          title: t('آشنایی با ECU', 'Getting to Know ECU'),
          subtitle: t(
            'ساختار و وظایف واحد کنترل موتور',
            'Engine control unit architecture',
          ),
        ),
        FeatureTile(
          icon: Icons.analytics,
          title: t('مبانی تحلیل داده', 'Data Analysis Basics'),
          subtitle: t(
            'شناخت داده‌ها و پارامترهای خودرو',
            'Understanding vehicle data',
          ),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: red, size: 27),
            const SizedBox(height: 10),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: red, size: 27),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
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

// RPM GAUGE

class AnimatedGauge extends StatefulWidget {
  final bool redline;
  final bool animations;
  final bool intro;

  const AnimatedGauge({
    super.key,
    required this.redline,
    required this.animations,
    this.intro = false,
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
      duration: Duration(
        milliseconds: widget.intro ? 4000 : 3200,
      ),
    );

    rpm = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 500,
          end: 8000,
        ).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 72,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 8000,
          end: 900,
        ).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 28,
      ),
    ]).animate(controller);

    if (widget.animations || widget.intro) {
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

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      rect,
      start,
      sweep * (value / 8000).clamp(0.0, 1.0),
      false,
      Paint()
        ..shader = const SweepGradient(
          colors: [
            silver,
            Colors.white,
            red,
          ],
          stops: [0, .72, 1],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    if (redline && value > 6500) {
      canvas.drawArc(
        rect,
        start + sweep * .78,
        sweep * .22,
        false,
        Paint()
          ..color = red.withOpacity(.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 24
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            13,
          ),
      );
    }

    for (int i = 0; i <= 40; i++) {
      final angle = start + sweep * i / 40;

      final outer = Offset(
        center.dx + math.cos(angle) * (radius + 12),
        center.dy + math.sin(angle) * (radius + 12),
      );

      final inner = Offset(
        center.dx +
            math.cos(angle) *
                (radius - (i % 5 == 0 ? 13 : 6)),
        center.dy +
            math.sin(angle) *
                (radius - (i % 5 == 0 ? 13 : 6)),
      );

      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = i >= 34 && redline
              ? red
              : silver.withOpacity(.75)
          ..strokeWidth = i % 5 == 0 ? 2.5 : 1.3,
      );
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

      tp.paint(
        canvas,
        pos - Offset(tp.width / 2, tp.height / 2),
      );
    }

    final needleAngle =
        start + sweep * (value / 8000).clamp(0.0, 1.0);

    final needleEnd = Offset(
      center.dx + math.cos(needleAngle) * (radius - 22),
      center.dy + math.sin(needleAngle) * (radius - 22),
    );

    if (redline && value > 6000) {
      canvas.drawLine(
        center,
        needleEnd,
        Paint()
          ..color = red.withOpacity(.45)
          ..strokeWidth = 22
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            15,
          ),
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
      11,
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
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    valueText.paint(
      canvas,
      Offset(
        center.dx - valueText.width / 2,
        center.dy - 48,
      ),
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
      Offset(
        center.dx - unit.width / 2,
        center.dy - 15,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.redline != redline;
  }
}

// CARACAL LOGO

class CaracalPainter extends CustomPainter {
  const CaracalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 220, size.height / 180);

    final metal = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white,
          Color(0xFF9EA5AD),
          Color(0xFF353A40),
        ],
      ).createShader(
        const Rect.fromLTWH(0, 0, 220, 180),
      );

    final dark = Paint()
      ..color = const Color(0xFF171A1E);

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

    final leftEar = Path()
      ..moveTo(39, 18)
      ..lineTo(67, 42)
      ..lineTo(53, 76)
      ..close();

    final rightEar = Path()
      ..moveTo(181, 18)
      ..lineTo(153, 42)
      ..lineTo(167, 76)
      ..close();

    canvas.drawPath(leftEar, dark);
    canvas.drawPath(rightEar, dark);

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

    canvas.drawLine(
      const Offset(110, 134),
      const Offset(110, 148),
      mouth,
    );

    canvas.drawLine(
      const Offset(110, 148),
      const Offset(88, 140),
      mouth,
    );

    canvas.drawLine(
      const Offset(110, 148),
      const Offset(132, 140),
      mouth,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CaracalPainter oldDelegate) => false;
}

// LEARN

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
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          t(
            'دانش فنی، از پایه تا پیشرفته',
            'Automotive knowledge from basic to advanced',
          ),
          style: const TextStyle(
            color: silver,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 20),
        for (final item in items)
          FeatureTile(
            icon: item[0] as IconData,
            title: t(item[1] as String, item[2] as String),
            subtitle: t(
              'برای مشاهده و یادگیری انتخاب کنید',
              'Select to explore this topic',
            ),
          ),
      ],
    );
  }
}

// GARAGE

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
                  english
                      ? 'Your garage is ready'
                      : 'گاراژ شما آماده است',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  english
                      ? 'Vehicle management will be available after account integration.'
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
                              ? 'Account setup is required.'
                              : 'ثبت خودرو به راه‌اندازی حساب نیاز دارد.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: Text(
                    english ? 'ADD VEHICLE' : 'افزودن خودرو',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// SETTINGS

class SettingsScreen extends StatelessWidget {
  final bool english;
  final bool engineSound;
  final bool animations;
  final bool redline;
  final bool haptics;
  final Future<void> Function(String, bool) onChange;

  const SettingsScreen({
    super.key,
    required this.english,
    required this.engineSound,
    required this.animations,
    required this.redline,
    required this.haptics,
    required this.onChange,
  });

  String t(String fa, String en) => english ? en : fa;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          'CARACAL CONTROL CENTER',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t('مرکز کنترل و شخصی‌سازی', 'Personalization & Controls'),
          style: const TextStyle(color: silver, fontSize: 12),
        ),
        const SizedBox(height: 20),
        section(t('ظاهر و نمایش', 'DISPLAY & APPEARANCE')),
        settingSwitch(
          t('افکت‌های حرکتی', 'Motion Effects'),
          t('فعال‌سازی انیمیشن‌ها', 'Enable animations'),
          animations,
          (v) => onChange('animations', v),
          Icons.animation,
        ),
        settingSwitch(
          t('نور ردلاین', 'Redline Glow'),
          t('افکت نور قرمز دور موتور', 'RPM redline lighting'),
          redline,
          (v) => onChange('redline', v),
          Icons.brightness_high,
        ),
        const SizedBox(height: 12),
        section(t('صدا و بازخورد', 'SOUND & FEEDBACK')),
        settingSwitch(
          t('صدای موتور و غرش کاراکال', 'Engine & Caracal Sound'),
          t('صدای آغاز برنامه', 'Intro sound effects'),
          engineSound,
          (v) => onChange('engineSound', v),
          Icons.volume_up,
        ),
        settingSwitch(
          t('بازخورد لمسی', 'Haptic Feedback'),
          t('لرزش هنگام لمس کنترل‌ها', 'Touch feedback'),
          haptics,
          (v) => onChange('haptics', v),
          Icons.vibration,
        ),
        const SizedBox(height: 12),
        section(t('زبان برنامه', 'APP LANGUAGE')),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.language, color: red),
          title: Text(t('زبان فارسی', 'English Language')),
          subtitle: Text(t('تغییر زبان برنامه', 'Change application language')),
          value: english,
          activeColor: red,
          onChanged: (v) => onChange('english', v),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              const SizedBox(
                width: 90,
                height: 75,
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

  Widget section(String title) {
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

  Widget settingSwitch(
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
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white54,
        ),
      ),
      value: value,
      activeColor: red,
      onChanged: onChanged,
    );
  }
}
