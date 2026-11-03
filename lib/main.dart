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
  final bool english, redline, animations;
  final ValueChanged<int> onNavigate;
  const HomeScreen({super.key, required this.english, required this.redline, required this.animations, required this.onNavigate});
  String t(String fa, String en) => english ? en : fa;

  @override Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;
    return ListView(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 18, 14, compact ? 12 : 18, 28),
      children: [
        Row(children: [
          Container(width: 54, height: 50, padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: const Color(0xFF171A1E), borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFF68717C)),
              boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 12, offset: Offset(0, 5))]),
            child: Image.asset('assets/130315.png', fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.pets, color: silver, size: 32))),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CARACAL TUNING', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.25)),
            Text('DRIVE • LEARN • UPGRADE', style: TextStyle(color: red, fontSize: 9, letterSpacing: 1.6, fontWeight: FontWeight.bold)),
          ])),
          IconButton(tooltip: 'Notifications',
            onPressed: () => showDialog<void>(context: context, builder: (_) => NotificationCenterDialog(english: english)),
            icon: const Icon(Icons.notifications_none, color: silver, size: 27)),
        ]),
        const SizedBox(height: 18),
        Container(
          padding: EdgeInsets.fromLTRB(compact ? 10 : 15, 14, compact ? 10 : 15, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF343A42), Color(0xFF101215), Color(0xFF050607)]),
            border: Border.all(color: const Color(0xFF737D88), width: 1.3),
            boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 24, offset: Offset(0, 12)),
              BoxShadow(color: Color(0x337D8996), blurRadius: 8, spreadRadius: 1)]),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.speed, color: Color(0xFFFF4148), size: 18),
              const SizedBox(width: 7),
              Expanded(child: Text(t('پنل پشت‌آمپر خودرو', 'DIGITAL COCKPIT'),
                style: const TextStyle(fontSize: 12, color: silver, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
                child: Text(t('حالت نمایشی', 'DEMO MODE'), style: const TextStyle(color: Color(0xFFFF6B70), fontSize: 8, fontWeight: FontWeight.w900))),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(5, 10, 5, 7),
              decoration: BoxDecoration(color: const Color(0xFF070809), borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF505963), width: 1.2),
                boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 14, spreadRadius: 2, offset: Offset(0, 5))]),
              child: Column(children: [
                SizedBox(height: compact ? 190 : 218,
                  child: Row(children: [
                    Expanded(child: AnimatedGauge(redline: redline, animations: animations)),
                    Container(width: 1, height: 145, color: Colors.white12),
                    Expanded(child: AnimatedSpeedGauge(animations: animations)),
                  ])),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _dialCaption(t('دور موتور', 'ENGINE RPM'), 'x1000'),
                    _dialCaption(t('سرعت', 'VEHICLE SPEED'), 'km/h'),
                  ])),
                const SizedBox(height: 9),
                const Divider(height: 1, color: Colors.white12),
                const SizedBox(height: 9),
                VehicleTelemetryPanel(english: english),
              ]),
            ),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.info_outline, color: Colors.white38, size: 13),
              const SizedBox(width: 5),
              Expanded(child: Text(t('اعداد صرفاً نمایشی هستند؛ اطلاعات واقعی به اتصال OBD-II نیاز دارد.',
                'Illustrative values only. Live vehicle data requires an OBD-II adapter.'),
                style: const TextStyle(color: Colors.white54, fontSize: 9))),
            ]),
          ]),
        ),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: Text(t('منظومه کاراکال', 'CARACAL SOLAR SYSTEM'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: .8))),
          const Icon(Icons.hub_rounded, color: red, size: 20),
        ]),
        const SizedBox(height: 10),
        OrbitalMainMenu(
          english: english,
          onNavigate: onNavigate,
        ),
        const SizedBox(height: 23),
        Text(t('موضوعات منتخب', 'FEATURED TOPICS')        Text(t('موضوعات منتخب', 'FEATURED TOPICS'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: .8)),
        const SizedBox(height: 11),
        FeatureTile(icon: Icons.settings_input_component, title: t('اصول عملکرد موتور', 'Engine Fundamentals'),
          subtitle: t('آشنایی با پارامترهای اصلی موتور', 'Understanding core engine parameters'),
          onTap: () => showLesson(context, english, 'Engine Architecture')),
        FeatureTile(icon: Icons.memory, title: t('آشنایی با ECU', 'Getting to Know ECU'),
          subtitle: t('ساختار و وظایف واحد کنترل موتور', 'Engine control unit architecture'),
          onTap: () => showLesson(context, english, 'ECU Fundamentals')),
        FeatureTile(icon: Icons.query_stats, title: t('مبانی تحلیل داده', 'Data Analysis Basics'),
          subtitle: t('شناخت داده‌ها و پارامترهای خودرو', 'Understanding vehicle data'),
          onTap: () => showLesson(context, english, 'Parameter Analysis')),
      ],
    );
  }

  Widget _dialCaption(String title, String unit) => Column(children: [
    Text(title, style: const TextStyle(color: silver, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
    const SizedBox(height: 2),
    Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 8, letterSpacing: 1)),
  ]);
}

class QuickCard extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  const QuickCard({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(17),
    child: Container(padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(17),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF30353B), Color(0xFF14171B), Color(0xFF08090B)]),
        border: Border.all(color: const Color(0xFF626B75), width: 1),
        boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 5))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: silver, size: 27), const SizedBox(height: 10),
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white)),
        const SizedBox(height: 4),
        Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white54, fontSize: 9)),
      ]),
    ),
  );
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


class AnimatedSpeedGauge extends StatefulWidget {
  final bool animations;
  const AnimatedSpeedGauge({super.key, required this.animations});
  @override
  State<AnimatedSpeedGauge> createState() => _AnimatedSpeedGaugeState();
}
class _AnimatedSpeedGaugeState extends State<AnimatedSpeedGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _speed;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _speed = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 260.0).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 65),
      TweenSequenceItem(tween: Tween<double>(begin: 260.0, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 35),
    ]).animate(_controller);
    if (widget.animations) { _controller.repeat(); } else { _controller.value = .42; }
  }
  @override
  void didUpdateWidget(covariant AnimatedSpeedGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animations && !_controller.isAnimating) { _controller.repeat(); }
    else if (!widget.animations && _controller.isAnimating) { _controller.stop(); _controller.value = .42; }
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _speed,
    builder: (_, __) => CustomPaint(painter: SpeedGaugePainter(value: _speed.value), child: const SizedBox.expand()),
  );
}
class SpeedGaugePainter extends CustomPainter {
  final double value;
  SpeedGaugePainter({required this.value});
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final center = Offset(size.width / 2, size.height * .77);
    final radius = math.min(size.width * .40, size.height * .63);
    const start = math.pi * 1.12;
    const sweep = math.pi * .76;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect.inflate(8), start, sweep, false, Paint()
      ..color = const Color(0xFF77818C).withOpacity(.6)
      ..style = PaintingStyle.stroke..strokeWidth = 2.2);
    canvas.drawArc(rect, start, sweep, false, Paint()
      ..color = Colors.white.withOpacity(.10)
      ..style = PaintingStyle.stroke..strokeWidth = 11);
    canvas.drawArc(rect, start, sweep * (value / 260).clamp(0.0, 1.0), false, Paint()
      ..color = const Color(0xFF56C8FF).withOpacity(.75)
      ..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round);
    for (int i = 0; i <= 26; i++) {
      final angle = start + sweep * i / 26;
      final major = i % 5 == 0;
      final p1 = Offset(center.dx + math.cos(angle) * (radius - (major ? 10 : 4)),
          center.dy + math.sin(angle) * (radius - (major ? 10 : 4)));
      final p2 = Offset(center.dx + math.cos(angle) * (radius + (major ? 9 : 5)),
          center.dy + math.sin(angle) * (radius + (major ? 9 : 5)));
      canvas.drawLine(p1, p2, Paint()
        ..color = Colors.white.withOpacity(major ? .9 : .36)
        ..strokeWidth = major ? 1.8 : 1);
      if (major) {
        final tp = TextPainter(
          text: TextSpan(text: (i * 10).toString(), style: const TextStyle(color: silver, fontSize: 8, fontWeight: FontWeight.w700)),
          textDirection: TextDirection.ltr,
        )..layout();
        final pos = Offset(center.dx + math.cos(angle) * (radius - 25),
            center.dy + math.sin(angle) * (radius - 25));
        tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
      }
    }
    final angle = start + sweep * (value / 260).clamp(0.0, 1.0);
    final needle = Offset(center.dx + math.cos(angle) * (radius - 19),
        center.dy + math.sin(angle) * (radius - 19));
    canvas.drawLine(center, needle, Paint()
      ..color = const Color(0xFF56C8FF)..strokeWidth = 2.6..strokeCap = StrokeCap.round);
    canvas.drawCircle(center, 6, Paint()..color = silver);
    canvas.drawCircle(center, 3, Paint()..color = const Color(0xFF101216));
    final speed = TextPainter(
      text: TextSpan(text: value.round().toString(), style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    speed.paint(canvas, Offset(center.dx - speed.width / 2, center.dy - 30));
    final unit = TextPainter(
      text: const TextSpan(text: 'km/h', style: TextStyle(color: silver, fontSize: 8, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    unit.paint(canvas, Offset(center.dx - unit.width / 2, center.dy - 9));
  }
  @override
  bool shouldRepaint(covariant SpeedGaugePainter oldDelegate) => oldDelegate.value != value;
}
class VehicleTelemetryPanel extends StatelessWidget {
  final bool english;
  const VehicleTelemetryPanel({super.key, required this.english});
  @override
  Widget build(BuildContext context) {
    final items = <(String, String, IconData)>[
      (english ? 'Coolant' : 'دمای آب', '90°C', Icons.thermostat),
      (english ? 'Oil temp.' : 'دمای روغن', '96°C', Icons.oil_barrel_outlined),
      (english ? 'Battery' : 'ولتاژ باتری', '14.2V', Icons.battery_charging_full),
      (english ? 'Boost' : 'فشار بوست', '1.2 bar', Icons.speed),
      (english ? 'Throttle' : 'دریچه گاز', '24%', Icons.tune),
      (english ? 'Fuel' : 'سوخت', '68%', Icons.local_gas_station),
      (english ? 'Engine load' : 'بار موتور', '42%', Icons.analytics),
      (english ? 'Gear' : 'دنده', 'D', Icons.settings),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Text(english ? 'VEHICLE DATA' : 'پارامترهای خودرو',
          style: const TextStyle(color: silver, fontWeight: FontWeight.w900, fontSize: 12))),
        const Text('DEMO', style: TextStyle(color: red, fontSize: 9, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 8),
      GridView.count(
        crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.05, mainAxisSpacing: 6, crossAxisSpacing: 6,
        children: items.map((item) => Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: const Color(0xFF0D0F12),
            borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white10)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(item.$3, color: const Color(0xFF56C8FF), size: 16),
            const SizedBox(height: 5),
            FittedBox(child: Text(item.$2, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900))),
            const SizedBox(height: 3),
            FittedBox(child: Text(item.$1, style: const TextStyle(color: silver, fontSize: 8))),
          ]),
        )).toList(),
      ),
      const SizedBox(height: 5),
      Text(english
        ? 'Illustrative values only — live readings require a compatible OBD-II adapter.'
        : 'اعداد نمایشی هستند؛ نمایش زنده به اتصال آداپتور سازگار OBD-II نیاز دارد.',
        style: const TextStyle(color: Colors.white38, fontSize: 9)),
    ]);
  }
}

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
  final TextEditingController _search = TextEditingController();
  List<Map<String, dynamic>> onlineLessons = [];
  bool loadingOnline = false;
  String? onlineError;
  String selectedFilter = 'all';

  bool get english => widget.english;
  String t(String fa, String en) => english ? en : fa;

  final List<Map<String, dynamic>> modules = [
    {'icon': Icons.school_rounded, 'fa':'آموزش تخصصی خودرو','en':'Automotive Technical Education','descFa':'مسیرهای آموزشی از مبانی تا مباحث حرفه‌ای خودرو.','descEn':'Structured learning paths from fundamentals to advanced automotive topics.','group':'learn'},
    {'icon': Icons.directions_car_filled, 'fa':'بانک اطلاعات فنی خودرو','en':'Vehicle Technical Database','descFa':'مشخصات فنی، سیستم‌ها و اطلاعات کاربردی خودروها.','descEn':'Vehicle specifications, systems and technical references.','group':'reference'},
    {'icon': Icons.warning_amber_rounded, 'fa':'بانک کدهای خطای DTC','en':'DTC Error Code Database','descFa':'جست‌وجو و شناخت کدهای خطا و مفهوم آن‌ها.','descEn':'Search diagnostic trouble codes and understand their meaning.','group':'diagnosis'},
    {'icon': Icons.memory, 'fa':'نقشه پایه ECU','en':'ECU Pinout Diagrams','descFa':'مرجع آموزشی پایه‌ها و اتصالات واحد کنترل الکترونیکی.','descEn':'Educational reference for ECU pins and connections.','group':'reference'},
    {'icon': Icons.account_tree, 'fa':'نقشه سیم‌کشی خودرو','en':'Automotive Wiring Diagrams','descFa':'مطالعه ساختار مدارها و مسیرهای سیم‌کشی.','descEn':'Study circuit layouts and vehicle wiring paths.','group':'reference'},
    {'icon': Icons.electrical_services, 'fa':'نقشه فیوز و رله','en':'Fuse & Relay Diagrams','descFa':'راهنمای آموزشی جعبه‌فیوزها و مدارهای حفاظتی.','descEn':'Educational guide to fuse boxes and protection circuits.','group':'reference'},
    {'icon': Icons.settings, 'fa':'راهنمای تعمیر موتور','en':'Engine Repair Guides','descFa':'آشنایی با اجزای موتور، اصول سرویس و تعمیر.','descEn':'Engine components, service principles and repair guides.','group':'repair'},
    {'icon': Icons.bolt, 'fa':'سیستم برق خودرو','en':'Automotive Electrical Systems','descFa':'مبانی برق، شارژ، استارت و مدارهای الکتریکی.','descEn':'Electrical fundamentals, charging, starting and circuits.','group':'repair'},
    {'icon': Icons.tune, 'fa':'آموزش برنامه‌ریزی و ریمپ ECU','en':'ECU Programming & Remapping','descFa':'مفاهیم کالیبراسیون، ساختار داده و اصول ایمن ریمپ.','descEn':'Calibration concepts, data structure and safe remapping principles.','group':'learn'},
    {'icon': Icons.settings_applications, 'fa':'گیربکس اتوماتیک','en':'Automatic Transmission','descFa':'شناخت ساختار، عملکرد و عیب‌یابی مقدماتی گیربکس.','descEn':'Transmission architecture, operation and basic diagnostics.','group':'repair'},
    {'icon': Icons.sensors, 'fa':'سنسورها و عملگرها','en':'Sensors & Actuators','descFa':'نحوه عملکرد و نقش حسگرها و عملگرهای خودرو.','descEn':'How automotive sensors and actuators work.','group':'diagnosis'},
    {'icon': Icons.menu_book, 'fa':'فرهنگ لغت تخصصی خودرو','en':'Automotive Technical Dictionary','descFa':'اصطلاحات تخصصی فارسی و انگلیسی صنعت خودرو.','descEn':'Persian and English automotive terminology.','group':'reference'},
    {'icon': Icons.calculate, 'fa':'ماشین‌حساب‌های فنی','en':'Automotive Calculators','descFa':'ابزارهای محاسباتی آموزشی برای پارامترهای خودرو.','descEn':'Learning calculators for common vehicle parameters.','group':'tools'},
    {'icon': Icons.smart_toy, 'fa':'دستیار هوشمند عیب‌یابی','en':'AI Diagnostic Assistant','descFa':'راهنمای مرحله‌ای تحلیل علائم و اطلاعات عیب‌یابی.','descEn':'Step-by-step assistance for interpreting symptoms and diagnostic data.','group':'tools'},
    {'icon': Icons.quiz, 'fa':'آزمون‌ها و سنجش تخصصی','en':'Professional Quizzes & Exams','descFa':'آزمون‌های آموزشی برای سنجش دانش فنی.','descEn':'Knowledge checks and technical learning assessments.','group':'learn'},
  ];

  @override
  void initState() {
    super.initState();
    loadOnlineLessons();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> loadOnlineLessons() async {
    if (!supabaseConfigured) return;
    if (mounted) setState(() { loadingOnline = true; onlineError = null; });
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
    Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
      OnlineLessonDetailScreen(lesson: lesson, english: english)));
  }

  void openModule(Map<String, dynamic> module) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
      ModuleDetailScreen(module: module, english: english)));
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = modules.where((m) {
      final groupOk = selectedFilter == 'all' || m['group'] == selectedFilter;
      final title = (english ? m['en'] : m['fa']).toString().toLowerCase();
      final other = (english ? m['fa'] : m['en']).toString().toLowerCase();
      return groupOk && (query.isEmpty || title.contains(query) || other.contains(query));
    }).toList();

    return RefreshIndicator(
      color: red,
      onRefresh: loadOnlineLessons,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          Row(children: [
            Expanded(child: Text(t('مرکز دانش کاراکال','CARACAL KNOWLEDGE HUB'),
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: .3))),
            IconButton(tooltip: t('تازه‌سازی','Refresh'), onPressed: loadOnlineLessons,
              icon: const Icon(Icons.refresh, color: silver)),
          ]),
          const SizedBox(height: 5),
          Text(t('۱۵ بخش تخصصی؛ هر بخش با صفحه و جست‌وجوی مستقل','15 specialist modules, each with its own detail page and discovery'),
            style: const TextStyle(color: silver, fontSize: 11)),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: t('جست‌وجو در بخش‌های فنی...','Search technical modules...'),
              prefixIcon: const Icon(Icons.search, color: red),
              suffixIcon: _search.text.isEmpty ? null : IconButton(
                onPressed: () { _search.clear(); setState(() {}); },
                icon: const Icon(Icons.close)),
              filled: true, fillColor: panel,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.white12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.white12)),
            ),
          ),
          const SizedBox(height: 13),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filterChip('all', t('همه','All')),
              _filterChip('learn', t('آموزش','Learning')),
              _filterChip('diagnosis', t('عیب‌یابی','Diagnostics')),
              _filterChip('reference', t('نقشه و مرجع','References')),
              _filterChip('repair', t('تعمیرات','Repair')),
              _filterChip('tools', t('ابزارها','Tools')),
            ]),
          ),
          const SizedBox(height: 18),
          if (onlineLessons.isNotEmpty) ...[
            _sectionTitle(t('مطالب منتشرشده','PUBLISHED CONTENT'), Icons.new_releases),
            const SizedBox(height: 10),
            for (final lesson in onlineLessons)
              FeatureTile(
                icon: Icons.auto_stories,
                title: ((english ? lesson['title_en'] : lesson['title_fa'] ?? lesson['title'])?.toString().trim().isNotEmpty == true)
                    ? (english ? lesson['title_en'] : lesson['title_fa'] ?? lesson['title']).toString()
                    : (lesson['title']?.toString() ?? ''),
                subtitle: (english ? lesson['summary_en'] : lesson['summary_fa'] ?? lesson['summary'])?.toString() ?? '',
                onTap: () => openOnlineLesson(lesson),
              ),
            const SizedBox(height: 12),
          ],
          if (loadingOnline) const Center(child: Padding(
            padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: red))),
          if (onlineError != null) Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(t('بارگذاری مطالب آنلاین انجام نشد: ','Online content could not be loaded: ') + onlineError!,
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 11))),
          _sectionTitle(t('فهرست بخش‌های تخصصی','SPECIALIST MODULES'), Icons.grid_view_rounded),
          const SizedBox(height: 11),
          if (visible.isEmpty)
            Padding(padding: const EdgeInsets.all(28),
              child: Center(child: Text(t('موردی پیدا نشد.','No modules found.'),
                style: const TextStyle(color: silver)))),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visible.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 11, crossAxisSpacing: 11,
              childAspectRatio: .98),
            itemBuilder: (_, i) {
              final m = visible[i];
              return InkWell(
                borderRadius: BorderRadius.circular(17),
                onTap: () => openModule(m),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    gradient: const LinearGradient(begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF30353B), Color(0xFF15171B), Color(0xFF090A0C)]),
                    border: Border.all(color: const Color(0xFF58616B)),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 9, offset: Offset(0, 4))]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Icon(m['icon'] as IconData, color: silver, size: 28),
                    Text(english ? m['en'] as String : m['fa'] as String,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                    Row(children: [
                      Expanded(child: Text(t('ورود به بخش','Open module'),
                        style: const TextStyle(color: Colors.white54, fontSize: 9))),
                      const Icon(Icons.arrow_forward_ios, color: red, size: 12),
                    ]),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 7),
    child: ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      selected: selectedFilter == value,
      onSelected: (_) => setState(() => selectedFilter = value),
      selectedColor: red.withOpacity(.22),
      backgroundColor: panel,
      side: BorderSide(color: selectedFilter == value ? red : Colors.white12),
    ),
  );

  Widget _sectionTitle(String title, IconData icon) => Row(children: [
    Icon(icon, color: red, size: 17), const SizedBox(width: 8),
    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: .5))),
  ]);
}

class ModuleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> module;
  final bool english;
  const ModuleDetailScreen({super.key, required this.module, required this.english});
  String t(String fa, String en) => english ? en : fa;

  @override
  Widget build(BuildContext context) {
    final title = english ? module['en'] as String : module['fa'] as String;
    final description = english ? module['descEn'] as String : module['descFa'] as String;
    return Scaffold(
      appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: bg, foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Container(padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [Color(0xFF343A42), Color(0xFF111316), Colors.black]),
            border: Border.all(color: const Color(0xFF737D88))),
          child: Column(children: [
            Icon(module['icon'] as IconData, size: 52, color: silver),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center,
              style: const TextStyle(color: silver, height: 1.7)),
          ]),
        ),
        const SizedBox(height: 20),
        Text(t('در این بخش چه چیزهایی یاد می‌گیری؟','WHAT YOU WILL FIND'),
          style: const TextStyle(color: red, fontWeight: FontWeight.w900, fontSize: 12)),
        const SizedBox(height: 10),
        for (final item in [
          t('مفاهیم پایه و اصطلاحات کلیدی','Core concepts and terminology'),
          t('ساختار سیستم‌ها و اجزای اصلی','System architecture and main components'),
          t('روش مطالعه اطلاعات و تحلیل داده‌ها','How to read information and interpret data'),
          t('نکات ایمنی و خطاهای رایج','Safety notes and common pitfalls'),
        ])
          FeatureTile(icon: Icons.check_circle_outline, title: item,
            subtitle: t('محتوای آموزشی این بخش به‌مرور از پنل مدیریت منتشر می‌شود.','Learning material for this module is published through the admin panel.')),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10)),
          child: Text(t('برای مشاهده مطالب اختصاصی این بخش، به قسمت آموزش‌های منتشرشده برگرد و از جست‌وجو استفاده کن.','For dedicated lessons, return to published learning content and use search.'),
            style: const TextStyle(color: silver, height: 1.6))),
      ]),
    );
  }
}

class OnlineLessonDetailScreen extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final bool english;
  const OnlineLessonDetailScreen({super.key, required this.lesson, required this.english});
  String t(String fa, String en) => english ? en : fa;

  @override
  Widget build(BuildContext context) {
    final title = (english ? lesson['title_en'] : lesson['title_fa'] ?? lesson['title'])?.toString()
        ?? lesson['title']?.toString() ?? '';
    final summary = (english ? lesson['summary_en'] : lesson['summary_fa'] ?? lesson['summary'])?.toString() ?? '';
    final body = (english ? lesson['body_en'] : lesson['body_fa'] ?? lesson['body'])?.toString()
        ?? lesson['body']?.toString() ?? '';
    final media = lesson['media_url']?.toString() ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: bg, foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        if (summary.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(summary, style: const TextStyle(color: silver, fontSize: 13, height: 1.7)),
        ],
        const SizedBox(height: 18),
        SelectableText(body, style: const TextStyle(fontSize: 14, height: 1.9)),
        if (media.isNotEmpty) ...[
          const SizedBox(height: 20),
          if (lesson['media_type'] == 'image')
            ClipRRect(borderRadius: BorderRadius.circular(14),
              child: Image.network(media, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text(t('تصویر بارگذاری نشد.','Image could not be loaded.')))),
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.tryParse(media);
              if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.open_in_new),
            label: Text(t('باز کردن فایل پیوست','Open attachment')),
          ),
        ],
      ]),
    );
  }
}

// ORBITAL MAIN MENU — interactive planets around the CARACAL core.
class OrbitalMainMenu extends StatelessWidget {
  final bool english;
  final ValueChanged<int> onNavigate;
  const OrbitalMainMenu({super.key, required this.english, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final items = <_OrbitItem>[
      _OrbitItem(english ? 'LEARN' : 'آموزش', Icons.school_rounded, 1, const Offset(0, -112)),
      _OrbitItem(english ? 'ECU' : 'ریمپ و ECU', Icons.memory_rounded, 1, const Offset(105, -55)),
      _OrbitItem(english ? 'GARAGE' : 'گاراژ', Icons.directions_car_rounded, 2, const Offset(105, 65)),
      _OrbitItem(english ? 'BOOKING' : 'نوبت‌دهی', Icons.calendar_month_rounded, 3, const Offset(0, 120)),
      _OrbitItem(english ? 'PROFILE' : 'حساب کاربری', Icons.person_rounded, 2, const Offset(-105, 65)),
      _OrbitItem(english ? 'SETTINGS' : 'تنظیمات', Icons.tune_rounded, 4, const Offset(-105, -55)),
    ];
    return SizedBox(
      height: 300,
      child: LayoutBuilder(builder: (context, box) {
        final center = Offset(box.maxWidth / 2, 150);
        return Stack(children: [
          Positioned.fill(
            child: CustomPaint(painter: _OrbitPainter()),
          ),
          Positioned(
            left: center.dx - 48, top: center.dy - 48,
            child: Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(colors: [Color(0xFF515963), Color(0xFF171A1F), Color(0xFF08090B)]),
                border: Border.all(color: silver.withOpacity(.8), width: 1.5),
                boxShadow: [BoxShadow(color: red.withOpacity(.22), blurRadius: 25, spreadRadius: 2)],
              ),
              padding: const EdgeInsets.all(17),
              child: Image.asset('assets/130315.png', fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.pets, color: silver, size: 45)),
            ),
          ),
          for (final item in items)
            Positioned(
              left: center.dx + item.offset.dx - 36,
              top: center.dy + item.offset.dy - 36,
              child: Semantics(
                button: true,
                label: item.label,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onNavigate(item.tab),
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Color(0xFF454C55), Color(0xFF171A1F), Color(0xFF090A0C)]),
                      border: Border.all(color: const Color(0xFF929BA5), width: 1.1),
                      boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 12, offset: Offset(0, 5))],
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(item.icon, color: item.tab == 1 ? red : silver, size: 23),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
        ]);
      }),
    );
  }
}

class _OrbitItem {
  final String label;
  final IconData icon;
  final int tab;
  final Offset offset;
  const _OrbitItem(this.label, this.icon, this.tab, this.offset);
}

class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 150);
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 1
      ..color = const Color(0x667E8995);
    canvas.drawCircle(center, 78, p);
    p..color = const Color(0x447E8995)..strokeWidth = 1.2;
    canvas.drawOval(Rect.fromCenter(center: center, width: 270, height: 220), p);
    p..color = const Color(0x22FF3038)..strokeWidth = 1;
    canvas.drawOval(Rect.fromCenter(center: center, width: 300, height: 265), p);
    final glow = Paint()..color = const Color(0x44FF3038)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, 5, glow);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
