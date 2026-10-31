import 'package:flutter/material.dart';

void main() {
  runApp(const CaracalApp());
}

class CaracalApp extends StatelessWidget {
  const CaracalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CARACAL TUNING',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080808),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Color(0xFFAAAAAA),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool english = false;
  int selectedIndex = 0;

  final List<IconData> icons = [
    Icons.memory,
    Icons.speed,
    Icons.car_repair,
    Icons.school,
  ];

  final List<String> englishTitles = [
    'ECU Knowledge',
    'Engine Remapping',
    'Diagnostics',
    'Tuning Academy',
  ];

  final List<String> persianTitles = [
    'آموزش ECU',
    'ریمپ موتور',
    'عیب‌یابی خودرو',
    'آکادمی تیونینگ',
  ];

  @override
  Widget build(BuildContext context) {
    final titles = english ? englishTitles : persianTitles;

    return Directionality(
      textDirection:
          english ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'CARACAL TUNING',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => english = !english);
              },
              child: Text(
                english ? 'FA' : 'EN',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: selectedIndex == 0
            ? _home(titles)
            : Center(
                child: Text(
                  english
                      ? 'Coming Soon'
                      : 'این بخش به‌زودی فعال می‌شود',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: const Color(0xFF151515),
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            setState(() => selectedIndex = index);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              label: english ? 'Home' : 'خانه',
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              label: english ? 'Library' : 'آموزش',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              label: english ? 'Account' : 'حساب کاربری',
            ),
          ],
        ),
      ),
    );
  }

  Widget _home(List<String> titles) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 190,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon
