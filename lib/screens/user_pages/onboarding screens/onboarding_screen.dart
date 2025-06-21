// ignore_for_file: library_private_types_in_public_api

import 'package:bikex/components/buttons.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                OnboardingPage(
                  title: "All your favourites",
                  description:
                      "Get all your loved foods in one place. You just place the order, and we do the rest.",
                  onNext: _goToNextPage,
                  onSkip: _skipToLastPage,
                  isLastPage: false,
                  currentPage: _currentPage,
                ),
                OnboardingPage(
                  title: "Order from chosen chef",
                  description:
                      "Customize your meals and order from your favorite chef with just a few clicks.",
                  onNext: _goToNextPage,
                  onSkip: _skipToLastPage,
                  isLastPage: false,
                  currentPage: _currentPage,
                ),
                OnboardingPage(
                  title: "Quick delivery",
                  description:
                      "Enjoy smooth delivery on all your orders for a limited time.",
                  onNext: _finishOnboarding,
                  onSkip: null,
                  isLastPage: true,
                  currentPage: _currentPage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goToNextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToLastPage() {
    _pageController.animateToPage(
      2, // Last page index
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _finishOnboarding() {
    // Handle finishing the onboarding (e.g., navigate to the home screen)
    Navigator.pushNamed(context, '/login');
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final bool isLastPage;
  final int currentPage;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.isLastPage,
    required this.currentPage,
    this.onNext,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Image placeholder
            Container(
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
              margin: EdgeInsets.only(top: 50),
              height: MediaQuery.of(context).size.height / 2.7,
              width: MediaQuery.of(context).size.width / 1.5,
            ),
            // Title and description
            Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            // Circle scroll (page indicator)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3, // Number of pages
                (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    color: currentPage == index ? Colors.orange : Colors.grey,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Custom buttons
            Column(
              children: isLastPage
                  ? [
                      elevatedButton(
                        "Get Started",
                        onNext!,
                      ),
                    ]
                  : [
                      elevatedButton(
                        "Next",
                        onNext!,
                      ),
                      textButton(
                        "Skip",
                        onSkip!,
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}


