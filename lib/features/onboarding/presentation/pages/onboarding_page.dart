import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/strings/onboarding_strings.dart';
import '../../../../core/theme/motion.dart';
import '../../../../shared/widgets/entrance.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _slides = [
    _Slide(
      icon: Icons.forum_outlined,
      title: OnboardingStrings.talkTitle,
      description: OnboardingStrings.talkDescription,
    ),
    _Slide(
      icon: Icons.photo_camera_outlined,
      title: OnboardingStrings.worldTitle,
      description: OnboardingStrings.worldDescription,
    ),
    _Slide(
      icon: Icons.bolt_outlined,
      title: OnboardingStrings.actionsTitle,
      description: OnboardingStrings.actionsDescription,
    ),
  ];

  final _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() => context.go(AppRoutes.home);

  void _next() {
    if (_isLastPage) {
      _finish();
      return;
    }
    // La página se desplaza dentro de la pantalla: curva de ida y vuelta.
    _pageController.nextPage(duration: Motion.page, curve: Motion.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text(OnboardingStrings.skip),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged:
                      (index) => setState(() => _currentPage = index),
                  itemBuilder:
                      (context, index) => _SlideView(slide: _slides[index]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: Motion.enter,
                      curve: Motion.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _currentPage ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color:
                            i == _currentPage
                                ? scheme.primary
                                : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _next,
                child: Text(
                  _isLastPage
                      ? OnboardingStrings.start
                      : OnboardingStrings.next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Solo se ve una vez: aquí sí vale la pena una entrada escalonada.
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Entrance(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 56, color: scheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: 40),
        Entrance(
          delay: Motion.stagger,
          child: Text(
            slide.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 12),
        Entrance(
          delay: Motion.stagger * 2,
          child: Text(
            slide.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
