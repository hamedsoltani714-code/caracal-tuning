import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
bool supabaseConfigured = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      supabaseConfigured = true;
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
    }
  }
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
                      child: SizedBox(
                        width: 250,
                        height: 205,
                        child: Image.asset(
                          'assets/images/130315.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorBuilder: (context, error, stack) =>
                              const CustomPaint(painter: CaracalPainter()),
                        ),
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
            SizedBox(
              width: 58,
              height: 52,
              child: Image.asset(
                'assets/images/130315.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) =>
                    const CustomPaint(painter: CaracalPainter()),
              ),
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
              tooltip: t('اعلان‌ها', 'Notifications'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: panel,
                  title: Text(t('مرکز اعلان‌ها', 'Notification Center')),
                  content: Text(t(
                    'فعلاً اعلان جدیدی وجود ندارد. اعلان‌های آموزشی و به‌روزرسانی‌ها در این بخش نمایش داده می‌شوند.',
                    'There are no new notifications. Learning updates and app announcements will appear here.',
                  )),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(t('متوجه شدم', 'Got it')),
                    ),
                  ],
                ),
              ),
              icon: const Icon(Icons.notifications_none, color: silver),
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
          onTap: () => showLesson(context, english, 'Engine Architecture'),
        ),
        FeatureTile(
          icon: Icons.developer_board,
          title: t('آشنایی با ECU', 'Getting to Know ECU'),
          subtitle: t(
            'ساختار و وظایف واحد کنترل موتور',
            'Engine control unit architecture',
          ),
          onTap: () => showLesson(context, english, 'ECU Fundamentals'),
        ),
        FeatureTile(
          icon: Icons.analytics,
          title: t('مبانی تحلیل داده', 'Data Analysis Basics'),
          subtitle: t(
            'شناخت داده‌ها و پارامترهای خودرو',
            'Understanding vehicle data',
          ),
          onTap: () => showLesson(context, english, 'Parameter Analysis'),
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
  final VoidCallback? onTap;

  const FeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
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


void showLesson(BuildContext context, bool english, String title) {
  final Map<String, List<String>> lessons = {
    'ECU Fundamentals': [
      'واحد کنترل الکترونیکی (ECU) داده حسگرها را دریافت می‌کند و بر اساس نرم‌افزار و کالیبراسیون، عملگرهای موتور را مدیریت می‌کند.',
      'بخش‌های اصلی شامل ورودی حسگرها، پردازنده، حافظه، مدارهای خروجی و شبکه ارتباطی خودرو هستند.',
      'در بررسی ECU ابتدا کدهای خطا، داده زنده و شرایط ثبت خطا را با ابزار استاندارد بررسی کنید.'
    ],
    'Remapping Basics': [
      'ریمپ یعنی بازنگری کنترل‌شده در کالیبراسیون ECU با توجه به سخت‌افزار، سوخت، شرایط کار و محدودیت‌های ایمنی موتور.',
      'پیش از هر تغییر باید سلامت مکانیکی، خطاهای فعال و وضعیت حسگرها بررسی شود.',
      'هر تغییر باید مستند، قابل بازگشت و با پایش دما، فشار و ناک ارزیابی شود.'
    ],
    'Ignition System': [
      'سیستم جرقه وظیفه ایجاد جرقه در زمان مناسب برای احتراق مخلوط هوا و سوخت را دارد.',
      'شمع، کوئل، سیم‌کشی و فرمان ECU از اجزای مهم این سامانه هستند.',
      'عیب‌یابی باید با بررسی خطاها و آزمون‌های استاندارد انجام شود.'
    ],
    'Fuel System': [
      'سامانه سوخت‌رسانی سوخت را با فشار و مقدار کنترل‌شده به موتور می‌رساند.',
      'پمپ، فیلتر، ریل سوخت، انژکتورها و حسگرهای مرتبط از اجزای اصلی هستند.',
      'فشار و ترکیب سوخت باید مطابق مشخصات سازنده بررسی شود.'
    ],
    'Parameter Analysis': [
      'داده زنده کمک می‌کند وضعیت موتور در شرایط واقعی کار بررسی شود.',
      'پارامترهایی مانند دمای آب، دمای هوای ورودی، فشار منیفولد، اصلاح سوخت و دور موتور باید در کنار هم تحلیل شوند.',
      'مقادیر را با مشخصات سازنده و شرایط ثبت داده مقایسه کنید؛ یک عدد به‌تنهایی نتیجه قطعی نمی‌دهد.'
    ],
    'Vehicle Diagnostics': [
      'عیب‌یابی اصولی با ثبت شکایت، بررسی ظاهری و خواندن کدهای خطا آغاز می‌شود.',
      'کد خطا سرنخ است و لزوماً به معنی خرابی قطعه‌ای که نام برده شده نیست.',
      'پس از آزمون علت ریشه‌ای، تعمیر و پاک‌کردن خطا، نتیجه باید دوباره بررسی شود.'
    ],
    'Engine Architecture': [
      'موتور از سامانه‌های مکانیکی، روانکاری، خنک‌کاری، هوا و سوخت و کنترل الکترونیکی تشکیل شده است.',
      'شناخت ارتباط این سامانه‌ها برای تحلیل عملکرد و عیب‌یابی ضروری است.',
      'همیشه مشخصات فنی همان کد موتور و دستورالعمل سازنده را مرجع قرار دهید.'
    ],
    'Engine Maps Basics': [
      'جداول کالیبراسیون رابطه ورودی‌هایی مانند دور موتور و بار را با یک فرمان یا هدف کنترلی مشخص می‌کنند.',
      'برای خواندن جدول باید محور‌ها، واحدها، مقیاس داده و شرایط فعال‌سازی آن را شناخت.',
      'تغییر جدول بدون شناخت منطق کنترلی و اعتبارسنجی می‌تواند به موتور آسیب بزند؛ آموزش و آزمون باید در محیط کنترل‌شده انجام شود.'
    ],
  };
  final points = lessons[title] ?? ['محتوای این درس به‌زودی تکمیل می‌شود.'];
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: panel,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < points.length; i++) ...[
                Text('${i + 1}. ${english ? _lessonEnglish(title, i) : points[i]}',
                    style: const TextStyle(height: 1.7, color: silver)),
                const SizedBox(height: 12),
              ],
              Text(english
                  ? 'Educational overview only. Follow manufacturer service data and qualified procedures.'
                  : 'این محتوا آموزشی است؛ برای تعمیر و تنظیم عملی از اطلاعات سازنده و روش‌های تخصصی معتبر استفاده کنید.',
                  style: const TextStyle(fontSize: 11, color: Colors.white54)),
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(english ? 'Close' : 'بستن'))],
    ),
  );
}

String _lessonEnglish(String title, int index) {
  const data = {
    'ECU Fundamentals': ['The ECU receives sensor data and manages engine actuators using its software and calibration.', 'Main sections include sensor inputs, processor, memory, output drivers and vehicle communication networks.', 'Begin diagnosis by checking fault codes, live data and the conditions in which the fault was recorded.'],
    'Remapping Basics': ['Remapping is a controlled review of ECU calibration based on hardware, fuel, operating conditions and engine safety limits.', 'Before changes, verify mechanical health, active faults and sensor condition.', 'Document every change, keep a recovery path and validate while monitoring temperature, pressure and knock.'],
    'Ignition System': ['The ignition system creates a spark at the correct time to ignite the air-fuel mixture.', 'Spark plugs, coils, wiring and ECU commands are key components.', 'Use standard tests and fault data when diagnosing the system.'],
    'Fuel System': ['The fuel system delivers a controlled amount of fuel at the required pressure.', 'The pump, filter, rail, injectors and related sensors are key components.', 'Check pressure and fuel quality against manufacturer specifications.'],
    'Parameter Analysis': ['Live data helps evaluate engine operation under real conditions.', 'Coolant temperature, intake air temperature, manifold pressure, fuel trims and RPM should be considered together.', 'Compare readings with manufacturer specifications and recording conditions; one value alone is not conclusive.'],
    'Vehicle Diagnostics': ['A sound diagnostic process begins with the reported symptom, a visual check and fault-code retrieval.', 'A fault code is a clue, not proof that the named component has failed.', 'After identifying the root cause and repair, verify the result again.'],
    'Engine Architecture': ['An engine combines mechanical, lubrication, cooling, air, fuel and electronic control systems.', 'Understanding how these systems interact is essential for performance analysis and diagnosis.', 'Use specifications for the exact engine code and manufacturer procedures.'],
    'Engine Maps Basics': ['Calibration maps relate inputs such as engine speed and load to a control command or target.', 'To interpret a map, identify its axes, units, data scaling and activation conditions.', 'Changing a map without understanding control logic and validation can damage an engine.'],
  };
  return (data[title] ?? ['This lesson will be expanded soon.'])[index];
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
              'Tap to open this lesson',
            ),
            onTap: () => showLesson(
              context,
              english,
              item[2] as String,
            ),
          ),
      ],
    );
  }
}

// GARAGE / ACCOUNT / ADMIN
class GarageScreen extends StatefulWidget {
  final bool english;
  const GarageScreen({super.key, required this.english});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final vehicleController = TextEditingController();
  bool busy = false;
  bool signUp = false;
  String? error;
  List<Map<String, dynamic>> vehicles = [];
  Map<String, dynamic>? profile;

  bool get en => widget.english;
  String t(String fa, String english) => en ? english : fa;
  bool get configured => supabaseConfigured;
  SupabaseClient get client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (configured && client.auth.currentUser != null) loadAccount();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    vehicleController.dispose();
    super.dispose();
  }

  Future<void> runBusy(Future<void> Function() action) async {
    setState(() { busy = true; error = null; });
    try { await action(); }
    catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> authenticate() => runBusy(() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.length < 6) {
      throw Exception(t('ایمیل و گذرواژه حداقل ۶ کاراکتری را وارد کن.', 'Enter an email and a password of at least 6 characters.'));
    }
    if (signUp) {
      await client.auth.signUp(email: email, password: password);
    } else {
      await client.auth.signInWithPassword(email: email, password: password);
    }
    await loadAccount();
  });

  Future<void> loadAccount() async {
    final user = client.auth.currentUser;
    if (user == null) return;
    final p = await client.from('profiles').select().eq('id', user.id).maybeSingle();
    final v = await client.from('vehicles').select().eq('user_id', user.id).order('created_at', ascending: false);
    if (!mounted) return;
    setState(() {
      profile = p;
      vehicles = List<Map<String, dynamic>>.from(v);
    });
  }

  Future<void> addVehicle() async {
    final name = vehicleController.text.trim();
    if (name.isEmpty) return;
    await runBusy(() async {
      await client.from('vehicles').insert({'name': name});
      vehicleController.clear();
      await loadAccount();
    });
  }

  Future<void> signOut() async {
    await runBusy(() async {
      await client.auth.signOut();
      if (mounted) setState(() { profile = null; vehicles = []; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(t('گاراژ و حساب کاربری', 'GARAGE & ACCOUNT'), style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        if (!configured) _configurationNotice() else if (client.auth.currentUser == null) _authCard() else _accountCard(),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.redAccent))),
        if (busy) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: red))),
      ],
    );
  }

  Widget _configurationNotice() => _card(Column(children: [
    const Icon(Icons.cloud_off, color: silver, size: 48),
    const SizedBox(height: 12),
    Text(t('اتصال سرور هنوز تنظیم نشده', 'Backend is not configured'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    const SizedBox(height: 8),
    Text(t('برای فعال شدن ورود، گاراژ آنلاین و مدیریت مدیران، آدرس پروژه و کلید عمومی Supabase باید هنگام بیلد تنظیم شود.', 'Set the Supabase project URL and public anon key at build time to enable authentication, cloud garage and admin management.'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 12)),
  ]));

  Widget _authCard() => _card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Icon(Icons.account_circle_outlined, color: silver, size: 54),
    const SizedBox(height: 12),
    Text(signUp ? t('ساخت حساب کاربری', 'Create account') : t('ورود به کاراکال', 'Sign in to CARACAL'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
    const SizedBox(height: 16),
    TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: t('ایمیل', 'Email'), border: const OutlineInputBorder())),
    const SizedBox(height: 12),
    TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(labelText: t('گذرواژه (حداقل ۶ کاراکتر)', 'Password (6+ characters)'), border: const OutlineInputBorder())),
    const SizedBox(height: 14),
    FilledButton(onPressed: busy ? null : authenticate, child: Text(signUp ? t('ثبت‌نام', 'CREATE ACCOUNT') : t('ورود', 'SIGN IN'))),
    TextButton(onPressed: busy ? null : () => setState(() { signUp = !signUp; error = null; }), child: Text(signUp ? t('قبلاً حساب دارم؛ ورود', 'I already have an account') : t('حساب ندارم؛ ثبت‌نام', 'Create a new account'))),
  ]));

  Widget _accountCard() {
    final user = client.auth.currentUser!;
    final role = profile?['role']?.toString() ?? 'user';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _card(Column(children: [
        const Icon(Icons.verified_user_outlined, size: 48, color: silver),
        const SizedBox(height: 8),
        Text(user.email ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(t('سطح دسترسی: ', 'Role: ') + role.toUpperCase(), style: const TextStyle(color: red, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (role == 'owner' || role == 'admin') SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CaracalAdminScreen(english: en, isOwner: role == 'owner'))), icon: const Icon(Icons.admin_panel_settings), label: Text(t('پنل مدیریت', 'ADMIN PANEL')))),
        SizedBox(width: double.infinity, child: TextButton.icon(onPressed: signOut, icon: const Icon(Icons.logout), label: Text(t('خروج از حساب', 'SIGN OUT')))),
      ])),
      const SizedBox(height: 18),
      Text(t('خودروهای من', 'MY VEHICLES'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 10),
      _card(Column(children: [
        TextField(controller: vehicleController, decoration: InputDecoration(labelText: t('نام خودرو (مثلاً پژو ۲۰۶)', 'Vehicle name (e.g. Peugeot 206)'), border: const OutlineInputBorder(), suffixIcon: IconButton(onPressed: busy ? null : addVehicle, icon: const Icon(Icons.add, color: red)))),
        const SizedBox(height: 8),
        if (vehicles.isEmpty) Text(t('هنوز خودرویی ثبت نکرده‌ای.', 'No vehicles added yet.'), style: const TextStyle(color: Colors.white54)) else ...vehicles.map((v) => ListTile(leading: const Icon(Icons.directions_car, color: silver), title: Text(v['name']?.toString() ?? ''), trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => runBusy(() async { await client.from('vehicles').delete().eq('id', v['id']); await loadAccount(); })))),
      ])),
    ]);
  }

  Widget _card(Widget child) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)), child: child);
}

class CaracalAdminScreen extends StatefulWidget {
  final bool english;
  final bool isOwner;
  const CaracalAdminScreen({super.key, required this.english, required this.isOwner});
  @override
  State<CaracalAdminScreen> createState() => _CaracalAdminScreenState();
}

class _CaracalAdminScreenState extends State<CaracalAdminScreen> {
  bool loading = true;
  String? message;
  List<Map<String, dynamic>> users = [];
  final email = TextEditingController();
  bool manageContent = true;
  bool publishContent = false;
  bool manageUsers = false;
  SupabaseClient get client => Supabase.instance.client;
  String t(String fa, String en) => widget.english ? en : fa;

  @override
  void initState() { super.initState(); load(); }
  @override
  void dispose() { email.dispose(); super.dispose(); }

  Future<void> load() async {
    try {
      final rows = await client.from('profiles').select('id,email,role,permissions,created_at').order('created_at', ascending: false);
      if (mounted) setState(() { users = List<Map<String, dynamic>>.from(rows); loading = false; });
    } catch (e) { if (mounted) setState(() { message = e.toString(); loading = false; }); }
  }

  Future<void> createAdmin() async {
    final address = email.text.trim();
    if (address.isEmpty || !address.contains('@')) { setState(() => message = t('ایمیل معتبر وارد کن.', 'Enter a valid email.')); return; }
    setState(() { loading = true; message = null; });
    try {
      final response = await client.functions.invoke('create-admin', body: {'email': address, 'permissions': {'manage_content': manageContent, 'publish_content': publishContent, 'manage_users': manageUsers}});
      if (response.status < 200 || response.status >= 300) throw Exception(response.data.toString());
      email.clear();
      message = t('دعوت‌نامه مدیر ارسال شد.', 'Admin invitation sent.');
      await load();
    } catch (e) { if (mounted) setState(() { message = e.toString(); loading = false; }); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg,
    appBar: AppBar(backgroundColor: bg, title: Text(t('پنل مدیریت کاراکال', 'CARACAL ADMIN'))),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      if (widget.isOwner) Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: red.withOpacity(.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: red.withOpacity(.4))), child: Text(t('حساب مالک اصلی: اختیار نهایی مدیریت مدیران و دسترسی‌ها فقط با مالک است.', 'Owner account: only the owner has final authority over administrators and permissions.'), style: const TextStyle(fontSize: 12))),
      if (widget.isOwner) const SizedBox(height: 14),
      if (widget.isOwner) Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(t('افزودن مدیر جدید', 'INVITE NEW ADMIN'), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: t('ایمیل مدیر', 'Admin email'), border: const OutlineInputBorder())),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: manageContent, onChanged: (v) => setState(() => manageContent = v ?? false), title: Text(t('مدیریت محتوا', 'Manage content'))),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: publishContent, onChanged: (v) => setState(() => publishContent = v ?? false), title: Text(t('انتشار محتوا', 'Publish content'))),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: manageUsers, onChanged: (v) => setState(() => manageUsers = v ?? false), title: Text(t('مدیریت کاربران', 'Manage users'))),
        FilledButton(onPressed: loading ? null : createAdmin, child: Text(t('ارسال دعوت‌نامه', 'SEND INVITATION'))),
      ])),
      const SizedBox(height: 18),
      Text(t('کاربران و مدیران', 'USERS & ADMINS'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      if (loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: red))),
      ...users.map((u) => Card(color: panel, child: ListTile(leading: Icon(u['role'] == 'owner' ? Icons.shield : u['role'] == 'admin' ? Icons.admin_panel_settings : Icons.person, color: u['role'] == 'owner' ? red : silver), title: Text(u['email']?.toString() ?? u['id'].toString()), subtitle: Text((u['role'] ?? 'user').toString().toUpperCase() + (u['role'] == 'admin' ? ' • ${(u['permissions'] as Map? ?? {}).entries.where((e) => e.value == true).map((e) => e.key).join(', ')}' : ''))))),
      if (message != null) Padding(padding: const EdgeInsets.all(12), child: Text(message!, style: const TextStyle(color: silver))),
    ]),
  );
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
