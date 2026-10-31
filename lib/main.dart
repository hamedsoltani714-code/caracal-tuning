import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const CaracalApp());
}

const Color silver = Color(0xFFC6C6C6);
const Color background = Color(0xFF090909);
const Color cardColor = Color(0xFF1C1C1C);

class CaracalApp extends StatelessWidget {
  const CaracalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CARACAL TUNING',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: silver,
          secondary: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// SPLASH SCREEN

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation;

  @override
  void initState() {
    super.initState();

    animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();

    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF303030),
                  Colors.black,
                  Colors.black,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  height: 170,
                  child: CustomPaint(
                    painter: RPMGaugePainter(animation.value),
                  ),
                ),
                const SizedBox(height: 15),
                Transform.scale(
                  scale: 0.9 + animation.value * 0.1,
                  child: const Icon(
                    Icons.pets,
                    size: 85,
                    color: silver,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'CARACAL TUNING',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'DRIVE • LEARN • UPGRADE',
                  style: TextStyle(
                    color: silver,
                    letterSpacing: 2,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 35),
                SizedBox(
                  width: 150,
                  child: LinearProgressIndicator(
                    value: animation.value,
                    backgroundColor: Colors.white12,
                    color: silver,
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class RPMGaugePainter extends CustomPainter {
  final double progress;

  RPMGaugePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.88);
    final radius = size.width * 0.39;

    final backgroundPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = silver
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      backgroundPaint,
    );

    canvas.drawArc(
      rect,
      math.pi,
      math.pi * progress,
      false,
      activePaint,
    );

    for (int i = 0; i <= 8; i++) {
      final angle = math.pi + math.pi * i / 8;

      final start = Offset(
        center.dx + (radius - 3) * math.cos(angle),
        center.dy + (radius - 3) * math.sin(angle),
      );

      final end = Offset(
        center.dx + (radius - 18) * math.cos(angle),
        center.dy + (radius - 18) * math.sin(angle),
      );

      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = i >= 7 ? Colors.redAccent : silver
          ..strokeWidth = 2,
      );
    }

    final needleAngle = math.pi + math.pi * progress;

    final needleEnd = Offset(
      center.dx + (radius - 28) * math.cos(needleAngle),
      center.dy + (radius - 28) * math.sin(needleAngle),
    );

    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = Colors.redAccent
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      center,
      6,
      Paint()..color = Colors.white,
    );

    final text = TextPainter(
      text: const TextSpan(
        text: 'RPM',
        style: TextStyle(
          color: silver,
          fontSize: 13,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    text.layout();
    text.paint(
      canvas,
      Offset(center.dx - text.width / 2, center.dy - 34),
    );
  }

  @override
  bool shouldRepaint(covariant RPMGaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// LESSON DATA

class Lesson {
  final String title;
  final String englishTitle;
  final String subtitle;
  final String body;
  final String englishBody;
  final IconData icon;

  const Lesson({
    required this.title,
    required this.englishTitle,
    required this.subtitle,
    required this.body,
    required this.englishBody,
    required this.icon,
  });
}

const List<Lesson> lessons = [
  Lesson(
    title: 'ECU چیست؟',
    englishTitle: 'What is an ECU?',
    subtitle: 'آشنایی با کامپیوتر خودرو',
    body:
        'ECU واحد کنترل الکترونیکی خودرو است. این واحد اطلاعات حسگرها را دریافت می‌کند، آن‌ها را پردازش می‌کند و فرمان‌های لازم را به بخش‌های مختلف موتور می‌فرستد.\n\n'
        'نوع ECU و امکانات آن به سازنده و مدل خودرو بستگی دارد.',
    englishBody:
        'An ECU is the electronic control unit of a vehicle. It receives sensor information, processes it and sends commands to different engine systems.',
    icon: Icons.memory,
  ),
  Lesson(
    title: 'مبانی سنسورها',
    englishTitle: 'Sensor Basics',
    subtitle: 'نقش حسگرها در مدیریت موتور',
    body:
        'حسگرها اطلاعاتی مانند دمای موتور، فشار هوا، موقعیت دریچه گاز و سرعت چرخش موتور را گزارش می‌کنند.\n\n'
        'بررسی داده زنده حسگرها یکی از مراحل مهم عیب‌یابی اصولی خودرو است.',
    englishBody:
        'Sensors report information such as engine temperature, air pressure, throttle position and engine speed. Live sensor data is important for proper diagnostics.',
    icon: Icons.sensors,
  ),
  Lesson(
    title: 'ریمپ چیست؟',
    englishTitle: 'What is Remapping?',
    subtitle: 'آشنایی مقدماتی با کالیبراسیون',
    body:
        'ریمپ به بررسی و اصلاح کالیبراسیون ECU گفته می‌شود.\n\n'
        'هر تغییر باید با شناخت موتور، سوخت، سخت‌افزار و محدودیت‌های ایمنی انجام شود. تغییرات حدسی ممکن است به موتور و سامانه آلایندگی آسیب بزنند.',
    englishBody:
        'Remapping means reviewing and modifying ECU calibration. Changes must consider the engine, fuel, hardware and safety limits.',
    icon: Icons.speed,
  ),
  Lesson(
    title: 'خواندن خطاها',
    englishTitle: 'Reading Fault Codes',
    subtitle: 'شروع اصولی عیب‌یابی',
    body:
        'کد خطا یک سرنخ برای پیدا کردن مشکل خودرو است، نه تشخیص قطعی قطعه خراب.\n\n'
        'شرایط ثبت خطا، اطلاعات لحظه وقوع و داده زنده باید بررسی شوند.',
    englishBody:
        'A fault code is a clue, not proof that a specific component has failed. Check the fault conditions and live data before diagnosing.',
    icon: Icons.car_repair,
  ),
  Lesson(
    title: 'نقشه‌های ECU',
    englishTitle: 'ECU Maps',
    subtitle: 'آشنایی با مفهوم مپ',
    body:
        'مپ‌ها مجموعه‌ای از داده‌های کالیبراسیون هستند که رفتار بخش‌هایی از مدیریت موتور را تعیین می‌کنند.\n\n'
        'شناخت آن‌ها نیازمند آشنایی با ساختار فایل و مستندات معتبر ECU است.',
    englishBody:
        'Maps are calibration data that define aspects of engine management. Understanding them requires ECU file structure knowledge and reliable documentation.',
    icon: Icons.grid_view,
  ),
  Lesson(
    title: 'ایمنی کار',
    englishTitle: 'Workshop Safety',
    subtitle: 'قبل از هر تغییر چه کنیم؟',
    body:
        'همیشه از فایل اصلی نسخه پشتیبان تهیه کنید.\n\n'
        'از ابزار سازگار استفاده کنید، تغذیه برق را پایدار نگه دارید و پس از سرویس، عملکرد خودرو را بررسی کنید.\n\n'
        'در کارهای تخصصی از تکنسین واجد صلاحیت کمک بگیرید.',
    englishBody:
        'Always back up the original file. Use compatible tools, maintain stable power and verify vehicle operation after servicing.',
    icon: Icons.verified_user,
  ),
];

// MAIN SCREEN

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isPersian = true;
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          isPersian ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'CARACAL TUNING',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontSize: 17,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  isPersian = !isPersian;
                });
              },
              child: Text(
                isPersian ? 'EN' : 'فا',
                style: const TextStyle(
                  color: silver,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: IndexedStack(
          index: selectedTab,
          children: [
            buildHome(),
            buildAcademy(),
            buildAccount(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: Colors.black,
          indicatorColor: Colors.white12,
          selectedIndex: selectedTab,
          onDestinationSelected: (index) {
            setState(() {
              selectedTab = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              label: isPersian ? 'خانه' : 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              label: isPersian ? 'آموزش' : 'Lessons',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              label: isPersian ? 'حساب' : 'Account',
            ),
          ],
        ),
      ),
    );
  }

  // HOME PAGE

  Widget buildHome() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF484848),
                Color(0xFF191919),
                Colors.black,
              ],
            ),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.pets,
                    size: 48,
                    color: silver,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'DRIVE • LEARN • UPGRADE',
                      style: TextStyle(
                        color: silver,
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                isPersian
                    ? 'قدرت، دانش، کنترل.'
                    : 'POWER. KNOWLEDGE. CONTROL.',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isPersian
                    ? 'به دنیای تخصصی تیونینگ و عیب‌یابی خودرو خوش آمدید.'
                    : 'Welcome to automotive tuning and diagnostics.',
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    selectedTab = 1;
                  });
                },
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  isPersian ? 'شروع یادگیری' : 'Start Learning',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: silver,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text(
          isPersian ? 'مسیرهای تخصصی' : 'SPECIALTIES',
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            buildCategory(Icons.memory,
                isPersian ? 'شناخت ECU' : 'ECU Basics', 0),
            buildCategory(Icons.speed,
                isPersian ? 'مبانی ریمپ' : 'Remapping', 2),
            buildCategory(Icons.car_repair,
                isPersian ? 'عیب‌یابی' : 'Diagnostics', 3),
            buildCategory(Icons.school,
                isPersian ? 'آکادمی' : 'Academy', 4),
          ],
        ),
        const SizedBox(height: 26),
        Text(
          isPersian ? 'آموزش‌های منتخب' : 'FEATURED LESSONS',
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        ...lessons.take(3).map(buildLessonTile),
      ],
    );
  }

  Widget buildCategory(
    IconData icon,
    String title,
    int lessonIndex,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        openLesson(lessons[lessonIndex]);
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: silver, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ACADEMY PAGE

  Widget buildAcademy() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          isPersian ? 'کتابخانه آموزش' : 'LEARNING LIBRARY',
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isPersian
              ? 'مطالب مقدماتی برای شروع مسیر تخصصی خودرو'
              : 'Starter lessons for automotive learning',
          style: const TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 20),
        ...lessons.map(buildLessonTile),
      ],
    );
  }

  Widget buildLessonTile(Lesson lesson) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 11),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.white10,
          child: Icon(lesson.icon, color: silver),
        ),
        title: Text(
          isPersian ? lesson.title : lesson.englishTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isPersian ? lesson.subtitle : 'Technical introduction',
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: const Icon(
          Icons.chevron_left,
          color: silver,
        ),
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
          isPersian: isPersian,
        ),
      ),
    );
  }

  // ACCOUNT PAGE

  Widget buildAccount() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_circle_outlined,
            size: 75,
            color: silver,
          ),
          const SizedBox(height: 15),
          Text(
            isPersian ? 'حساب کاربری' : 'Your Account',
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isPersian
                ? 'ورود و عضویت در نسخه‌های بعدی اضافه می‌شود.'
                : 'Sign-in will be added in a future version.',
            style: const TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

// LESSON DETAILS

class LessonScreen extends StatelessWidget {
  final Lesson lesson;
  final bool isPersian;

  const LessonScreen({
    super.key,
    required this.lesson,
    required this.isPersian,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          isPersian ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isPersian ? 'آکادمی کاراکال' : 'CARACAL ACADEMY',
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              height: 145,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF484848),
                    Colors.black,
                  ],
                ),
              ),
              child: Icon(
                lesson.icon,
                color: silver,
                size: 70,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isPersian ? lesson.title : lesson.englishTitle,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isPersian ? lesson.subtitle : 'Technical lesson',
              style: const TextStyle(color: silver),
            ),
            const SizedBox(height: 24),
            Text(
              isPersian ? lesson.body : lesson.englishBody,
              style: const TextStyle(
                fontSize: 16,
                height: 1.9,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                isPersian
                    ? 'یادآوری: این محتوا آموزشی و مقدماتی است. برای کار عملی، دستورالعمل سازنده و اصول ایمنی را رعایت کنید.'
                    : 'Note: This is introductory educational content. Follow manufacturer procedures and workshop safety.',
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
}
