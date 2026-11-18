import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ebook_app_desktop/controllers/onboarding_controller.dart';
import 'package:ebook_app_desktop/core/constants/app_colors.dart';
import 'package:ebook_app_desktop/views/common_widgets/pepper_button.dart';
import 'package:ebook_app_desktop/views/common_widgets/sync_progress_bar.dart';
import 'package:ebook_app_desktop/views/library/library_screen.dart';
import 'package:ebook_app_desktop/views/onboarding/widgets/onboarding_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
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

    if (!controller.canProceedToApp) {
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
              if (controller.isLastPage) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () {
                  final lastIndex = controller.totalSlides - 1;
                  controller.setPage(lastIndex);
                  _pageController.animateToPage(
                    lastIndex,
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
        child: Consumer<OnboardingController>(
          builder: (context, controller, child) {
            final slides = controller.slides;

            return Column(
              children: [
                // Slide Carousel
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: slides.length,
                    onPageChanged: (index) {
                      controller.setPage(index);
                    },
                    itemBuilder: (context, index) {
                      final slide = slides[index];
                      return OnboardingCard(
                        icon: slide.icon,
                        tag: slide.tag,
                        title: slide.title,
                        description: slide.description,
                      );
                    },
                  ),
                ),

                // Bottom Section: Background Sync Status & Navigation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
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
                        children: List.generate(slides.length, (i) {
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
                        label: controller.isLastPage ? 'Get Started' : 'Next',
                        icon: controller.isLastPage ? Icons.arrow_forward_rounded : null,
                        width: double.infinity,
                        isLoading: controller.isLastPage && !controller.canProceedToApp,
                        onPressed: () {
                          if (controller.isLastPage) {
                            _finishOnboarding(context);
                          } else {
                            final nextIndex = controller.currentPage + 1;
                            controller.setPage(nextIndex);
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
