import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

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
  bool animations = true;
  bool redline = true;
  bool haptics = true;
  int tab = 0;
  bool ready = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  void finishIntro() {
    if (mounted && !ready) setState(() => ready = true);
  }

  Future<void> loadSettings() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      english = p.getBool('english') ?? false;
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
          : IntroScreen(onFinished: finishIntro),
    );
  }
}

// INTRO — plays the uploaded cinematic MP4 (including its own soundtrack).

class IntroScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const IntroScreen({super.key, required this.onFinished});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  VideoPlayerController? _video;
  Timer? _fallbackTimer;
  bool _failed = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final controller = VideoPlayerController.asset('assets/images/intro.mp4');
      _video = controller;
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(false);
      await controller.setVolume(1.0);
      controller.addListener(_videoListener);
      await controller.play();
      setState(() {});
      // Safety fallback for devices/codecs that fail to report completion.
      final duration = controller.value.duration;
      _fallbackTimer = Timer(duration + const Duration(seconds: 2), _finish);
    } catch (e) {
      debugPrint('CARACAL intro video failed: $e');
      if (!mounted) return;
      setState(() => _failed = true);
      _fallbackTimer = Timer(const Duration(seconds: 3), _finish);
    }
  }

  void _videoListener() {
    final controller = _video;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.hasError) {
      debugPrint('CARACAL intro playback error: ${controller.value.errorDescription}');
      _finish();
    } else if (controller.value.isCompleted) {
      _finish();
    }
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    _fallbackTimer?.cancel();
    widget.onFinished();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _video?.removeListener(_videoListener);
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _video;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (controller != null && controller.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              )
            else
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [Color(0xFF292D33), Colors.black],
                  ),
                ),
              ),
            // Subtle dark footer keeps the brand readable without covering the clip.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 34, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE6000000)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/130315.png',
                      width: 76,
                      height: 62,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.directions_car_filled,
                        color: silver,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'CARACAL TUNING',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        shadows: [Shadow(color: Colors.black, blurRadius: 12)],
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'DRIVE • LEARN • UPGRADE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    if (_failed) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'CARACAL TUNING',
                        style: TextStyle(color: Colors.white54, fontSize: 9),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

class LearnScreen extends StatefulWidget {
  final bool english;
  const LearnScreen({super.key, required this.english});
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  List<Map<String, dynamic>> onlineLessons = [];
  bool loadingOnline = false;
  String? onlineError;
  bool get english => widget.english;
  String t(String fa, String en) => english ? en : fa;

  @override
  void initState() {
    super.initState();
    loadOnlineLessons();
  }

  Future<void> loadOnlineLessons() async {
    if (!supabaseConfigured) return;
    setState(() { loadingOnline = true; onlineError = null; });
    try {
      final rows = await Supabase.instance.client
          .from('lessons')
          .select('id,title,title_en,summary,summary_en,body,body_en,category,media_url,media_type,created_at')
          .eq('is_published', true)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() => onlineLessons = List<Map<String, dynamic>>.from(rows));
    } catch (e) {
      if (mounted) setState(() => onlineError = e.toString());
    } finally {
      if (mounted) setState(() => loadingOnline = false);
    }
  }

  void openOnlineLesson(Map<String, dynamic> lesson) {
    final title = (english ? lesson['title_en'] : lesson['title'])?.toString();
    final body = (english ? lesson['body_en'] : lesson['body'])?.toString();
    final mediaUrl = lesson['media_url']?.toString();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: panel,
        title: Text((title?.isNotEmpty == true ? title : lesson['title']?.toString()) ?? ''),
        content: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text((english ? lesson['summary_en'] : lesson['summary'])?.toString() ?? '', style: const TextStyle(color: silver)),
            const SizedBox(height: 12),
            Text(body?.isNotEmpty == true ? body! : (lesson['body']?.toString() ?? '')),
            if (mediaUrl != null && mediaUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              if (lesson['media_type'] == 'image') ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(mediaUrl, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Text(t('پیش‌نمایش تصویر در دسترس نیست.', 'Image preview unavailable.'))),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(mediaUrl);
                  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_new),
                label: Text(t('باز کردن فایل پیوست', 'Open attachment')),
              ),
            ],
          ],
        )),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('بستن', 'Close')))],
      ),
    );
  }

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
    return RefreshIndicator(
      color: red,
      onRefresh: loadOnlineLessons,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: [
          Row(children: [
            Expanded(child: Text(t('آموزش تخصصی', 'TECHNICAL ACADEMY'), style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900))),
            IconButton(onPressed: loadOnlineLessons, icon: const Icon(Icons.refresh, color: silver)),
          ]),
          const SizedBox(height: 7),
          Text(t('دانش فنی، از پایه تا پیشرفته', 'Automotive knowledge from basic to advanced'), style: const TextStyle(color: silver, fontSize: 12)),
          const SizedBox(height: 18),
          if (onlineLessons.isNotEmpty) ...[
            Text(t('مطالب جدید منتشرشده', 'NEW PUBLISHED CONTENT'), style: const TextStyle(color: red, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            for (final lesson in onlineLessons)
              FeatureTile(
                icon: Icons.auto_stories,
                title: ((english ? lesson['title_en'] : lesson['title'])?.toString().trim().isNotEmpty == true)
                    ? (english ? lesson['title_en'] : lesson['title']).toString()
                    : (lesson['title']?.toString() ?? ''),
                subtitle: ((english ? lesson['summary_en'] : lesson['summary'])?.toString() ?? ''),
                onTap: () => openOnlineLesson(lesson),
              ),
            const SizedBox(height: 14),
          ],
          if (loadingOnline) const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: red))),
          if (onlineError != null) Text(t('بارگذاری مطالب آنلاین انجام نشد: ', 'Could not load online content: ') + onlineError!, style: const TextStyle(color: Colors.orangeAccent, fontSize: 11)),
          Text(t('آموزش‌های پایه', 'CORE LESSONS'), style: const TextStyle(fontWeight: FontWeight.w900, color: silver)),
          const SizedBox(height: 10),
          for (final item in items)
            FeatureTile(
              icon: item[0] as IconData,
              title: t(item[1] as String, item[2] as String),
              subtitle: t('برای مشاهده و یادگیری انتخاب کنید', 'Tap to open this lesson'),
              onTap: () => showLesson(context, english, item[2] as String),
            ),
        ],
      ),
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
        if (role == 'owner' || role == 'admin') SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CaracalAdminScreen(english: en, isOwner: role == 'owner', permissions: Map<String, dynamic>.from(profile?['permissions'] as Map? ?? {})))), icon: const Icon(Icons.admin_panel_settings), label: Text(t('پنل مدیریت', 'ADMIN PANEL')))),
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
  final Map<String, dynamic> permissions;
  const CaracalAdminScreen({super.key, required this.english, required this.isOwner, required this.permissions});
  @override
  State<CaracalAdminScreen> createState() => _CaracalAdminScreenState();
}

class _CaracalAdminScreenState extends State<CaracalAdminScreen> {
  bool loading = true;
  String? message;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> lessons = [];
  final email = TextEditingController();
  bool manageContent = true;
  bool publishContent = false;
  bool manageUsers = false;
  SupabaseClient get client => Supabase.instance.client;
  String t(String fa, String en) => widget.english ? en : fa;
  bool get canManageContent => widget.isOwner || widget.permissions['manage_content'] == true;
  bool get canPublishContent => widget.isOwner || widget.permissions['publish_content'] == true;

  @override
  void initState() { super.initState(); load(); }
  @override
  void dispose() { email.dispose(); super.dispose(); }

  Future<void> load() async {
    if (mounted) setState(() { loading = true; message = null; });
    try {
      if (widget.isOwner) {
        final rows = await client.from('profiles').select('id,email,role,permissions,created_at').order('created_at', ascending: false);
        users = List<Map<String, dynamic>>.from(rows);
      }
      if (canManageContent) {
        final content = await client.from('lessons').select('id,title,title_en,summary,body,body_en,category,is_published,media_url,media_type,created_at').order('created_at', ascending: false);
        lessons = List<Map<String, dynamic>>.from(content);
      }
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) setState(() { message = e.toString(); loading = false; });
    }
  }

  Future<void> createAdmin() async {
    final address = email.text.trim();
    if (address.isEmpty || !address.contains('@')) { setState(() => message = t('ایمیل معتبر وارد کن.', 'Enter a valid email.')); return; }
    setState(() { loading = true; message = null; });
    try {
      final response = await client.functions.invoke('create-admin', body: {'email': address, 'permissions': {'manage_content': manageContent, 'publish_content': publishContent, 'manage_users': manageUsers}});
      if (response.status < 200 || response.status >= 300) throw Exception(response.data.toString());
      email.clear();
      if (mounted) setState(() => message = t('دعوت‌نامه مدیر ارسال شد.', 'Admin invitation sent.'));
      await load();
    } catch (e) { if (mounted) setState(() { message = e.toString(); loading = false; }); }
  }

  Future<void> saveAdminPermissions(String id, Map<String, dynamic> perms) async {
    try {
      await client.from('profiles').update({'permissions': perms}).eq('id', id).eq('role', 'admin');
      if (mounted) setState(() => message = t('دسترسی‌های مدیر ذخیره شد.', 'Administrator permissions saved.'));
      await load();
    } catch (e) { if (mounted) setState(() => message = e.toString()); }
  }

  Future<void> openLessonEditor({Map<String, dynamic>? lesson}) async {
    final title = TextEditingController(text: lesson?['title']?.toString() ?? '');
    final titleEn = TextEditingController(text: lesson?['title_en']?.toString() ?? '');
    final summary = TextEditingController(text: lesson?['summary']?.toString() ?? '');
    final summaryEn = TextEditingController(text: lesson?['summary_en']?.toString() ?? '');
    final body = TextEditingController(text: lesson?['body']?.toString() ?? '');
    final bodyEn = TextEditingController(text: lesson?['body_en']?.toString() ?? '');
    final category = TextEditingController(text: lesson?['category']?.toString() ?? 'general');
    String mediaType = lesson?['media_type']?.toString() ?? 'none';
    String? mediaUrl = lesson?['media_url']?.toString();
    bool published = lesson?['is_published'] == true;
    bool uploading = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(builder: (ctx, setDialogState) {
        Widget field(TextEditingController c, String label, {int lines = 1, bool required = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(controller: c, maxLines: lines, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
            onChanged: (_) {},),
        );
        return AlertDialog(
          backgroundColor: panel,
          title: Text(lesson == null ? t('افزودن مطلب جدید', 'ADD NEW CONTENT') : t('ویرایش مطلب', 'EDIT CONTENT')),
          content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            field(title, t('عنوان فارسی', 'Primary title')),
            field(titleEn, t('عنوان انگلیسی', 'English title')),
            field(summary, t('خلاصه مطلب', 'Summary'), lines: 2),
            field(summaryEn, t('خلاصه انگلیسی', 'English summary'), lines: 2),
            field(category, t('دسته‌بندی', 'Category')),
            field(body, t('متن کامل آموزش', 'Full lesson text'), lines: 5),
            field(bodyEn, t('متن انگلیسی آموزش', 'English lesson text'), lines: 5),
            DropdownButtonFormField<String>(value: mediaType, decoration: InputDecoration(labelText: t('نوع فایل پیوست', 'Attachment type'), border: const OutlineInputBorder()),
              items: [DropdownMenuItem(value: 'none', child: Text(t('بدون فایل', 'No attachment'))), DropdownMenuItem(value: 'image', child: Text(t('تصویر', 'Image'))), DropdownMenuItem(value: 'video', child: Text(t('ویدئو', 'Video'))), DropdownMenuItem(value: 'document', child: Text(t('فایل آموزشی', 'Document')))],
              onChanged: (v) => setDialogState(() => mediaType = v ?? 'none')),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: uploading ? null : () async {
                try {
                  final result = await FilePicker.platform.pickFiles(withData: true, type: FileType.any);
                  if (result == null || result.files.single.bytes == null) return;
                  final file = result.files.single;
                  final ext = (file.extension ?? 'bin').toLowerCase();
                  final path = '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
                  setDialogState(() => uploading = true);
                  final contentType = _mediaContentType(ext);
                  await client.storage.from('lesson-media').uploadBinary(path, file.bytes!, fileOptions: FileOptions(contentType: contentType, upsert: true));
                  mediaUrl = client.storage.from('lesson-media').getPublicUrl(path);
                  if (mediaType == 'none') mediaType = _guessMediaType(ext);
                  setDialogState(() => uploading = false);
                } catch (e) {
                  setDialogState(() => uploading = false);
                  if (mounted) setState(() => message = '${t('بارگذاری فایل ناموفق بود: ', 'File upload failed: ')}$e');
                }
              },
              icon: uploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload_file),
              label: Text(uploading ? t('در حال بارگذاری...', 'Uploading...') : t('انتخاب و بارگذاری فایل', 'Choose and upload file')),
            ),
            if (mediaUrl != null && mediaUrl!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: SelectableText(mediaUrl!, style: const TextStyle(color: silver, fontSize: 10))),
            if (canPublishContent) SwitchListTile(contentPadding: EdgeInsets.zero, value: published, activeColor: red, title: Text(t('انتشار مطلب', 'Publish content')), onChanged: (v) => setDialogState(() => published = v)),
            if (!canPublishContent) Padding(padding: const EdgeInsets.only(top: 8), child: Text(t('این حساب فقط می‌تواند پیش‌نویس ذخیره کند؛ انتشار نیازمند مجوز Owner است.', 'This account can save drafts only; publishing requires permission.'), style: const TextStyle(color: Colors.orangeAccent, fontSize: 11))),
          ]))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t('انصراف', 'Cancel'))),
            FilledButton(onPressed: uploading ? null : () async {
              if (title.text.trim().isEmpty || body.text.trim().isEmpty) {
                setDialogState(() {});
                setState(() => message = t('عنوان و متن آموزش الزامی است.', 'Title and lesson body are required.'));
                return;
              }
              if (published && !canPublishContent) return;
              try {
                final values = {
                  'title': title.text.trim(), 'title_en': titleEn.text.trim(),
                  'summary': summary.text.trim(), 'summary_en': summaryEn.text.trim(),
                  'body': body.text.trim(), 'body_en': bodyEn.text.trim(),
                  'category': category.text.trim().isEmpty ? 'general' : category.text.trim(),
                  'media_url': mediaUrl, 'media_type': mediaType,
                  'is_published': published,
                };
                if (lesson == null) {
                  values['created_by'] = client.auth.currentUser!.id;
                  await client.from('lessons').insert(values);
                } else {
                  await client.from('lessons').update(values).eq('id', lesson['id']);
                }
                if (mounted) Navigator.pop(dialogContext);
                await load();
              } catch (e) {
                if (mounted) setState(() => message = e.toString());
              }
            }, child: Text(t('ذخیره مطلب', 'SAVE CONTENT'))),
          ],
        );
      }),
    );
    title.dispose(); titleEn.dispose(); summary.dispose(); summaryEn.dispose(); body.dispose(); bodyEn.dispose(); category.dispose();
  }

  Future<void> deleteLesson(Map<String, dynamic> lesson) async {
    try {
      await client.from('lessons').delete().eq('id', lesson['id']);
      await load();
    } catch (e) { if (mounted) setState(() => message = e.toString()); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg,
    appBar: AppBar(backgroundColor: bg, title: Text(t('پنل مدیریت کاراکال', 'CARACAL ADMIN')), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: red.withOpacity(.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: red.withOpacity(.4))), child: Text(widget.isOwner ? t('OWNER — مالک اصلی و مرجع نهایی اختیار است. فقط Owner می‌تواند مدیر بسازد و سطح دسترسی مدیران را تغییر دهد.', 'OWNER — The root account has final authority. Only the Owner can create administrators and change their permissions.') : t('ADMIN — دسترسی این حساب فقط بر اساس مجوزهایی است که مالک تعیین کرده است.', 'ADMIN — This account is limited to permissions assigned by the Owner.'), style: const TextStyle(fontSize: 12))),
      const SizedBox(height: 14),
      if (widget.isOwner) Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(t('دعوت مدیر جدید', 'INVITE NEW ADMIN'), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: t('ایمیل مدیر', 'Admin email'), border: const OutlineInputBorder())),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: manageContent, onChanged: (v) => setState(() => manageContent = v ?? false), title: Text(t('مدیریت محتوا', 'Manage content'))),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: publishContent, onChanged: (v) => setState(() => publishContent = v ?? false), title: Text(t('انتشار محتوا', 'Publish content'))),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: manageUsers, onChanged: (v) => setState(() => manageUsers = v ?? false), title: Text(t('مدیریت کاربران', 'Manage users'))),
        FilledButton(onPressed: loading ? null : createAdmin, child: Text(t('ارسال دعوت‌نامه', 'SEND INVITATION'))),
      ])),
      if (widget.isOwner) const SizedBox(height: 18),
      if (widget.isOwner) Text(t('مدیریت مدیران و دسترسی‌ها', 'ADMINISTRATORS & PERMISSIONS'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      if (widget.isOwner) ...users.where((u) => u['role'] == 'owner' || u['role'] == 'admin').map((u) => _AdminPermissionTile(user: u, english: widget.english, onSave: (perms) => saveAdminPermissions(u['id'].toString(), perms))),
      if (canManageContent) ...[
        const SizedBox(height: 22),
        Row(children: [Expanded(child: Text(t('مدیریت مطالب آموزشی', 'LEARNING CONTENT MANAGER'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))), IconButton(onPressed: () => openLessonEditor(), icon: const Icon(Icons.add_circle, color: red, size: 30))]),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => openLessonEditor(), icon: const Icon(Icons.post_add), label: Text(t('افزودن مطلب جدید', 'ADD NEW CONTENT')))),
        const SizedBox(height: 10),
        if (lessons.isEmpty) Text(t('هنوز مطلبی ثبت نشده است.', 'No content has been added yet.'), style: const TextStyle(color: silver)),
        ...lessons.map((lesson) => Card(color: panel, child: ListTile(
          leading: Icon(lesson['is_published'] == true ? Icons.public : Icons.edit_note, color: lesson['is_published'] == true ? Colors.greenAccent : silver),
          title: Text(lesson['title']?.toString() ?? ''),
          subtitle: Text('${lesson['category'] ?? 'general'} • ${lesson['is_published'] == true ? t('منتشرشده', 'Published') : t('پیش‌نویس', 'Draft')}'),
          trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') openLessonEditor(lesson: lesson); if (v == 'delete') deleteLesson(lesson); }, itemBuilder: (_) => [PopupMenuItem(value: 'edit', child: Text(t('ویرایش', 'Edit'))), PopupMenuItem(value: 'delete', child: Text(t('حذف', 'Delete')))]),
          onTap: () => openLessonEditor(lesson: lesson),
        ))),
      ],
      if (loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: red))),
      if (message != null) Padding(padding: const EdgeInsets.all(12), child: SelectableText(message!, style: const TextStyle(color: silver))),
    ]),
  );
}

class _AdminPermissionTile extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool english;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _AdminPermissionTile({required this.user, required this.english, required this.onSave});
  @override
  State<_AdminPermissionTile> createState() => _AdminPermissionTileState();
}
class _AdminPermissionTileState extends State<_AdminPermissionTile> {
  late bool manageContent;
  late bool publishContent;
  late bool manageUsers;
  @override
  void initState() {
    super.initState();
    final p = widget.user['permissions'] as Map? ?? {};
    manageContent = p['manage_content'] == true;
    publishContent = p['publish_content'] == true;
    manageUsers = p['manage_users'] == true;
  }
  @override
  Widget build(BuildContext context) {
    final en = widget.english;
    return Card(color: panel, child: ExpansionTile(
      leading: Icon(widget.user['role'] == 'owner' ? Icons.shield : Icons.admin_panel_settings, color: widget.user['role'] == 'owner' ? red : silver),
      title: Text(widget.user['email']?.toString() ?? widget.user['id'].toString()),
      subtitle: Text((widget.user['role'] ?? '').toString().toUpperCase()),
      children: [
        if (widget.user['role'] == 'admin') ...[
          CheckboxListTile(value: manageContent, onChanged: (v) => setState(() => manageContent = v ?? false), title: Text(en ? 'Manage content' : 'مدیریت محتوا')),
          CheckboxListTile(value: publishContent, onChanged: (v) => setState(() => publishContent = v ?? false), title: Text(en ? 'Publish content' : 'انتشار محتوا')),
          CheckboxListTile(value: manageUsers, onChanged: (v) => setState(() => manageUsers = v ?? false), title: Text(en ? 'Manage users' : 'مدیریت کاربران')),
          Padding(padding: const EdgeInsets.all(12), child: FilledButton(onPressed: () => widget.onSave({'manage_content': manageContent, 'publish_content': publishContent, 'manage_users': manageUsers}), child: Text(en ? 'Save permissions' : 'ذخیره دسترسی‌ها'))),
        ] else Padding(padding: const EdgeInsets.all(12), child: Text(en ? 'Root owner account — protected role.' : 'حساب مالک اصلی — نقش محافظت‌شده.')),
      ],
    ));
  }
}

String _guessMediaType(String ext) {
  if (['jpg','jpeg','png','webp','gif'].contains(ext)) return 'image';
  if (['mp4','mov','webm','m4v'].contains(ext)) return 'video';
  return 'document';
}
String _mediaContentType(String ext) {
  const types = {'jpg':'image/jpeg','jpeg':'image/jpeg','png':'image/png','webp':'image/webp','gif':'image/gif','mp4':'video/mp4','mov':'video/quicktime','webm':'video/webm','pdf':'application/pdf','doc':'application/msword','docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document','zip':'application/zip'};
  return types[ext] ?? 'application/octet-stream';
}


// SETTINGS

class SettingsScreen extends StatelessWidget {
  final bool english;
  final bool animations;
  final bool redline;
  final bool haptics;
  final Future<void> Function(String, bool) onChange;

  const SettingsScreen({
    super.key,
    required this.english,
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
        section(t('بازخورد لمسی', 'HAPTIC FEEDBACK')),
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
