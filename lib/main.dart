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
        scaffoldBackgroundColor: const Color(0xFF101010),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC0C0C0),
          secondary: Colors.white,
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
  bool isPersian = true;
  int selectedIndex = 0;

  final List<IconData> icons = [
    Icons.memory,
    Icons.speed,
    Icons.car_repair,
    Icons.school,
  ];

  @override
  Widget build(BuildContext context) {
    final titles = isPersian
        ? ['آموزش ECU', 'ریمپ موتور', 'عیب‌یابی خودرو', 'آکادمی تیونینگ']
        : ['ECU Training', 'Engine Remap', 'Car Diagnostics', 'Tuning Academy'];

    return Scaffold(
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
              setState(() {
                isPersian = !isPersian;
              });
            },
            child: Text(
              isPersian ? 'EN' : 'فا',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: selectedIndex == 0
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.black, Color(0xFF383838)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.pets,
                          size: 65,
                          color: Color(0xFFC0C0C0),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'CARACAL TUNING',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'DRIVE • LEARN • UPGRADE',
                          style: TextStyle(
                            color: Colors.grey,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          isPersian
                              ? 'به دنیای تخصصی تیونینگ خوش آمدید'
                              : 'Welcome to the world of tuning',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    isPersian ? 'دسته‌بندی‌ها' : 'Categories',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: titles.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    itemBuilder: (context, index) {
                      return Card(
                        color: const Color(0xFF202020),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: const BorderSide(color: Colors.white12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(titles[index]),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icons[index],
                                size: 38,
                                color: const Color(0xFFC0C0C0),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                titles[index],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            )
          : Center(
              child: Text(
                selectedIndex == 1
                    ? (isPersian ? 'بخش آموزش' : 'Learning')
                    : (isPersian ? 'حساب کاربری' : 'Account'),
                style: const TextStyle(fontSize: 24),
              ),
            ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.black,
        indicatorColor: Colors.white12,
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: isPersian ? 'خانه' : 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book),
            label: isPersian ? 'آموزش' : 'Learning',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            label: isPersian ? 'حساب' : 'Account',
          ),
        ],
      ),
    );
  }
}
