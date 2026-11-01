import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(const CaracalApp());

const silver = Color(0xFFD0D3D6);
const silverDark = Color(0xFF777D83);
const bg = Color(0xFF08090B);
const panel = Color(0xFF15171A);
const accent = Color(0xFFE13B35);

class CaracalApp extends StatelessWidget {
  const CaracalApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CARACAL TUNING',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: bg,
          colorScheme: const ColorScheme.dark(primary: silver, secondary: accent),
          useMaterial3: true,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(backgroundColor: bg, elevation: 0),
        ),
        home: const SplashScreen(),
      );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController rev = AnimationController(vsync: this, duration: const Duration(milliseconds: 3300));
  late final AnimationController pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  @override
  void initState() {
    super.initState();
    rev.forward();
    Timer(const Duration(milliseconds: 4300), () {
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    });
  }
  @override
  void dispose() { rev.dispose(); pulse.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
        body: AnimatedBuilder(
          animation: Listenable.merge([rev, pulse]),
          builder: (context, _) => Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment(0, -.25), radius: 1.1, colors: [Color(0xFF292D31), bg, Colors.black])),
            child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Spacer(),
              Transform.scale(scale: .94 + pulse.value * .06, child: const SizedBox(width: 190, height: 170, child: CustomPaint(painter: CaracalMarkPainter()))),
              const SizedBox(height: 18),
              const Text('CARACAL', style: TextStyle(fontSize: 34, letterSpacing: 8, fontWeight: FontWeight.w900)),
              const Text('T U N I N G', style: TextStyle(fontSize: 14, letterSpacing: 8, color: silver)),
              const SizedBox(height: 8),
              const Text('DRIVE  •  LEARN  •  UPGRADE', style: TextStyle(color: silverDark, fontSize: 10, letterSpacing: 2.2)),
              const SizedBox(height: 48),
              SizedBox(width: 290, height: 160, child: CustomPaint(painter: GaugePainter(rev.value))),
              const SizedBox(height: 12),
              Text('${(rev.value * 8500).round()} RPM', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 3, color: silver)),
              const Spacer(),
              Padding(padding: const EdgeInsets.only(bottom: 36), child: SizedBox(width: 150, child: LinearProgressIndicator(value: rev.value, minHeight: 2, backgroundColor: Colors.white12, color: accent))),
            ])),
          ),
        ),
      );
}

class CaracalMarkPainter extends CustomPainter {
  const CaracalMarkPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 4..strokeJoin = StrokeJoin.round..strokeCap = StrokeCap.round;
    final silverPaint = p..color = silver;
    final path = Path()
      ..moveTo(s.width*.16, s.height*.40)..lineTo(s.width*.08, s.height*.04)..lineTo(s.width*.36, s.height*.23)
      ..quadraticBezierTo(s.width*.5, s.height*.13, s.width*.64, s.height*.23)
      ..lineTo(s.width*.92, s.height*.04)..lineTo(s.width*.84, s.height*.40)
      ..quadraticBezierTo(s.width*.94, s.height*.76, s.width*.5, s.height*.94)
      ..quadraticBezierTo(s.width*.06, s.height*.76, s.width*.16, s.height*.40);
    canvas.drawPath(path, silverPaint);
    final eye = Paint()..color = accent..style = PaintingStyle.fill;
    canvas.drawPath(Path()..moveTo(s.width*.25,s.height*.48)..lineTo(s.width*.43,s.height*.54)..lineTo(s.width*.32,s.height*.60)..close(), eye);
    canvas.drawPath(Path()..moveTo(s.width*.75,s.height*.48)..lineTo(s.width*.57,s.height*.54)..lineTo(s.width*.68,s.height*.60)..close(), eye);
    final nose = Path()..moveTo(s.width*.43,s.height*.69)..quadraticBezierTo(s.width*.5,s.height*.64,s.width*.57,s.height*.69)..lineTo(s.width*.5,s.height*.77)..close();
    canvas.drawPath(nose, Paint()..color = silver);
    canvas.drawLine(Offset(s.width*.5,s.height*.77), Offset(s.width*.5,s.height*.84), p..color = silverDark..strokeWidth = 2);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GaugePainter extends CustomPainter {
  final double value;
  GaugePainter(this.value);
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width/2, size.height*.91), r = size.width*.40;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(rect, math.pi, math.pi, false, Paint()..color = Colors.white12..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round);
    canvas.drawArc(rect, math.pi, math.pi*value, false, Paint()..shader = const SweepGradient(startAngle: math.pi, endAngle: math.pi*2, colors: [silver, accent]).createShader(rect)..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round);
    for (var i=0;i<=20;i++) {
      final a = math.pi + math.pi*i/20;
      final inner = r - (i%2==0 ? 19 : 12);
      canvas.drawLine(Offset(c.dx+r*math.cos(a),c.dy+r*math.sin(a)), Offset(c.dx+inner*math.cos(a),c.dy+inner*math.sin(a)), (Paint()..color = (i >= 16 ? accent : silverDark)..strokeWidth = (i % 2 == 0 ? 2 : 1)));
    }
    final a = math.pi + math.pi*value;
    canvas.drawLine(c, Offset(c.dx+(r-29)*math.cos(a),c.dy+(r-29)*math.sin(a)), Paint()..color=Colors.white..strokeWidth=3..strokeCap=StrokeCap.round);
    canvas.drawCircle(c, 7, Paint()..color=accent);
    final tp = TextPainter(text: const TextSpan(text:'RPM',style:TextStyle(color:silver,fontSize:12,letterSpacing:3,fontWeight:FontWeight.bold)),textDirection:TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(c.dx-tp.width/2,c.dy-39));
  }
  @override
  bool shouldRepaint(covariant GaugePainter old) => old.value != value;
}

class Lesson {
  final String fa, en, sub, bodyFa, bodyEn;
  final IconData icon;
  const Lesson(this.fa,this.en,this.sub,this.bodyFa,this.bodyEn,this.icon);
}
const lessons = <Lesson>[
 Lesson('ECU چیست؟','What is an ECU?','آشنایی با کامپیوتر خودرو','ECU واحد کنترل الکترونیکی خودرو است. این واحد اطلاعات حسگرها را دریافت و پردازش می‌کند و بر اساس راهبردهای سازنده، فرمان‌هایی به سامانه‌های خودرو می‌فرستد.','An ECU is an electronic control unit. It receives and processes sensor information and controls vehicle systems according to manufacturer strategies.',Icons.memory),
 Lesson('مبانی سنسورها','Sensor Basics','نقش حسگرها در مدیریت موتور','حسگرها اطلاعاتی مانند دمای موتور، فشار هوا، موقعیت دریچه گاز و دور موتور را گزارش می‌کنند. بررسی داده زنده و مقایسه آن با مشخصات فنی، بخش مهمی از عیب‌یابی است.','Sensors report engine temperature, air pressure, throttle position and engine speed. Comparing live data with specifications is an important diagnostic step.',Icons.sensors),
 Lesson('مبانی ریمپ','Remapping Basics','آشنایی با کالیبراسیون ECU','ریمپ به بررسی و اصلاح کالیبراسیون ECU گفته می‌شود. هر تغییر باید با شناخت موتور، سوخت، سخت‌افزار، استاندارد آلایندگی و محدودیت‌های ایمنی انجام شود. تغییرات حدسی می‌تواند به خودرو آسیب بزند.','ECU remapping involves reviewing and modifying calibration. Any change must account for the engine, fuel, hardware, emissions requirements and safety limits.',Icons.speed),
 Lesson('خواندن کد خطا','Reading Fault Codes','شروع اصولی عیب‌یابی','کد خطا سرنخی برای یافتن مشکل است، نه تشخیص قطعی قطعه خراب. شرایط ثبت خطا، داده لحظه وقوع و داده زنده باید پیش از تصمیم‌گیری بررسی شوند.','A fault code is a clue, not proof of a failed component. Freeze-frame conditions and live data should be reviewed before making a diagnosis.',Icons.car_repair),
 Lesson('نقشه‌های ECU','ECU Maps','آشنایی با مفهوم مپ','مپ‌ها داده‌های کالیبراسیون هستند که رفتار بخش‌هایی از مدیریت موتور را تعیین می‌کنند. شناخت آن‌ها به ساختار فایل، تعریف محورها و مستندات معتبر نیاز دارد.','Maps are calibration data that define aspects of engine management. Understanding them requires knowledge of file structure, axes and reliable documentation.',Icons.grid_view),
 Lesson('ایمنی کارگاه','Workshop Safety','اصول پایه پیش از کار عملی','از فایل اصلی نسخه پشتیبان تهیه کنید، از ابزار سازگار استفاده کنید و تغذیه برق پایدار داشته باشید. برای عملیات تخصصی و آزمون خودرو از تکنسین واجد صلاحیت کمک بگیرید.','Back up original files, use compatible equipment and maintain stable power. Qualified technicians should perform specialist operations and vehicle testing.',Icons.verified_user),
];

class MainScreen extends StatefulWidget { const MainScreen({super.key}); @override State<MainScreen> createState()=>_MainScreenState(); }
class _MainScreenState extends State<MainScreen> {
 bool fa=true, sound=true; int tab=0; String query='';
 String t(String a,String b)=>fa?a:b;
 @override Widget build(BuildContext context)=>Directionality(textDirection:fa?TextDirection.rtl:TextDirection.ltr,child:Scaffold(
  appBar:AppBar(title:Row(children:[const SizedBox(width:30,height:30,child:CustomPaint(painter:CaracalMarkPainter())),const SizedBox(width:10),const Text('CARACAL TUNING',style:TextStyle(fontSize:15,fontWeight:FontWeight.w900,letterSpacing:1.4))]),actions:[TextButton(onPressed:()=>setState(()=>fa=!fa),child:Text(fa?'EN':'فا',style:const TextStyle(color:silver,fontWeight:FontWeight.bold))),IconButton(onPressed:openSettings,icon:const Icon(Icons.tune,color:silver))]),
  body:IndexedStack(index:tab,children:[home(),academy(),account()]),
  bottomNavigationBar:NavigationBar(backgroundColor:const Color(0xFF101113),indicatorColor:Colors.white12,selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:[NavigationDestination(icon:const Icon(Icons.dashboard_outlined),label:t('خانه','Home')),NavigationDestination(icon:const Icon(Icons.school_outlined),label:t('آکادمی','Academy')),NavigationDestination(icon:const Icon(Icons.person_outline),label:t('حساب','Account'))]),
 ));
 Widget home()=>ListView(padding:const EdgeInsets.all(16),children:[
  Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF34383D),Color(0xFF17191C),Colors.black]),border:Border.all(color:Colors.white24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const SizedBox(width:64,height:64,child:CustomPaint(painter:CaracalMarkPainter())),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('DRIVE • LEARN • UPGRADE',style:TextStyle(color:silver,fontSize:10,letterSpacing:1.4)),const SizedBox(height:6),Text(t('قدرت، دانش، کنترل.','POWER. KNOWLEDGE. CONTROL.'),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:20))]))]),const SizedBox(height:14),Text(t('به مرکز تخصصی آموزش و دانش فنی خودرو خوش آمدید.','Your hub for automotive technical learning and knowledge.'),style:const TextStyle(color:Colors.white70,height:1.7)),const SizedBox(height:16),FilledButton.icon(onPressed:()=>setState(()=>tab=1),style:FilledButton.styleFrom(backgroundColor:silver,foregroundColor:Colors.black),icon:const Icon(Icons.play_arrow),label:Text(t('ورود به آکادمی','Explore Academy')))])),
  const SizedBox(height:24),Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(t('مسیرهای تخصصی','SPECIALTIES'),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:18)),Text('01 / 04',style:const TextStyle(color:silverDark,fontSize:11))]),const SizedBox(height:12),GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,mainAxisSpacing:11,crossAxisSpacing:11,childAspectRatio:1.5,children:[category(Icons.memory,t('شناخت ECU','ECU BASICS'),0),category(Icons.speed,t('ریمپ و کالیبراسیون','REMAPPING'),2),category(Icons.car_repair,t('عیب‌یابی','DIAGNOSTICS'),3),category(Icons.shield_outlined,t('ایمنی کار','WORKSHOP SAFETY'),5)]),
  const SizedBox(height:24),Text(t('آموزش‌های منتخب','FEATURED LESSONS'),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:18)),const SizedBox(height:10),...lessons.take(3).map(lessonTile),
  Container(margin:const EdgeInsets.only(top:12),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(16),border:Border.all(color:Colors.white10)),child:Row(children:[const Icon(Icons.workspace_premium,color:silver,size:30),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t('عضویت حرفه‌ای','PRO MEMBERSHIP'),style:const TextStyle(fontWeight:FontWeight.bold)),Text(t('بخش اشتراک در نسخه متصل به سرور فعال می‌شود.','Membership will activate with the connected backend.'),style:const TextStyle(color:Colors.white54,fontSize:12))]))]))
 ]);
 Widget category(IconData icon,String title,int index)=>InkWell(onTap:()=>openLesson(lessons[index]),borderRadius:BorderRadius.circular(16),child:Container(decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(16),border:Border.all(color:Colors.white12)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,color:silver,size:31),const SizedBox(height:9),Text(title,textAlign:TextAlign.center,style:const TextStyle(fontSize:12,fontWeight:FontWeight.bold))])));
 Widget academy()=>Column(children:[Padding(padding:const EdgeInsets.fromLTRB(16,14,16,8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t('کتابخانه آموزش','LEARNING LIBRARY'),style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:12),TextField(onChanged:(v)=>setState(()=>query=v),decoration:InputDecoration(hintText:t('جست‌وجوی آموزش...','Search lessons...'),prefixIcon:const Icon(Icons.search),filled:true,fillColor:panel,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none)))])),Expanded(child:ListView(padding:const EdgeInsets.symmetric(horizontal:16),children:lessons.where((l)=>('${l.fa} ${l.en} ${l.sub}').toLowerCase().contains(query.toLowerCase())).map(lessonTile).toList())]);
 Widget lessonTile(Lesson l)=>Card(color:panel,margin:const EdgeInsets.only(bottom:10),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14),side:const BorderSide(color:Colors.white10)),child:ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:7),leading:CircleAvatar(backgroundColor:Colors.white10,child:Icon(l.icon,color:silver)),title:Text(fa?l.fa:l.en,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(fa?l.sub:'Technical introduction',style:const TextStyle(color:Colors.white54)),trailing:const Icon(Icons.chevron_right,color:silver),onTap:()=>openLesson(l)));
 void openLesson(Lesson l)=>Navigator.push(context,MaterialPageRoute(builder:(_)=>LessonScreen(lesson:l,fa:fa)));
 Widget account()=>ListView(padding:const EdgeInsets.all(20),children:[const SizedBox(height:18),const Center(child:SizedBox(width:110,height:100,child:CustomPaint(painter:CaracalMarkPainter()))),const SizedBox(height:14),Center(child:Text(t('حساب کاربری','YOUR ACCOUNT'),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:22))),const SizedBox(height:10),Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(15)),child:Text(t('ورود، عضویت و همگام‌سازی حساب پس از اتصال امن به Supabase فعال می‌شود. در این نسخه هیچ حساب یا اطلاعاتی به سرور ارسال نمی‌شود.','Sign-in, registration and account sync require a secure Supabase connection. This build does not send account data to a server.'),style:const TextStyle(color:Colors.white70,height:1.8))),const SizedBox(height:14),ListTile(leading:const Icon(Icons.admin_panel_settings,color:silver),title:Text(t('مدیریت مالک و ادمین‌ها','Owner & Admin Management')),subtitle:Text(t('پس از راه‌اندازی بک‌اند و احراز هویت فعال می‌شود.','Available after backend and authentication setup.'))),ListTile(leading:const Icon(Icons.settings,color:silver),title:Text(t('تنظیمات','Settings')),onTap:openSettings)]);
 void openSettings()=>showModalBottomSheet(context:context,backgroundColor:panel,builder:(ctx)=>StatefulBuilder(builder:(ctx,setSheet)=>SafeArea(child:Padding(padding:const EdgeInsets.all(20),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(t('تنظیمات','SETTINGS'),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:18)),SwitchListTile(value:sound,onChanged:(v){setState(()=>sound=v);setSheet(()=>{});},title:Text(t('افکت صوتی','Sound effects')),subtitle:Text(t('کلید آماده‌سازی تنظیم صدا؛ فایل صوتی هنوز به پروژه اضافه نشده است.','Sound preference switch; audio assets are not bundled yet.'))),ListTile(leading:const Icon(Icons.language),title:Text(t('زبان برنامه','App language')),trailing:TextButton(onPressed:(){setState(()=>fa=!fa);Navigator.pop(ctx);},child:Text(fa?'English':'فارسی'))),const SizedBox(height:8)])))));
}

class LessonScreen extends StatelessWidget {
 final Lesson lesson; final bool fa;
 const LessonScreen({super.key,required this.lesson,required this.fa});
 @override Widget build(BuildContext context)=>Directionality(textDirection:fa?TextDirection.rtl:TextDirection.ltr,child:Scaffold(appBar:AppBar(title:Text(fa?'آکادمی کاراکال':'CARACAL ACADEMY')),body:ListView(padding:const EdgeInsets.all(20),children:[Container(height:155,decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),gradient:const LinearGradient(colors:[Color(0xFF393D42),Colors.black])),child:Icon(lesson.icon,color:silver,size:68)),const SizedBox(height:24),Text(fa?lesson.fa:lesson.en,style:const TextStyle(fontSize:26,fontWeight:FontWeight.w900)),const SizedBox(height:10),Text(fa?lesson.sub:'Technical lesson',style:const TextStyle(color:silver)),const SizedBox(height:22),Text(fa?lesson.bodyFa:lesson.bodyEn,style:const TextStyle(fontSize:16,height:1.9,color:Colors.white70)),const SizedBox(height:24),Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:panel,borderRadius:BorderRadius.circular(13)),child:Text(fa?'یادآوری: این محتوا آموزشی است. برای کار عملی، دستورالعمل سازنده و اصول ایمنی را رعایت کنید.':'Note: This is educational content. Follow manufacturer procedures and workshop safety.',style:const TextStyle(color:silver,height:1.7)))])));
}
