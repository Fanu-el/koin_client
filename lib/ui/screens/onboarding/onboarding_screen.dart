import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<OnboardingFeature> features = [
    OnboardingFeature(
      title: 'Track Your Spending',
      description: 'Monitor all your transactions in one place with detailed insights and categorization.',
      icon: Icons.receipt_long,
      color: const Color(0xFF6366F1),
    ),
    OnboardingFeature(
      title: 'Smart Budgeting',
      description: 'Set budgets for each category and get alerts when you\'re about to exceed limits.',
      icon: Icons.pie_chart,
      color: const Color(0xFF8B5CF6),
    ),
    OnboardingFeature(
      title: 'Savings Goals',
      description: 'Define your goals and watch your savings grow with progress tracking.',
      icon: Icons.flag,
      color: const Color(0xFF06B6D4),
    ),
    OnboardingFeature(
      title: 'AI Financial Advisor',
      description: 'Get personalized spending recommendations from your AI financial advisor.',
      icon: Icons.auto_awesome,
      color: const Color(0xFF10B981),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: features.length,
                itemBuilder: (context, index) {
                  final feature = features[index];
                  return OnboardingPage(feature: feature);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      features.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentPage == index ? 32 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == index
                              ? features[index].color
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Action buttons
                  Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: const Text('Back'),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage == features.length - 1) {
                              _completeOnboarding();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Text(
                            _currentPage == features.length - 1 ? 'Get Started' : 'Next',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_currentPage == 0)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingFeature {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingFeature({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingFeature feature;

  const OnboardingPage({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              feature.icon,
              size: 60,
              color: feature.color,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            feature.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            feature.description,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
