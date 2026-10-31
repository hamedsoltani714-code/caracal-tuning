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
        scaffoldBackgroundColor: const Color(0xFF090909),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Color(0xFFB7B7B7),
        ),
        useMaterial3: true,
      ),
      home: const CaracalHome(),
    );
  }
}

class CaracalHome extends StatefulWidget {
  const CaracalHome({super.key});

  @override
  State<CaracalHome> createState() => _CaracalHomeState();
}

class _CaracalHomeState extends State<CaracalHome> {
  bool english = false;
  int selectedIndex = 0;

  final List<IconData> icons = [
    Icons.memory,
    Icons.speed,
    Icons.car_repair,
    Icons.school,
  ];

  final List<String> faTitles = [
    'آموزش ECU',
    'ریمپ موتور',
    'عیب‌یابی خودرو',
    'آکادمی تیونینگ',
  ];

  final List<String> enTitles = [
    'ECU Knowledge',
    'Engine Remapping',
    'Vehicle Diagnostics',
    'Tuning Academy',
  ];

  @override
  Widget build(BuildContext context) {
    final titles = english ? enTitles : faTitles;

    return Directionality(
      textDirection: english ? TextDirection.ltr : TextDirection.rtl,
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
              onPressed: () => setState(() => english = !english),
              child: Text(
                english ? 'FA' : 'EN',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: selectedIndex == 0
            ? _buildHome(titles)
            : _buildOtherPage(),
        bottomNavigationBar: NavigationBar(
          backgroundColor: const Color(0xFF171717),
          indicatorColor: Colors.white12,
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
              label: english ? 'Learning' : 'آموزش',
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

  Widget _buildHome(List<String> titles) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          height: 190,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF303030), Color(0xFF101010)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.pets,
                size: 65,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              const Text(
                'CARACAL TUNING',
                style: Text
