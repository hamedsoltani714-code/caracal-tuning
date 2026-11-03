import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'booking_admin_screens.dart';

// Public Supabase project configuration. Never place a service_role key in the app.
final String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://fabbzaviesndfobxhrxf.supabase.co',
).trim().replaceAll(RegExp(r'/+$'), '');

final String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZhYmJ6YXZpZXNuZGZvYnhocnhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTM1MzEyNjcsImV4cCI6MjEwOTEwNzI2N30.mwJfaLmV0dKso2dsXxX3gr2naFYqFEFtGi6Nw731RNk',
).trim();

bool supabaseConfigured = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final validUrl = Uri.tryParse(supabaseUrl);

  if (supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      validUrl != null &&
      validUrl.scheme == 'https' &&
      validUrl.host.isNotEmpty &&
      (validUrl.path.isEmpty || validUrl.path == '/')) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );

      supabaseConfigured = true;
      debugPrint('CARACAL: Supabase initialized.');
    } catch (e) {
      debugPrint('CARACAL SUPABASE ERROR: $e');
    }
  } else {
    debugPrint(
      'CARACAL: Supabase configuration is missing or invalid.',
    );
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
  bool introSound = true;
  int tab = 0;
  bool ready = false;
  bool settingsLoaded = false;

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
      introSound = p.getBool('introSound') ?? true;
      settingsLoaded = true;
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
        case 'introSound':
          introSound = value;
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
      home: !settingsLoaded
          ? const Scaffold(backgroundColor: Colors.black)
          : ready
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
                      BookingScreen(english: english),
                      SettingsScreen(
                        english: english,
                        animations: animations,
                        redline: redline,
                        haptics: haptics,
                        introSound: introSound,
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
                      icon: const Icon(Icons.calendar_month_outlined),
                      selectedIcon: const Icon(Icons.calendar_month, color: red),
                      label: t('نوبت‌دهی', 'Booking'),
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
          : IntroScreen(onFinished: finishIntro, soundEnabled: introSound),
    );
  }
}

// INTRO — plays the uploaded cinematic MP4 (including its own soundtrack).

class IntroScreen extends StatefulWidget {
  final VoidCallback onFinished;
  final bool soundEnabled;
  const IntroScreen({super.key, required this.onFinished, required this.soundEnabled});

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
    // Play the supplied intro video with its ORIGINAL embedded soundtrack.
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final controller = VideoPlayerController.asset('assets/Intro.mp4');
      _video = controller;
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(false);
      // Preserve the original audio track embedded in Intro.mp4.
      await controller.setVolume(widget.soundEnabled ? 1.0 : 0.0);
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
                      'assets/130315.png',
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
                'assets/130315.png',
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
                builder: (_) => NotificationCenterDialog(english: english),
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
              onTap: () => onNavigate(4),
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

  GaugePainter({required this.value, required this.redline});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final center = Offset(size.width / 2, size.height * .76);
    final radius = math.min(size.width * .405, size.height * .66);
    const start = math.pi * 1.12;
    const sweep = math.pi * .76;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final progress = (value / 9000).clamp(0.0, 1.0);
    final hot = redline && value >= 6500;

    // Dark instrument-panel halo and layered metallic bezels.
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [red.withOpacity(hot ? .16 : .055), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.55));
    canvas.drawCircle(center, radius * 1.55, halo);

    canvas.drawArc(rect.inflate(15), start, sweep, false,
      Paint()..color = Colors.white.withOpacity(.055)
        ..style = PaintingStyle.stroke..strokeWidth = 1.4);
    canvas.drawArc(rect.inflate(8), start, sweep, false,
      Paint()..color = const Color(0xFF68717C).withOpacity(.55)
        ..style = PaintingStyle.stroke..strokeWidth = 2.2);

    // Outer illuminated sweep.
    canvas.drawArc(rect, start, sweep, false,
      Paint()..color = Colors.white.withOpacity(.09)
        ..style = PaintingStyle.stroke..strokeWidth = 17
        ..strokeCap = StrokeCap.round);
    if (progress > .01) {
      canvas.drawArc(rect, start, sweep * progress, false,
        Paint()..color = red.withOpacity(.23)
          ..style = PaintingStyle.stroke..strokeWidth = 27
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
          ..strokeCap = StrokeCap.round);
      canvas.drawArc(rect, start, sweep * progress, false,
        Paint()..shader = const SweepGradient(
          colors: [Color(0xFF69727D), Colors.white, Color(0xFFFF3038)],
          stops: [0, .58, 1],
        ).createShader(rect)
          ..style = PaintingStyle.stroke..strokeWidth = 12
          ..strokeCap = StrokeCap.round);
    }

    // Fine ticks and major engraved marks.
    for (int i = 0; i <= 54; i++) {
      final angle = start + sweep * i / 54;
      final major = i % 6 == 0;
      final outerR = radius + (major ? 13 : 9);
      final innerR = radius - (major ? 12 : 4);
      final p1 = Offset(center.dx + math.cos(angle) * innerR,
          center.dy + math.sin(angle) * innerR);
      final p2 = Offset(center.dx + math.cos(angle) * outerR,
          center.dy + math.sin(angle) * outerR);
      final isHot = i >= 39 && redline;
      canvas.drawLine(p1, p2, Paint()
        ..color = isHot ? red.withOpacity(major ? 1 : .65) : silver.withOpacity(major ? .95 : .4)
        ..strokeWidth = major ? 2.4 : 1
        ..strokeCap = StrokeCap.round);
    }

    for (int i = 0; i <= 9; i++) {
      final angle = start + sweep * i / 9;
      final pos = Offset(center.dx + math.cos(angle) * (radius - 31),
          center.dy + math.sin(angle) * (radius - 31));
      final tp = TextPainter(
        text: TextSpan(text: '$i', style: TextStyle(
          color: i >= 7 && redline ? red : const Color(0xFFE0E4E8),
          fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .4)),
        textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // Center dial face.
    canvas.drawCircle(center, 40, Paint()..color = const Color(0xFF0C0E11));
    canvas.drawCircle(center, 40, Paint()
      ..color = Colors.white.withOpacity(.14)
      ..style = PaintingStyle.stroke..strokeWidth = 1);
    final rpmText = TextPainter(
      text: TextSpan(text: (value / 1000).toStringAsFixed(1),
        style: const TextStyle(color: Colors.white, fontSize: 28,
          fontWeight: FontWeight.w900, letterSpacing: -.8)),
      textDirection: TextDirection.ltr)..layout();
    rpmText.paint(canvas, Offset(center.dx - rpmText.width / 2, center.dy - 23));
    final unit = TextPainter(
      text: const TextSpan(text: 'x1000 RPM',
        style: TextStyle(color: silver, fontSize: 8, letterSpacing: 1.8,
          fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr)..layout();
    unit.paint(canvas, Offset(center.dx - unit.width / 2, center.dy + 9));

    // Needle with shadow, luminous edge and machined hub.
    final needleAngle = start + sweep * progress;
    final needleEnd = Offset(center.dx + math.cos(needleAngle) * (radius - 18),
        center.dy + math.sin(needleAngle) * (radius - 18));
    canvas.drawLine(center.translate(1.5, 2), needleEnd.translate(1.5, 2),
      Paint()..color = Colors.black.withOpacity(.8)..strokeWidth = 9
        ..strokeCap = StrokeCap.round);
    if (hot) {
      canvas.drawLine(center, needleEnd, Paint()..color = red.withOpacity(.6)
        ..strokeWidth = 18..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..strokeCap = StrokeCap.round);
    }
    canvas.drawLine(center, needleEnd, Paint()..color = const Color(0xFFFF3942)
      ..strokeWidth = 4.2..strokeCap = StrokeCap.round);
    canvas.drawCircle(center, 10, Paint()..shader = const RadialGradient(
      colors: [Color(0xFFE9EDF1), Color(0xFF565E68), Color(0xFF171A1E)],
    ).createShader(Rect.fromCircle(center: center, radius: 10)));
    canvas.drawCircle(center, 3.5, Paint()..color = red);

    // Small redline warning indicator.
    if (hot) {
      final pulse = .45 + .35 * (math.sin(value / 110) + 1) / 2;
      canvas.drawArc(rect.inflate(22), start + sweep * .76, sweep * .24, false,
        Paint()..color = red.withOpacity(pulse)
          ..style = PaintingStyle.stroke..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    }
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.redline != redline;
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

class NotificationCenterDialog extends StatelessWidget {
  final bool english;
  const NotificationCenterDialog({super.key, required this.english});

  Future<List<Map<String, dynamic>>> load() async {
    if (!supabaseConfigured) return [];
    final rows = await Supabase.instance.client
        .from('app_notifications')
        .select('id,title_fa,title_en,body_fa,body_en,created_at')
        .eq('is_published', true)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: panel,
    title: Text(english ? 'Notification Center' : 'مرکز اعلان‌ها'),
    content: SizedBox(
      width: 420,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(height: 90, child: Center(child: CircularProgressIndicator(color: red)));
          }
          if (snapshot.hasError) {
            return Text(english ? 'Could not load announcements.' : 'بارگذاری اعلان‌ها انجام نشد.');
          }
          final rows = snapshot.data ?? [];
          if (rows.isEmpty) {
            return Text(english ? 'No announcements yet.' : 'فعلاً اعلان منتشرشده‌ای وجود ندارد.');
          }
          return ListView(
            shrinkWrap: true,
            children: rows.map((row) {
              final title = (english ? row['title_en'] : row['title_fa'])?.toString();
              final body = (english ? row['body_en'] : row['body_fa'])?.toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title?.isNotEmpty == true ? title! : (row['title_fa']?.toString() ?? ''), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(body?.isNotEmpty == true ? body! : (row['body_fa']?.toString() ?? ''), style: const TextStyle(color: silver, height: 1.5)),
                ]),
              );
            }).toList(),
          );
        },
      ),
    ),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(english ? 'Close' : 'بستن'))],
  );
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
          .select('id,title,title_fa,title_en,summary,summary_fa,summary_en,body,body_fa,body_en,category,media_url,media_type,created_at')
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
    final title = (english ? lesson['title_en'] : lesson['title_fa'] ?? lesson['title'])?.toString();
    final body = (english ? lesson['body_en'] : lesson['body_fa'] ?? lesson['body'])?.toString();
    final mediaUrl = lesson['media_url']?.toString();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: panel,
        title: Text((title?.isNotEmpty == true ? title : lesson['title_fa']?.toString() ?? lesson['title']?.toString()) ?? ''),
        content: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text((english ? lesson['summary_en'] : lesson['summary_fa'] ?? lesson['summary'])?.toString() ?? '', style: const TextStyle(color: silver)),
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
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final vehicleController = TextEditingController();
  bool busy = false;
  bool signUp = false;
  bool phoneMode = false;
  bool otpSent = false;
  String? error;
  List<Map<String, dynamic>> vehicles = [];
  List<Map<String, dynamic>> memberships = [];
  Map<String, dynamic>? profile;

  bool get en => widget.english;
  String t(String fa, String english) => en ? english : fa;
  bool get configured => supabaseConfigured;
  SupabaseClient get client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (configured) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          if (client.auth.currentUser != null) {
            runBusy(loadAccount);
          }
        } catch (e) {
          if (mounted) setState(() => error = e.toString());
        }
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    otpController.dispose();
    vehicleController.dispose();
    super.dispose();
  }

  Future<void> runBusy(Future<void> Function() action) async {
    setState(() { busy = true; error = null; });
    try { await action(); }
    catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => busy = false); }
  }

  String _normalizedPhone(String raw) {
    final phone = raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)) {
      throw Exception(t('شماره را با کد کشور وارد کن؛ مثل +989121234567.', 'Enter phone in international format, e.g. +14155552671.'));
    }
    return phone;
  }

  Future<void> resendConfirmation() => runBusy(() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      throw Exception(t('ابتدا ایمیل ثبت‌نام را وارد کن.', 'Enter the signup email first.'));
    }
    try {
      await client.auth.resend(type: OtpType.signup, email: email);
      if (mounted) setState(() => error = t('درخواست ارسال مجدد ثبت شد. صندوق ورودی و هرزنامه را بررسی کن.', 'Confirmation email requested again. Check inbox and spam.'));
    } on AuthException catch (e) {
      final m = e.message.toLowerCase();
      if (m.contains('already confirmed')) {
        throw Exception(t('این ایمیل قبلاً تأیید شده؛ از بخش ورود استفاده کن.', 'This email is already confirmed. Please sign in.'));
      }
      throw Exception(_authError(e));
    }
  });

  Future<void> sendPhoneCode() => runBusy(() async {
    final phone = _normalizedPhone(phoneController.text);
    try {
      await client.auth.signInWithOtp(phone: phone);
      if (mounted) setState(() {
        otpSent = true;
        error = t('کد پیامکی درخواست شد. کد دریافتی را وارد کن.', 'SMS code requested. Enter the code you received.');
      });
    } on AuthException catch (e) {
      throw Exception(_authError(e));
    }
  });

  Future<void> verifyPhoneCode() => runBusy(() async {
    final phone = _normalizedPhone(phoneController.text);
    final token = otpController.text.trim();
    if (token.length < 4) throw Exception(t('کد پیامکی را وارد کن.', 'Enter the SMS verification code.'));
    try {
      await client.auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);
      await loadAccount();
    } on AuthException catch (e) {
      throw Exception(_authError(e));
    }
  });

  Future<void> authenticate() => runBusy(() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || !email.contains('@') || password.length < 6) {
      throw Exception(t('ایمیل معتبر و گذرواژه حداقل ۶ کاراکتری را وارد کن.', 'Enter a valid email and a password of at least 6 characters.'));
    }
    try {
      if (signUp) {
        final response = await client.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: 'com.example.caracal_tuning://login-callback/',
        );
        if (response.session == null) {
          if (mounted) setState(() => error = t('حساب ساخته شد؛ ایمیل خود را برای تأیید بررسی کن.', 'Account created. Check your email to confirm it.'));
          return;
        }
      } else {
        await client.auth.signInWithPassword(email: email, password: password);
      }
      await loadAccount();
    } on AuthException catch (e) {
      throw Exception(_authError(e));
    }
  });

  String _authError(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return t('ایمیل یا گذرواژه اشتباه است.', 'Email or password is incorrect.');
    }
    if (message.contains('email not confirmed')) {
      return t('ابتدا ایمیل خود را تأیید کن.', 'Please confirm your email first.');
    }
    if (message.contains('network') || message.contains('socket') || message.contains('timeout')) {
      return t('ارتباط با سرور برقرار نشد؛ اینترنت و تنظیمات Supabase را بررسی کن.', 'Could not reach the server. Check your internet and Supabase settings.');
    }
    return e.message;
  }

  Future<void> loadAccount() async {
    final user = client.auth.currentUser;
    if (user == null) return;
    final p = await client.from('profiles').select('id,email,role,permissions,created_at').eq('id', user.id).maybeSingle();
    // A garage request must never invalidate a successful authentication.
    List<Map<String, dynamic>> loadedVehicles = [];
    List<Map<String, dynamic>> loadedMemberships = [];
    try {
      final v = await client.from('vehicles').select('id,user_id,name,created_at').eq('user_id', user.id).order('created_at', ascending: false);
      loadedVehicles = List<Map<String, dynamic>>.from(v);
    } catch (e) {
      debugPrint('CARACAL garage vehicles warning: $e');
    }
    try {
      final m = await client.from('memberships').select('id,plan,status,starts_at,ends_at,notes,created_at').eq('user_id', user.id).order('created_at', ascending: false).limit(10);
      loadedMemberships = List<Map<String, dynamic>>.from(m);
    } catch (e) {
      debugPrint('CARACAL membership load warning: $e');
    }
    if (!mounted) return;
    setState(() {
      profile = p ?? {'id': user.id, 'email': user.email, 'role': 'user', 'permissions': <String, dynamic>{}};
      vehicles = loadedVehicles;
      memberships = loadedMemberships;
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
      if (mounted) setState(() { profile = null; vehicles = []; memberships = []; });
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
    if (!signUp) ...[
      const SizedBox(height: 12),
      TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(labelText: t('گذرواژه', 'Password'), border: const OutlineInputBorder())),
      const SizedBox(height: 14),
      FilledButton(onPressed: busy ? null : authenticate, child: Text(t('ورود با گذرواژه', 'SIGN IN WITH PASSWORD'))),
    ] else ...[
      const SizedBox(height: 12),
      TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(labelText: t('گذرواژه (حداقل ۶ کاراکتر)', 'Password (6+ characters)'), border: const OutlineInputBorder())),
      const SizedBox(height: 14),
      FilledButton(onPressed: busy ? null : authenticate, child: Text(t('ثبت‌نام', 'CREATE ACCOUNT'))),
    ],
    TextButton(onPressed: busy ? null : () => setState(() { signUp = !signUp; error = null; }), child: Text(signUp ? t('قبلاً حساب دارم؛ ورود', 'I already have an account') : t('حساب ندارم؛ ثبت‌نام', 'Create a new account'))),
  ]));

  Widget _accountCard() {
    final user = client.auth.currentUser!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _card(Column(children: [
        const Icon(Icons.verified_user_outlined, size: 48, color: silver),
        const SizedBox(height: 8),
        Text(user.email ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        const SizedBox(height: 12),
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
      const SizedBox(height: 18),
      Text(t('عضویت و اشتراک من', 'MY MEMBERSHIP'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 10),
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (memberships.isEmpty) Text(t('هنوز اشتراکی برای حساب شما ثبت نشده است.', 'No membership is registered for your account.'), style: const TextStyle(color: Colors.white54))
        else ...memberships.map((m) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.workspace_premium_outlined, color: red),
          title: Text(m['plan']?.toString() ?? 'standard'),
          subtitle: Text('${t('وضعیت: ', 'Status: ')}${m['status'] ?? 'pending'}'),
        )),
      ])),
    ]);
  }

  Widget _card(Widget child) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)), child: child);
}

// SETTINGS

class SettingsScreen extends StatelessWidget {
  final bool english;
  final bool animations;
  final bool redline;
  final bool haptics;
  final bool introSound;
  final Future<void> Function(String, bool) onChange;

  const SettingsScreen({
    super.key,
    required this.english,
    required this.animations,
    required this.redline,
    required this.haptics,
    required this.introSound,
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
        settingSwitch(
          t('صدای شروع برنامه', 'Intro Sound'),
          t('صدای ویدئوی آغازین کاراکال', 'Play intro video sound'),
          introSound,
          (v) => onChange('introSound', v),
          Icons.volume_up,
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
