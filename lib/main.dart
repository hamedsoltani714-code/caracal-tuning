import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

const Color bg = Color(0xFF08090B);
const Color panel = Color(0xFF17191D);
const Color silver = Color(0xFFD0D3D6);
const Color muted = Color(0xFF858B91);
const Color red = Color(0xFFE13B35);

bool get backendReady =>
    supabaseUrl.startsWith('https://') && supabaseAnonKey.isNotEmpty;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (backendReady) {
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
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CARACAL TUNING',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: silver,
          secondary: red,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class CaracalLogo extends StatelessWidget {
  const CaracalLogo({super.key, this.size = 100});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: CaracalPainter(),
      ),
    );
  }
}

class CaracalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = silver
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round;

    final head = Path()
      ..moveTo(size.width * .17, size.height * .40)
      ..lineTo(size.width * .08, size.height * .04)
      ..lineTo(size.width * .37, size.height * .23)
      ..quadraticBezierTo(
        size.width * .5,
        size.height * .13,
        size.width * .63,
        size.height * .23,
      )
      ..lineTo(size.width * .92, size.height * .04)
      ..lineTo(size.width * .83, size.height * .40)
      ..quadraticBezierTo(
        size.width * .96,
        size.height * .82,
        size.width * .5,
        size.height * .95,
      )
      ..quadraticBezierTo(
        size.width * .04,
        size.height * .82,
        size.width * .17,
        size.height * .40,
      );

    canvas.drawPath(head, p);

    final eye = Paint()..color = red;

    canvas.drawPath(
      Path()
        ..moveTo(size.width * .24, size.height * .48)
        ..lineTo(size.width * .43, size.height * .54)
        ..lineTo(size.width * .32, size.height * .61)
        ..close(),
      eye,
    );

    canvas.drawPath(
      Path()
        ..moveTo(size.width * .76, size.height * .48)
        ..lineTo(size.width * .57, size.height * .54)
        ..lineTo(size.width * .68, size.height * .61)
        ..close(),
      eye,
    );

    final nose = Path()
      ..moveTo(size.width * .43, size.height * .70)
      ..quadraticBezierTo(
        size.width * .5,
        size.height * .64,
        size.width * .57,
        size.height * .70,
      )
      ..lineTo(size.width * .5, size.height * .79)
      ..close();

    canvas.drawPath(nose, Paint()..color = silver);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GaugePainter extends CustomPainter {
  const GaugePainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .88);
    final radius = size.width * .39;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );

    canvas.drawArc(
      rect,
      math.pi,
      math.pi * value.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    for (int i = 0; i <= 20; i++) {
      final angle = math.pi + math.pi * i / 20;
      final outer = radius;
      final inner = radius - (i.isEven ? 18 : 10);

      canvas.drawLine(
        Offset(
          center.dx + outer * math.cos(angle),
          center.dy + outer * math.sin(angle),
        ),
        Offset(
          center.dx + inner * math.cos(angle),
          center.dy + inner * math.sin(angle),
        ),
        Paint()
          ..color = i >= 16 ? red : silver
          ..strokeWidth = i.isEven ? 2 : 1,
      );
    }

    final angle = math.pi + math.pi * value.clamp(0.0, 1.0);

    canvas.drawLine(
      center,
      Offset(
        center.dx + (radius - 25) * math.cos(angle),
        center.dy + (radius - 25) * math.sin(angle),
      ),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(center, 7, Paint()..color = red);
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) {
    return oldDelegate.value != value;
  }
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
    duration: const Duration(milliseconds: 3200),
  );

  late final AnimationController pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  final AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    rev.forward();
    playIntroSound();

    Timer(const Duration(milliseconds: 4300), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MainScreen(),
        ),
      );
    });
  }

  Future<void> playIntroSound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('caracal_sound_enabled') ?? true;

      if (enabled) {
        await player.setVolume(.75);
        await player.play(
          UrlSource('https://sfxmint.com/dl/car-revving-06.mp3'),
        );
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
        builder: (context, child) {
          return Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Color(0xFF30343A),
                  Color(0xFF111316),
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
                    scale: .95 + pulse.value * .05,
                    child: const CaracalLogo(size: 175),
                  ),
                  const SizedBox(height: 15),
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
                      color: silver,
                      letterSpacing: 7,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'DRIVE • LEARN • UPGRADE',
                    style: TextStyle(
                      color: muted,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 45),
                  SizedBox(
                    width: 290,
                    height: 150,
                    child: CustomPaint(
                      painter: GaugePainter(rev.value),
                    ),
                  ),
                  Text(
                    '${(rev.value * 8500).round()} RPM',
                    style: const TextStyle(
                      color: silver,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 35),
                    child: SizedBox(
                      width: 150,
                      child: LinearProgressIndicator(
                        value: rev.value,
                        color: red,
                        backgroundColor: Colors.white12,
                        minHeight: 3,
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

class Lesson {
  const Lesson({
    required this.fa,
    required this.en,
    required this.summary,
    required this.bodyFa,
    required this.bodyEn,
    required this.icon,
  });

  final String fa;
  final String en;
  final String summary;
  final String bodyFa;
  final String bodyEn;
  final IconData icon;
}

const List<Lesson> localLessons = [
  Lesson(
    fa: 'آشنایی با ECU',
    en: 'Understanding ECU',
    summary: 'مبانی کامپیوتر خودرو',
    bodyFa:
        'ECU واحد کنترل الکترونیکی خودرو است. این واحد اطلاعات حسگرها را دریافت و پردازش می‌کند و بر اساس راهبردهای سازنده، سامانه‌های مختلف خودرو را کنترل می‌کند.',
    bodyEn:
        'An ECU is an electronic control unit. It receives sensor information and controls vehicle systems according to manufacturer strategies.',
    icon: Icons.memory,
  ),
  Lesson(
    fa: 'مبانی سنسورها',
    en: 'Sensor Basics',
    summary: 'نقش حسگرها در مدیریت موتور',
    bodyFa:
        'حسگرها اطلاعاتی مانند دمای موتور، فشار هوا، موقعیت دریچه گاز و دور موتور را گزارش می‌کنند. بررسی داده زنده و مقایسه آن با مشخصات فنی، بخش مهمی از عیب‌یابی است.',
    bodyEn:
        'Sensors report information such as engine temperature, air pressure, throttle position and engine speed.',
    icon: Icons.sensors,
  ),
  Lesson(
    fa: 'مبانی ریمپ',
    en: 'Remapping Basics',
    summary: 'آشنایی با کالیبراسیون ECU',
    bodyFa:
        'ریمپ به بررسی و اصلاح کالیبراسیون ECU گفته می‌شود. هر تغییر باید با شناخت موتور، سوخت، سخت‌افزار، استاندارد آلایندگی و محدودیت‌های ایمنی انجام شود.',
    bodyEn:
        'ECU remapping involves reviewing and modifying calibration. Changes must account for engine hardware, fuel, emissions and safety.',
    icon: Icons.speed,
  ),
  Lesson(
    fa: 'خواندن کد خطا',
    en: 'Reading Fault Codes',
    summary: 'شروع اصولی عیب‌یابی',
    bodyFa:
        'کد خطا سرنخی برای یافتن مشکل است، نه تشخیص قطعی قطعه خراب. شرایط ثبت خطا و داده زنده باید پیش از تصمیم‌گیری بررسی شوند.',
    bodyEn:
        'A fault code is a clue, not proof of a failed component. Live data should be reviewed before making a diagnosis.',
    icon: Icons.car_repair,
  ),
  Lesson(
    fa: 'نقشه‌های ECU',
    en: 'ECU Maps',
    summary: 'آشنایی با مفهوم مپ',
    bodyFa:
        'مپ‌ها داده‌های کالیبراسیون هستند که رفتار بخش‌هایی از مدیریت موتور را تعیین می‌کنند. شناخت آن‌ها به ساختار فایل، تعریف محورها و مستندات معتبر نیاز دارد.',
    bodyEn:
        'Maps are calibration data that define aspects of engine management. Understanding them requires knowledge of file structure and documentation.',
    icon: Icons.grid_view,
  ),
  Lesson(
    fa: 'ایمنی کارگاه',
    en: 'Workshop Safety',
    summary: 'اصول پایه پیش از کار عملی',
    bodyFa:
        'از فایل اصلی نسخه پشتیبان تهیه کنید، از ابزار سازگار استفاده کنید و تغذیه برق پایدار داشته باشید. برای عملیات تخصصی از تکنسین واجد صلاحیت کمک بگیرید.',
    bodyEn:
        'Back up original files, use compatible equipment and maintain stable power. Qualified technicians should perform specialist operations.',
    icon: Icons.verified_user,
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
  int selectedTab = 0;
  String searchText = '';
  List<Lesson> remoteLessons = [];

  String t(String a, String b) => fa ? a : b;

  @override
  void initState() {
    super.initState();
    loadPreferences();
    loadLessons();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      sound = prefs.getBool('caracal_sound_enabled') ?? true;
    });
  }

  Future<void> loadLessons() async {
    if (!backendReady) return;

    try {
      final rows = await Supabase.instance.client
          .from('lessons')
          .select()
          .eq('is_published', true)
          .order('created_at', ascending: false);

      final result = rows.map<Lesson>((row) {
        return Lesson(
          fa: row['title_fa'] ?? 'آموزش',
          en: row['title_en'] ?? 'Lesson',
          summary: row['summary_fa'] ?? '',
          bodyFa: row['body_fa'] ?? '',
          bodyEn: row['body_en'] ?? '',
          icon: Icons.menu_book,
        );
      }).toList();

      if (mounted) {
        setState(() {
          remoteLessons = result;
        });
      }
    } catch (_) {
      // Local lessons are kept available.
    }
  }

  List<Lesson> get allLessons => [
        ...localLessons,
        ...remoteLessons,
      ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: fa ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'CARACAL TUNING',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  fa = !fa;
                });
              },
              child: Text(
                fa ? 'EN' : 'فا',
                style: const TextStyle(color: silver),
              ),
            ),
            IconButton(
              onPressed: openSettings,
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: IndexedStack(
          index: selectedTab,
          children: [
            homePage(),
            academyPage(),
            accountPage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedTab,
          onDestinationSelected: (value) {
            setState(() {
              selectedTab = value;
            });
          },
          backgroundColor: const Color(0xFF111316),
          indicatorColor: Colors.white12,
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
  }

  Widget homePage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF383D43),
                Color(0xFF17191D),
                Colors.black,
              ],
            ),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: CaracalLogo(size: 105),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'DRIVE • LEARN • UPGRADE',
                  style: TextStyle(
                    color: silver,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                t('قدرت، دانش، کنترل.', 'POWER. KNOWLEDGE. CONTROL.'),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 21,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                t(
                  'به مرکز تخصصی آموزش و دانش فنی خودرو خوش آمدید.',
                  'Your hub for automotive technical learning.',
                ),
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      selectedTab = 1;
                    });
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(t('ورود به آکادمی', 'Explore Academy')),
                  style: FilledButton.styleFrom(
                    backgroundColor: silver,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        Text(
          t('مسیرهای تخصصی', 'SPECIALTIES'),
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            categoryCard(Icons.memory, t('شناخت ECU', 'ECU BASICS'), 0),
            categoryCard(Icons.speed, t('ریمپ', 'REMAPPING'), 2),
            categoryCard(Icons.car_repair, t('عیب‌یابی', 'DIAGNOSTICS'), 3),
            categoryCard(Icons.shield, t('ایمنی', 'SAFETY'), 5),
          ],
        ),
        const SizedBox(height: 25),
        Text(
          t('آموزش‌های منتخب', 'FEATURED LESSONS'),
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        ...allLessons.take(3).map(lessonTile),
      ],
    );
  }

  Widget categoryCard(IconData icon, String title, int index) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        openLesson(localLessons[index]);
      },
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
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget academyPage() {
    final filtered = allLessons.where((lesson) {
      final text = '${lesson.fa} ${lesson.en} ${lesson.summary}'.toLowerCase();
      return text.contains(searchText.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('کتابخانه آموزش', 'LEARNING LIBRARY'),
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
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
            children: filtered.map(lessonTile).toList(),
          ),
        ),
      ],
    );
  }

  Widget lessonTile(Lesson lesson) {
    return Card(
      color: panel,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.white10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.white10,
          child: Icon(lesson.icon, color: silver),
        ),
        title: Text(
          fa ? lesson.fa : lesson.en,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          fa ? lesson.summary : 'Technical lesson',
          style: const TextStyle(color: muted),
        ),
        trailing: const Icon(Icons.chevron_right, color: silver),
        onTap: () {
          openLesson(lesson);
        },
      ),
    );
  }

  void openLesson(Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          lesson: lesson,
          fa: fa,
        ),
      ),
    );
  }

  Widget accountNotice(String text) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        text,
        style: const TextStyle(height: 1.7),
      ),
    );
  }

  Widget accountPage() {
    final user = backendReady
        ? Supabase.instance.client.auth.currentUser
        : null;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 15),
        const Center(child: CaracalLogo(size: 115)),
        const SizedBox(height: 15),
        Center(
          child: Text(
            t('حساب کاربری', 'YOUR ACCOUNT'),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 23,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (!backendReady) ...[
          accountNotice(
            t(
              'اتصال سرور تنظیم نشده است. برای فعال‌سازی ورود، کلیدهای Supabase باید هنگام ساخت APK تنظیم شوند.',
              'Supabase is not configured. Set the Supabase build keys to enable authentication.',
            ),
          ),
        ] else if (user == null) ...[
          accountNotice(
            t(
              'برای استفاده از امکانات حساب کاربری وارد شوید یا ثبت‌نام کنید.',
              'Sign in or register to use account features.',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              openAuth();
            },
            icon: const Icon(Icons.login),
            label: Text(t('ورود / ثبت‌نام', 'Sign in / Register')),
          ),
        ] else ...[
          accountNotice(
            '${t('وارد شده با', 'Signed in as')}: ${user.email ?? ''}',
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings, color: silver),
            title: Text(t('پنل مدیریت', 'Administration')),
            onTap: openAdmin,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: red),
            title: Text(t('خروج از حساب', 'Sign out')),
            onTap: signOut,
          ),
        ],
      ],
    );
  }

  Future<void> openAuth() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(fa: fa),
      ),
    );

    if (mounted) setState(() {});
  }

  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      showMessage(t('خروج انجام نشد.', 'Sign out failed.'));
    }
  }

  Future<void> openAdmin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerAdminScreen(fa: fa),
      ),
    );
  }

  Future<void> openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(fa: fa),
      ),
    );

    await loadPreferences();

    if (mounted) setState(() {});
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.fa});

  final bool fa;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool sound = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      sound = prefs.getBool('caracal_sound_enabled') ?? true;
    });
  }

  Future<void> changeSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('caracal_sound_enabled', value);

    if (mounted) {
      setState(() {
        sound = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fa = widget.fa;

    return Directionality(
      textDirection: fa ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(fa ? 'تنظیمات' : 'Settings'),
        ),
        body: ListView(
          children: [
            SwitchListTile(
              value: sound,
              activeThumbColor: red,
              title: Text(
                fa ? 'صدای شروع برنامه' : 'Startup sound',
              ),
              subtitle: Text(
                fa
                    ? 'فعال یا غیرفعال کردن صدای موتور'
                    : 'Enable or disable engine sound',
              ),
              onChanged: changeSound,
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(fa ? 'زبان برنامه' : 'App language'),
              subtitle: Text(
                fa ? 'فارسی / انگلیسی' : 'Persian / English',
              ),
            ),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('CARACAL TUNING'),
              subtitle: Text('DRIVE • LEARN • UPGRADE'),
            ),
          ],
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: fa ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(fa ? lesson.fa : lesson.en),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Icon(
                    lesson.icon,
                    size: 55,
                    color: silver,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    fa ? lesson.fa : lesson.en,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              fa ? lesson.bodyFa : lesson.bodyEn,
              style: const TextStyle(
                fontSize: 16,
                height: 2,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
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

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
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

    setState(() {
      busy = true;
    });

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
        Navigator.pop(context);
      }
    } on AuthException catch (error) {
      message(error.message);
    } catch (_) {
      message(
        widget.fa
            ? 'اتصال برقرار نشد. تنظیمات سرور را بررسی کنید.'
            : 'Connection failed. Check server settings.',
      );
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.fa ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.fa ? 'ورود به کاراکال' : 'CARACAL SIGN IN'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const SizedBox(height: 20),
            const Center(child: CaracalLogo(size: 120)),
            const SizedBox(height: 30),
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
                labelText: widget.fa ? 'رمز عبور' : 'Password',
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
                  : () {
                      setState(() {
                        registering = !registering;
                      });
                    },
              child: Text(
                registering
                    ? (widget.fa ? 'قبلاً حساب دارم؛ ورود' : 'Sign in')
                    : (widget.fa ? 'ثبت‌نام حساب جدید' : 'Create an account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OwnerAdminScreen extends StatefulWidget {
  const OwnerAdminScreen({super.key, required this.fa});

  final bool fa;

  @override
  State<OwnerAdminScreen> createState() => _OwnerAdminScreenState();
}

class _OwnerAdminScreenState extends State<OwnerAdminScreen> {
  String? role;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadRole();
  }

  Future<void> loadRole() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        setState(() {
          loading = false;
        });
        return;
      }

      final result = await client
          .from('user_roles')
          .select('role')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        role = result?['role'] as String?;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fa = widget.fa;

    return Directionality(
      textDirection: fa ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(fa ? 'پنل مدیریت' : 'ADMIN PANEL'),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: panel,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const CaracalLogo(size: 90),
                        const SizedBox(height: 15),
                        Text(
                          '${fa ? 'نقش حساب شما' : 'Your role'}: ${role ?? (fa ? 'تعیین نشده' : 'Not assigned')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (role == 'owner') ...[
                    ListTile(
                      leading: const Icon(
                        Icons.verified_user,
                        color: silver,
                      ),
                      title: Text(
                        fa ? 'مالک اصلی سامانه' : 'Platform owner',
                      ),
                      subtitle: Text(
                        fa
                            ? 'حساب مالک اصلی شناسایی شد.'
                            : 'Owner account detected.',
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.menu_book),
                      title: Text(
                        fa ? 'مدیریت آموزش‌ها' : 'Lesson management',
                      ),
                      subtitle: Text(
                        fa
                            ? 'مدیریت محتوا از طریق جدول lessons در Supabase انجام می‌شود.'
                            : 'Manage content through the lessons table in Supabase.',
                      ),
                    ),
                  ] else ...[
                    Text(
                      fa
                          ? 'این حساب نقش مالک ندارد. برای دسترسی مدیریتی، نقش حساب باید در جدول user_roles توسط مالک تعیین شود.'
                          : 'This account is not the owner. The owner must assign its role in user_roles.',
                      style: const TextStyle(height: 1.8),
                    ),
                  ],
                  const SizedBox(height: 15),
                  OutlinedButton.icon(
                    onPressed: loadRole,
                    icon: const Icon(Icons.refresh),
                    label: Text(fa ? 'بررسی دوباره نقش' : 'Refresh role'),
                  ),
                ],
              ),
      ),
    );
  }
}
