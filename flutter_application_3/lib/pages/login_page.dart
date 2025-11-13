import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_service.dart';
import '../providers/user_provider.dart';
import '../providers/app_settings_provider.dart';
import '../utils/app_typography.dart';
import 'signup_page.dart';
import '../utils/page_transitions.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    final error = await authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      // On successful login, sync UserProvider with Firebase user data
      final userProvider = context.read<UserProvider>();
      final settingsProvider = context.read<AppSettingsProvider>();
      final user = authService.user;
      if (user != null) {
        try {
          // Set user ID in providers to enable Firebase sync
          userProvider.setUserId(user.uid);
          settingsProvider.setUserId(user.uid);
          
          // Load previously saved user data for this email (username, profile pic)
          if (user.email != null && user.email!.isNotEmpty) {
            await userProvider.loadUserDataForEmail(user.email!);
          }
          
          // Update display name and email from Firebase Auth if not already set
          if (user.displayName != null && user.displayName!.isNotEmpty) {
            await userProvider.updateDisplayName(user.displayName!);
          }
          if (user.email != null && user.email!.isNotEmpty) {
            await userProvider.updateEmail(user.email!);
          }
        } catch (e) {
          // If updating fails, continue anyway
        }
      }
    }
  }

  Future<void> _resetPassword() async {
    final emailController = TextEditingController(text: _emailController.text.trim());

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Reset Password', style: AppTypography.subsectionHeading(context)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your email address to receive a password reset link:',
                style: AppTypography.bodyMedium(context),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'You will receive an email with a link to reset your password. Check your spam folder if you don\'t see it.',
                  style: AppTypography.caption(context),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: AppTypography.button(context)),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your email')),
                  );
                  return;
                }

                // Send password reset email
                final authService = context.read<AuthService>();
                final error = await authService.resetPassword(email);
                
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  
                  if (error == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset email sent! Check your inbox.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text('Send Reset Link', style: AppTypography.button(context)),
            ),
          ],
        );
      },
    );

    // Clean up controller
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // FBLA HIVE Text - Outfit Black
                Center(
                  child: Text(
                    'FBLA HIVE',
                    style: AppTypography.appTitle(context, color: Colors.black).copyWith(
                      fontSize: 36,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                // FBLA Logo
                Center(
                  child: Container(
                    width: 132, // 120 * 1.1 = 132
                    height: 132,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(7.5), // Reduced further to make image 40% larger
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          1.2, 0, 0, 0, 0, // Red channel (increase contrast)
                          0, 1.2, 0, 0, 0, // Green channel
                          0, 0, 1.2, 0, 0, // Blue channel
                          0, 0, 0, 1, 0,   // Alpha channel
                        ]),
                        child: Image.asset(
                          'assets/images/bee_logo_white.png',
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.hexagon,
                              size: 126, // 90 * 1.4 = 126
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome Back',
                  style: AppTypography.pageTitle(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: AppTypography.bodyLarge(context, color: theme.hintColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Identifier Field (Email or Username)
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email or Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email or username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: Text('Forgot Password?', style: AppTypography.button(context)),
                  ),
                ),
                const SizedBox(height: 16),

                // Sign In Button
                Consumer<AuthService>(
                  builder: (context, authService, _) {
                    return ElevatedButton(
                      onPressed: authService.isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: authService.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Sign In',
                              style: AppTypography.button(context),
                            ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ", style: AppTypography.bodyMedium(context)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          FadePageRoute(page: const SignUpPage()),
                        );
                      },
                      child: Text('Sign Up', style: AppTypography.button(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
