import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_typography.dart';

class OnboardingTutorial extends StatefulWidget {
  const OnboardingTutorial({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingTutorial> createState() => _OnboardingTutorialState();
}

class _OnboardingTutorialState extends State<OnboardingTutorial> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<TutorialStep> _steps = [
    TutorialStep(
      icon: Icons.waving_hand,
      title: 'Welcome to FBLA HIVE!',
      description: 'Connect with FBLA members, share achievements, and grow your professional network.',
      primaryColor: const Color(0xFF1976D2),
    ),
    TutorialStep(
      icon: Icons.home_rounded,
      title: 'Your Home Feed',
      description: 'View posts from FBLA members, like, comment, and save posts to read later.',
      primaryColor: const Color(0xFF2196F3),
    ),
    TutorialStep(
      icon: Icons.add_circle_rounded,
      title: 'Create Posts',
      description: 'Share your FBLA experiences, achievements, and insights with tags for easy discovery.',
      primaryColor: const Color(0xFF42A5F5),
    ),
    TutorialStep(
      icon: Icons.share_rounded,
      title: 'Cross-Platform Sharing',
      description: 'Connect your social media accounts to share posts across Facebook, X, Instagram, and LinkedIn.',
      primaryColor: const Color(0xFF64B5F6),
    ),
    TutorialStep(
      icon: Icons.person_rounded,
      title: 'Customize Your Profile',
      description: 'Add your bio, chapter, events, and profile picture to help others connect with you.',
      primaryColor: const Color(0xFF1565C0),
    ),
    TutorialStep(
      icon: Icons.notifications_rounded,
      title: 'Stay Updated',
      description: 'Get notifications when someone likes or comments on your posts. Customize in settings.',
      primaryColor: const Color(0xFF1976D2),
    ),
    TutorialStep(
      icon: Icons.settings_rounded,
      title: 'Personalize Your Experience',
      description: 'Adjust theme colors, font size, and notification preferences to make the app yours.',
      primaryColor: const Color(0xFF2196F3),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      _completeTutorial();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      widget.onComplete();
    }
  }

  void _skipTutorial() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Skip Tutorial?', style: AppTypography.subsectionHeading(context)),
        content: Text('You can always view this tutorial again from Settings.', style: AppTypography.bodyMedium(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continue Tutorial', style: AppTypography.button(context)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _completeTutorial();
            },
            child: Text('Skip', style: AppTypography.button(context)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentStep = _steps[_currentStep];

    return Material(
      color: theme.brightness == Brightness.dark 
          ? Colors.black.withOpacity(0.9)
          : Colors.white.withOpacity(0.95),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  onPressed: _skipTutorial,
                  icon: const Icon(Icons.close),
                  label: Text('Skip', style: AppTypography.button(context)),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Content
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Icon with gradient background
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            currentStep.primaryColor.withOpacity(0.3),
                            currentStep.primaryColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        currentStep.icon,
                        size: 56,
                        color: currentStep.primaryColor,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Title
                    Text(
                      currentStep.title,
                      style: AppTypography.sectionHeading(context),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      currentStep.description,
                      style: AppTypography.bodyLarge(context, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Progress indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentStep ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentStep
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 32),
              
              // Navigation buttons
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: theme.colorScheme.primary),
                        ),
                        child: Text('Back', style: AppTypography.button(context)),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: _currentStep == 0 ? 1 : 1,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      child: Text(
                        _currentStep == _steps.length - 1 ? 'Get Started' : 'Next',
                        style: AppTypography.button(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TutorialStep {
  final IconData icon;
  final String title;
  final String description;
  final Color primaryColor;

  TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.primaryColor,
  });
}

// Check if onboarding should be shown
class OnboardingHelper {
  static Future<bool> shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('onboarding_completed') ?? false);
  }

  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', false);
  }
}
