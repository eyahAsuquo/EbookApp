import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ebook_app/controllers/onboarding_controller.dart';
import 'package:ebook_app/core/constants/app_colors.dart';
import 'package:ebook_app/views/common_widgets/pepper_button.dart';
import 'package:ebook_app/views/common_widgets/sync_progress_bar.dart';
import 'package:ebook_app/views/library/library_screen.dart';
import 'package:ebook_app/views/onboarding/widgets/onboarding_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.auto_stories_rounded,
      'tag': 'Offline Reading',
      'title': 'Immersive Offline Reading',
      'description':
          'Enjoy rich stories without interruptions or internet connectivity. Customize fonts, spacing, and eye-friendly sepia and dark themes.',
    },
    {
      'icon': Icons.touch_app_rounded,
      'tag': 'Instant Lookup',
      'title': 'Tap-to-Define Inbuilt Dictionary',
      'description':
          'No more context switching between dictionary apps. Simply tap any word inside the ebook for instant phonetics, meanings, and examples.',
    },
    {
      'icon': Icons.offline_bolt_rounded,
      'tag': 'Zero Latency',
      'title': 'Local Engine & Vocabulary Bookmarks',
      'description':
          'The entire dictionary is indexed directly inside your phone. Bookmark intriguing words to build your personal offline vocabulary list.',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Start background SQLite extraction and database seeding immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OnboardingController>().startBackgroundSync();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding(BuildContext context) async {
    final controller = context.read<OnboardingController>();

    // If still seeding, wait briefly or show progress
    if (!controller.isSyncComplete && controller.syncProgress < 0.95) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Finalizing offline dictionary database... Just a moment!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await controller.completeOnboarding();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LibraryScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<OnboardingController>(
            builder: (context, controller, child) {
              if (controller.currentPage == _slides.length - 1) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () {
                  _pageController.animateToPage(
                    _slides.length - 1,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Slide Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  context.read<OnboardingController>().setPage(index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return OnboardingCard(
                    icon: slide['icon'] as IconData,
                    tag: slide['tag'] as String,
                    title: slide['title'] as String,
                    description: slide['description'] as String,
                  );
                },
              ),
            ),

            // Bottom Section: Background Sync Status & Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Consumer<OnboardingController>(
                builder: (context, controller, child) {
                  final isLast = controller.currentPage == _slides.length - 1;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Active background sync progress widget
                      SyncProgressBar(
                        progress: controller.syncProgress,
                        status: controller.syncStatus,
                        isComplete: controller.isSyncComplete,
                      ),
                      const SizedBox(height: 20),

                      // Dots Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (i) {
                          final isActive = controller.currentPage == i;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: isActive ? 24 : 6,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.pepperRed : AppColors.divider,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // Next or Get Started Button
                      PepperButton(
                        label: isLast ? 'Get Started' : 'Next',
                        icon: isLast ? Icons.arrow_forward_rounded : null,
                        width: double.infinity,
                        isLoading: isLast && !controller.isSyncComplete && controller.syncProgress < 0.2,
                        onPressed: () {
                          if (isLast) {
                            _finishOnboarding(context);
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

