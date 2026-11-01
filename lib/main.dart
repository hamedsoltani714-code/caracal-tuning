import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

bool get supabaseConfigured =>
    supabaseUrl.startsWith('https://') && supabaseAnonKey.isNotEmpty;

const silver = Color(0xFFD0D3D6);
const silverDark = Color(0xFF777D83);
const bg = Color(0xFF08090B);
const panel = Color(0xFF15171A);
const accent = Color(0xFFE13B35);
const engineSoundUrl = 'https://sfxmint.com/dl/car-revving-06.mp3';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseConfigured) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  runApp(const CaracalApp());
}

class CaracalApp extends StatelessWidget {
  const CaracalApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CARACAL TUNING',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: bg,
          colorScheme: const ColorScheme.dark(
            primary: silver,
            secondary: accent,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const SplashScreen(),
      );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController rev = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3300),
  );

  late final AnimationController pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  final AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    rev.forward();
    playSound();

    Timer(const Duration(milliseconds: 4300), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    });
  }

  Future<void> playSound() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (prefs.getBool('caracal_sound_enabled') ?? true) {
        await player.setVolume(0.8);
        await player.play(UrlSource(engineSoundUrl));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    player.dispose();
    rev.dispose();
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([rev, pulse]),
        builder: (context, _) {
          return Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.25),
                radius: 1.1,
                colors: [
                  Color(0xFF292D31),
                  bg,
                  Colors.black,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Transform.scale(
                    scale: 0.94 + pulse.value * 0.06,
                    child: const SizedBox(
                      width: 190,
                      height: 170,
                      child: CustomPaint(
                        painter: CaracalMarkPainter(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'CARACAL',
                    style: TextStyle(
                      fontSize: 34,
                      letterSpacing: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'T U N I N G',
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 8,
                      color: silver,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'DRIVE • LEARN • UPGRADE',
                    style: TextStyle(
                      color: silverDark,
                      fontSize: 10,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 290,
                    height: 160,
                    child: CustomPaint(
                      painter: GaugePainter(rev.value),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(rev.value * 8500).round()} RPM',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: silver,
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 36),
                    child: SizedBox(
                      width: 150,
                      child: LinearProgressIndicator(
                        value: rev.value,
                        minHeight: 2,
                        backgroundColor: Colors.white12,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CaracalMarkPainter extends CustomPainter {
  const CaracalMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = silver;

    final head = Path()
      ..moveTo(size.width * 0.16, size.height * 0.40)
      ..lineTo(size.width * 0.08, size.height * 0.04)
      ..lineTo(size.width * 0.36, size.height * 0.23)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.13,
        size.width * 0.64,
        size.height * 0.23,
      )
      ..lineTo(size.width * 0.92, size.height * 0.04)
      ..lineTo(size.width * 0.84, size.height * 0.40)
      ..quadraticBezierTo(
        size.width * 0.94,
        size.height * 0.76,
        size.width * 0.5,
        size.height * 0.94,
      )
      ..quadraticBezierTo(
        size.width * 0.06,
        size.height * 0.76,
        size.width * 0.16,
        size.height * 0.40,
      );

    canvas.drawPath(head, outline);

    final eyes = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.25, size.height * 0.48)
        ..lineTo(size.width * 0.43, size.height * 0.54)
        ..lineTo(size.width * 0.32, size.height * 0.60)
        ..close(),
      eyes,
    );

    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.75, size.height * 0.48)
        ..lineTo(size.width * 0.57, size.height * 0.54)
        ..lineTo(size.width * 0.68, size.height * 0.60)
        ..close(),
      eyes,
    );

    final nose = Path()
      ..moveTo(size.width * 0.43, size.height * 0.69)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.64,
        size.width * 0.57,
        size.height * 0.69,
      )
      ..lineTo(size.width * 0.5, size.height * 0.77)
      ..close();

    canvas.drawPath(nose, Paint()..color = silver);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}class GaugePainter extends CustomPainter {
  const GaugePainter(this.value);
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.91);
    final radius = size.width * 0.40;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      rect,
      math.pi,
      math.pi * value.clamp(0.0, 1.0),
      false,
      Paint()
        ..shader = const SweepGradient(
          startAngle: math.pi,
          endAngle: math.pi * 2,
          colors: [silver, accent],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i <= 20; i++) {
      final angle = math.pi + math.pi * i / 20;
      final inner = radius - (i.isEven ? 19 : 12);
      canvas.drawLine(
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
        Offset(
          center.dx + inner * math.cos(angle),
          center.dy + inner * math.sin(angle),
        ),
        Paint()
          ..color = i >= 16 ? accent : silverDark
          ..strokeWidth = i.isEven ? 2 : 1,
      );
    }

    final angle = math.pi + math.pi * value.clamp(0.0, 1.0);
    canvas.drawLine(
      center,
      Offset(
        center.dx + (radius - 29) * math.cos(angle),
        center.dy + (radius - 29) * math.sin(angle),
      ),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(center, 7, Paint()..color = accent);

    final label = TextPainter(
      text: const TextSpan(
        text: 'RPM',
        style: TextStyle(
          color: silver,
          fontSize: 12,
          letterSpacing: 3,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    label.paint(canvas, Offset(center.dx - label.width / 2, center.dy - 39));
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) =>
      oldDelegate.value != value;
}

class Lesson {
  const Lesson(
    this.fa,
    this.en,
    this.sub,
    this.bodyFa,
    this.bodyEn,
    this.icon,
  );

  final String fa;
  final String en;
  final String sub;
  final String bodyFa;
  final String bodyEn;
  final IconData icon;
}

const lessons = <Lesson>[
  Lesson(
    'ECU چیست؟',
    'What is an ECU?',
    'آشنایی با کامپیوتر خودرو',
    'ECU واحد کنترل الکترونیکی خودرو است. این واحد اطلاعات حسگرها را دریافت و پردازش می‌کند و بر اساس راهبردهای سازنده، فرمان‌هایی به سامانه‌های خودرو می‌فرستد.',
    'An ECU is an electronic control unit. It receives and processes sensor information and controls vehicle systems according to manufacturer strategies.',
    Icons.memory,
  ),
  Lesson(
    'مبانی سنسورها',
    'Sensor Basics',
    'نقش حسگرها در مدیریت موتور',
    'حسگرها اطلاعاتی مانند دمای موتور، فشار هوا، موقعیت دریچه گاز و دور موتور را گزارش می‌کنند. بررسی داده زنده و مقایسه آن با مشخصات فنی، بخش مهمی از عیب‌یابی است.',
    'Sensors report engine temperature, air pressure, throttle position and engine speed. Comparing live data with specifications is an important diagnostic step.',
    Icons.sensors,
  ),
  Lesson(
    'مبانی ریمپ',
    'Remapping Basics',
    'آشنایی با کالیبراسیون ECU',
    'ریمپ به بررسی و اصلاح کالیبراسیون ECU گفته می‌شود. هر تغییر باید با شناخت موتور، سوخت، سخت‌افزار، استاندارد آلایندگی و محدودیت‌های ایمنی انجام شود.',
    'ECU remapping involves reviewing and modifying calibration. Any change must account for the engine, fuel, hardware, emissions requirements and safety limits.',
    Icons.speed,
  ),
  Lesson(
    'خواندن کد خطا',
    'Reading Fault Codes',
    'شروع اصولی عیب‌یابی',
    'کد خطا سرنخی برای یافتن مشکل است، نه تشخیص قطعی قطعه خراب. شرایط ثبت خطا و داده زنده باید پیش از تصمیم‌گیری بررسی شوند.',
    'A fault code is a clue, not proof of a failed component. Freeze-frame conditions and live data should be reviewed before making a diagnosis.',
    Icons.car_repair,
  ),
  Lesson(
    'نقشه‌های ECU',
    'ECU Maps',
    'آشنایی با مفهوم مپ',
    'مپ‌ها داده‌های کالیبراسیون هستند که رفتار بخش‌هایی از مدیریت موتور را تعیین می‌کنند. شناخت آن‌ها به ساختار فایل، تعریف محورها و مستندات معتبر نیاز دارد.',
    'Maps are calibration data that define aspects of engine management. Understanding them requires knowledge of file structure, axes and reliable documentation.',
    Icons.grid_view,
  ),
  Lesson(
    'ایمنی کارگاه',
    'Workshop Safety',
    'اصول پایه پیش از کار عملی',
    'از فایل اصلی نسخه پشتیبان تهیه کنید، از ابزار سازگار استفاده کنید و تغذیه برق پایدار داشته باشید. برای عملیات تخصصی از تکنسین واجد صلاحیت کمک بگیرید.',
    'Back up original files, use compatible equipment and maintain stable power. Qualified technicians should perform specialist operations.',
    Icons.verified_user,
  ),
];

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool fa = true;
  bool sound = true;
  int tab = 0;
  String query = '';
  List<Lesson> remoteLessons = [];

  String t(String a, String b) => fa ? a : b;

  @override
  void initState() {
    super.initState();
    _loadSoundPreference();
    loadRemoteLessons();
  }

  Future<void> _loadSoundPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        sound = prefs.getBool('caracal_sound_enabled') ?? true;
      });
    }
  }

  Future<void> loadRemoteLessons() async {
    if (!supabaseConfigured) return;

    try {
      final rows = await Supabase.instance.client
          .from('lessons')
          .select()
          .eq('is_published', true)
          .order('created_at', ascending: false);

      final parsed = rows
          .map<Lesson>(
            (e) => Lesson(
              e['title_fa'] ?? 'آموزش',
              e['title_en'] ?? 'Lesson',
              e['summary_fa'] ?? '',
              e['body_fa'] ?? '',
              e['body_en'] ?? '',
              Icons.menu_book,
            ),
          )
          .toList();

      if (mounted) setState(() => remoteLessons = parsed);
    } catch (_) {
      // Local lessons remain available if the backend is offline.
    }
  }

  List<Lesson> get allLessons => [...lessons, ...remoteLessons];

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: fa ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CustomPaint(painter: CaracalMarkPainter()),
                ),
                const SizedBox(width: 10),
                const Text(
                  'CARACAL TUNING',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => setState(() => fa = !fa),
                child: Text(
                  fa ? 'EN' : 'فا',
                  style: const TextStyle(
                    color: silver,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: openSettings,
                icon: const Icon(Icons.tune, color: silver),
              ),
            ],
          ),
          body: IndexedStack(
            index: tab,
            children: [home(), academy(), account()],
          ),
          bottomNavigationBar: NavigationBar(
            backgroundColor: const Color(0xFF101113),
            indicatorColor: Colors.white12,
            selectedIndex: tab,
            onDestinationSelected: (value) => setState(() => tab = value),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.dashboard_outlined),
                label: t('خانه', 'Home'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.school_outlined),
                label: t('آکادمی', 'Academy'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                label: t('حساب', 'Account'),
              ),
            ],
          ),
        ),
      );

  Widget home() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF34383D),
                  Color(0xFF17191C),
                  Colors.black,
                ],
              ),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 64,
                      height: 64,
                      child: CustomPaint(painter: CaracalMarkPainter()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DRIVE • LEARN • UPGRADE',
                            style: TextStyle(
                              color: silver,
                              fontSize: 10,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t(
                              'قدرت، دانش، کنترل.',
                              'POWER. KNOWLEDGE. CONTROL.',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  t(
                    'به مرکز تخصصی آموزش و دانش فنی خودرو خوش آمدید.',
                    'Your hub for automotive technical learning and knowledge.',
                  ),
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => setState(() => tab = 1),
                  style: FilledButton.styleFrom(
                    backgroundColor: silver,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(t('ورود به آکادمی', 'Explore Academy')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            t('مسیرهای تخصصی', 'SPECIALTIES'),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 11,
            crossAxisSpacing: 11,
            childAspectRatio: 1.5,
            children: [
              category(Icons.memory, t('شناخت ECU', 'ECU BASICS'), 0),
              category(Icons.speed, t('ریمپ و کالیبراسیون', 'REMAPPING'), 2),
              category(Icons.car_repair, t('عیب‌یابی', 'DIAGNOSTICS'), 3),
              category(
                Icons.shield_outlined,
                t('ایمنی کار', 'WORKSHOP SAFETY'),
                5,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            t('آموزش‌های منتخب', 'FEATURED LESSONS'),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          ...allLessons.take(3).map(lessonTile),
        ],
      );  Widget category(IconData icon, String title, int index) => InkWell(
        onTap: () => openLesson(lessons[index]),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: silver, size: 31),
              const SizedBox(height: 9),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );

  Widget academy() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('کتابخانه آموزش', 'LEARNING LIBRARY'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: InputDecoration(
                    hintText: t('جست‌وجوی آموزش...', 'Search lessons...'),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: panel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: allLessons
                  .where(
                    (lesson) => ('${lesson.fa} ${lesson.en} ${lesson.sub}')
                        .toLowerCase()
                        .contains(query.toLowerCase()),
                  )
                  .map(lessonTile)
                  .toList(),
            ),
          ),
        ],
      );

  Widget lessonTile(Lesson lesson) => Card(
        color: panel,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.white10),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 7,
          ),
          leading: CircleAvatar(
            backgroundColor: Colors.white10,
            child: Icon(lesson.icon, color: silver),
          ),
          title: Text(
            fa ? lesson.fa : lesson.en,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            fa ? lesson.sub : 'Technical introduction',
            style: const TextStyle(color: Colors.white54),
          ),
          trailing: const Icon(Icons.chevron_right, color: silver),
          onTap: () => openLesson(lesson),
        ),
      );

  void openLesson(Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonScreen(lesson: lesson, fa: fa),
      ),
    );
  }

  Widget account() => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          const Center(
            child: SizedBox(
              width: 112,
              height: 100,
              child: CustomPaint(painter: CaracalMarkPainter()),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              t('حساب کاربری', 'YOUR ACCOUNT'),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (!supabaseConfigured)
            accountNotice(
              t(
                'اتصال سرور هنوز تنظیم نشده است. برای فعال‌سازی ورود، هنگام ساخت APK کلیدهای Supabase را تعریف کنید.',
                'Backend is not configured. Set the Supabase build keys to enable authentication.',
              ),
            )
          else if (Supabase.instance.client.auth.currentUser == null) ...[
            accountNotice(
              t(
                'برای همگام‌سازی آموزش‌ها و امکانات حساب کاربری وارد شوید یا ثبت‌نام کنید.',
                'Sign in or create an account to sync lessons and use account features.',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AuthScreen(fa: fa)),
              ).then((_) {
                if (mounted) setState(() {});
              }),
              icon: const Icon(Icons.login),
              label: Text(t('ورود / ثبت‌نام', 'Sign in / Register')),
            ),
          ] else ...[
            accountNotice(
              '${t('وارد شده با', 'Signed in as')}: ${Supabase.instance.client.auth.currentUser!.email ?? ''}',
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: silver),
              title: Text(t('پنل مدیریت', 'Administration')),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OwnerAdminScreen(fa: fa),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: accent),
              title: Text(t('خروج از حساب', 'Sign out')),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
      },
    ),
  ),
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.fa});
  final bool fa;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool registering = false;
  bool busy = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 8) {
      message(
        widget.fa
            ? 'ایمیل و رمز حداقل ۸ کاراکتری وارد کنید.'
            : 'Enter an email and a password of at least 8 characters.',
      );
      return;
    }

    setState(() => busy = true);

    try {
      final auth = Supabase.instance.client.auth;

      if (registering) {
        await auth.signUp(
          email: email.text.trim(),
          password: password.text,
        );
      } else {
        await auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }

      if (!mounted) return;

      if (registering && auth.currentUser == null) {
        message(
          widget.fa
              ? 'لینک تأیید به ایمیل شما ارسال شد.'
              : 'A confirmation link was sent to your email.',
        );
      } else {
        Navigator.pop(context, true);
      }
    } on AuthException catch (error) {
      message(error.message);
    } catch (_) {
      message(
        widget.fa
            ? 'اتصال برقرار نشد. تنظیمات Supabase را بررسی کنید.'
            : 'Connection failed. Check Supabase configuration.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: widget.fa ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.fa ? 'ورود به کاراکال' : 'CARACAL SIGN IN',
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const SizedBox(height: 20),
              const Center(
                child: SizedBox(
                  width: 120,
                  height: 110,
                  child: CustomPaint(painter: CaracalMarkPainter()),
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: widget.fa ? 'ایمیل' : 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: panel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: widget.fa
                      ? 'رمز عبور (حداقل ۸ کاراکتر)'
                      : 'Password (8+ characters)',
                  prefixIcon: const Icon(Icons.lock_outline),
                  filled: true,
                  fillColor: panel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: busy ? null : submit,
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: busy
                      ? const CircularProgressIndicator()
                      : Text(
                          registering
                              ? (widget.fa ? 'ساخت حساب' : 'Create account')
                              : (widget.fa ? 'ورود' : 'Sign in'),
                        ),
                ),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() => registering = !registering),
                child: Text(
                  registering
                      ? (widget.fa
                          ? 'قبلاً حساب دارم؛ ورود'
                          : 'I already have an account')
                      : (widget.fa
                          ? 'حساب ندارم؛ ثبت‌نام'
                          : 'Create a new account'),
                ),
              ),
            ],
          ),
        ),
      );
}

class OwnerAdminScreen extends StatefulWidget {
  const OwnerAdminScreen({super.key, required this.fa});
  final bool fa;

  @override
  State<OwnerAdminScreen> createState() => _OwnerAdminScreenState();
}

class _OwnerAdminScreenState extends State<OwnerAdminScreen> {
  final email = TextEditingController();
  bool busy = false;
  String? role;
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser!.id;

      final mine = await client
          .from('user_roles')
          .select('role')
          .eq('user_id', uid)
          .maybeSingle();

      if (mounted) {
        setState(() => role = mine?['role'] as String?);
      }

      if (mine?['role'] == 'owner') {
        final rows = await client
            .from('user_roles')
            .select('email,role,permissions,created_at')
            .order('created_at');

        if (mounted) {
          setState(() => users = List<Map<String, dynamic>>.from(rows));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.fa
                  ? 'جدول نقش‌ها آماده نیست؛ SQL راه‌اندازی را اجرا کنید.'
                  : 'Role table is not ready. Run the setup SQL.',
            ),
          ),
        );
      }
    }
  }  Future<void> setAdmin(String nextRole) async {
    if (email.text.trim().isEmpty) return;

    setState(() => busy = true);

    try {
      await Supabase.instance.client
          .from('user_roles')
          .update({'role': nextRole})
          .eq('email', email.text.trim());

      email.clear();
      await load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.fa
                  ? 'فقط مالک اجازه تغییر نقش دارد. ایمیل باید قبلاً ثبت‌نام کرده باشد.'
                  : 'Only the owner can change roles. The email must belong to a registered user.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> setContentPermission(
    String userEmail,
    bool enabled,
  ) async {
    try {
      await Supabase.instance.client
          .from('user_roles')
          .update({
            'permissions': {
              'content': enabled,
              'members': false,
              'notifications': false,
            },
          })
          .eq('email', userEmail);

      await load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.fa ? 'تغییر مجوز انجام نشد.' : 'Permission update failed.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          '${widget.fa ? 'نقش فعلی' : 'Current role'}: ${role ?? (widget.fa ? 'در حال بررسی' : 'checking')}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ];

    if (role == 'owner' || role == 'admin') {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ContentManagementScreen(fa: widget.fa),
              ),
            ),
            icon: const Icon(Icons.library_add),
            label: Text(
              widget.fa ? 'مدیریت آموزش‌ها' : 'Manage lessons',
            ),
          ),
        ),
      );
    }

    if (role == 'owner') {
      children.addAll([
        const SizedBox(height: 22),
        Text(
          widget.fa ? 'مدیریت مدیران' : 'ADMIN MANAGEMENT',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: widget.fa ? 'ایمیل کاربر ثبت‌نام‌شده' : 'Registered user email',
            filled: true,
            fillColor: panel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: busy ? null : () => setAdmin('admin'),
                child: Text(widget.fa ? 'ارتقا به مدیر' : 'Make admin'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: busy ? null : () => setAdmin('member'),
                child: Text(widget.fa ? 'حذف مدیریت' : 'Remove admin'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          widget.fa ? 'فهرست کاربران' : 'USER LIST',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...users.map((user) {
          final userEmail = user['email']?.toString() ?? '';
          final userRole = user['role']?.toString() ?? 'member';
          final permissions =
              user['permissions'] as Map<String, dynamic>? ?? {};
          final contentEnabled = permissions['content'] == true;

          return Card(
            color: panel,
            child: ListTile(
              title: Text(
                userEmail.isEmpty ? 'User' : userEmail,
                style: const TextStyle(fontSize: 13),
              ),
              subtitle: Text(userRole),
              trailing: userRole == 'owner'
                  ? const Icon(Icons.verified, color: silver)
                  : Switch(
                      value: contentEnabled,
                      onChanged: (value) =>
                          setContentPermission(userEmail, value),
                    ),
            ),
          );
        }),
      ]);
    } else if (role != 'admin') {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text(
            widget.fa
                ? 'دسترسی مدیریت برای این حساب فعال نیست.'
                : 'This account does not have admin access.',
          ),
        ),
      );
    }

    return Directionality(
      textDirection: widget.fa ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.fa ? 'پنل مدیریت' : 'ADMIN PANEL'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: children,
        ),
      ),
    );
  }
}class ContentManagementScreen extends StatefulWidget {
  const ContentManagementScreen({super.key, required this.fa});
  final bool fa;

  @override
  State<ContentManagementScreen> createState() =>
      _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen> {
  final faTitle = TextEditingController();
  final enTitle = TextEditingController();
  final faBody = TextEditingController();
  final enBody = TextEditingController();
  final faSummary = TextEditingController();
  final enSummary = TextEditingController();

  bool busy = false;
  bool allowed = false;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    faTitle.dispose();
    enTitle.dispose();
    faBody.dispose();
    enBody.dispose();
    faSummary.dispose();
    enSummary.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser!.id;
      final role = await client
          .from('user_roles')
          .select('role,permissions')
          .eq('user_id', uid)
          .single();

      final permissions = role['permissions'];
      final canManage = role['role'] == 'owner' ||
          (role['role'] == 'admin' &&
              permissions is Map &&
              permissions['content'] == true);

      final rows = canManage
          ? await client
              .from('lessons')
              .select()
              .order('created_at', ascending: false)
          : <dynamic>[];

      if (mounted) {
        setState(() {
          allowed = canManage;
          items = List<Map<String, dynamic>>.from(rows);
        });
      }
    } catch (_) {
      if (mounted) setState(() => allowed = false);
    }
  }

  Future<void> save() async {
    if (faTitle.text.trim().isEmpty ||
        enTitle.text.trim().isEmpty ||
        faBody.text.trim().isEmpty ||
        enBody.text.trim().isEmpty) {
      return;
    }

    setState(() => busy = true);

    try {
      final client = Supabase.instance.client;
      await client.from('lessons').insert({
        'title_fa': faTitle.text.trim(),
        'title_en': enTitle.text.trim(),
        'summary_fa': faSummary.text.trim(),
        'summary_en': enSummary.text.trim(),
        'body_fa': faBody.text.trim(),
        'body_en': enBody.text.trim(),
        'category': 'general',
        'is_published': true,
        'created_by': client.auth.currentUser!.id,
      });

      faTitle.clear();
      enTitle.clear();
      faBody.clear();
      enBody.clear();
      faSummary.clear();
      enSummary.clear();

      await load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.fa ? 'آموزش منتشر شد.' : 'Lesson published.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.fa
                  ? 'انتشار ناموفق بود؛ اتصال و مجوز را بررسی کنید.'
                  : 'Publish failed. Check connection and permissions.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(
    TextEditingController controller,
    String label, {
    int lines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          maxLines: lines,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: panel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: widget.fa ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.fa ? 'مدیریت آموزش‌ها' : 'LESSON MANAGER',
            ),
          ),
          body: !allowed
              ? Center(
                  child: Text(
                    widget.fa
                        ? 'مجوز مدیریت محتوا برای این حساب فعال نیست.'
                        : 'This account does not have content-management permission.',
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      widget.fa ? 'آموزش جدید' : 'NEW LESSON',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    field(faTitle, 'عنوان فارسی'),
                    field(enTitle, 'English title'),
                    field(faSummary, 'خلاصه فارسی'),
                    field(enSummary, 'English summary'),
                    field(faBody, 'متن کامل فارسی', lines: 5),
                    field(enBody, 'Full English content', lines: 5),
                    FilledButton.icon(
                      onPressed: busy ? null : save,
                      icon: const Icon(Icons.publish),
                      label: Text(
                        widget.fa ? 'انتشار آموزش' : 'Publish lesson',
                      ),
                    ),
                    const Divider(height: 32),
                    Text(
                      widget.fa
                          ? 'آموزش‌های منتشرشده'
                          : 'PUBLISHED LESSONS',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...items.map(
                      (item) => ListTile(
                        leading: const Icon(Icons.menu_book, color: silver),
                        title: Text('${item['title_fa']}'),
                        subtitle: Text('${item['title_en']}'),
                      ),
                    ),
                  ],
                ),
        ),
      );
}

class LessonScreen extends StatelessWidget {
  const LessonScreen({
    super.key,
    required this.lesson,
    required this.fa,
  });

  final Lesson lesson;
  final bool fa;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: fa ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              fa ? 'آکادمی کاراکال' : 'CARACAL ACADEMY',
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                height: 155,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF393D42), Colors.black],
                  ),
                ),
                child: Icon(lesson.icon, color: silver, size: 68),
              ),
              const SizedBox(height: 24),
              Text(
                fa ? lesson.fa : lesson.en,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                fa ? lesson.sub : 'Technical lesson',
                style: const TextStyle(color: silver),
              ),
              const SizedBox(height: 22),
              Text(
                fa ? lesson.bodyFa : lesson.bodyEn,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.9,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  fa
                      ? 'یادآوری: این محتوا آموزشی است. برای کار عملی، دستورالعمل سازنده و اصول ایمنی را رعایت کنید.'
                      : 'Note: This is educational content. Follow manufacturer procedures and workshop safety.',
                  style: const TextStyle(
                    color: silver,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
