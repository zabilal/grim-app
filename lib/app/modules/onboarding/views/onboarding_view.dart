import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:grim_app/app/routes/app_pages.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  _OnboardingViewState createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  final List<OnboardingPage> pages = [
    OnboardingPage(
      title: "GRIM EXECUTION",
      description:
          "Brutal productivity through disciplined execution. No excuses, only results.",
      icon: Icons.military_tech,
      color: Color(0xFF1a1a1a),
    ),
    OnboardingPage(
      title: "12 WEEK YEAR",
      description:
          "Achieve more in 12 weeks than most do in 12 months. Compress time, amplify focus.",
      icon: Icons.calendar_today,
      color: Color(0xFF2C2C2C),
    ),
    OnboardingPage(
      title: "DEEP WORK FOCUS",
      description:
          "4 hours of deep work daily. Block distractions. Build mastery.",
      icon: Icons.psychology,
      color: Color(0xFF3D3D3D),
    ),
    OnboardingPage(
      title: "HONOR WILL COME",
      description:
          "Stay committed. Execute relentlessly. Your future self will thank you.",
      icon: Icons.emoji_events,
      color: Color(0xFFFFD700),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            itemCount: pages.length,
            itemBuilder: (context, index) {
              return _buildPage(pages[index]);
            },
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => _buildDot(index),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: currentPage == pages.length - 1
                ? ElevatedButton(
                    onPressed: () => Get.offNamed(Routes.dashboard),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('BEGIN YOUR JOURNEY'),
                  )
                : TextButton(
                    onPressed: () => Get.offNamed(Routes.dashboard),
                    child: Text('SKIP'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Container(
      color: page.color,
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(page.icon, size: 120, color: Colors.white),
          SizedBox(height: 50),
          Text(
            page.title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          Text(
            page.description,
            style: TextStyle(fontSize: 18, color: Colors.white70, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      width: currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: currentPage == index ? Colors.white : Colors.white38,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
