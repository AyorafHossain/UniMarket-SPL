import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../main_screen.dart';
import 'login_screen.dart';
import 'verification_screen.dart';
import '../../constants/app_colors.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the auth state in the provider
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isCheckingAuth) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/app_icon.jpg',
                height: 120,
                width: 120,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.storefront,
                    size: 100,
                    color: AppColors.primary,
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'UniMarket',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your Campus Marketplace',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ],
          ),
        ),
      );
    }

    // If authenticated, show MainScreen, otherwise show LoginScreen
    if (authProvider.isAuthenticated) {
      if (authProvider.user != null && !authProvider.user!.emailVerified) {
        return const VerificationScreen();
      }
      return const MainScreen();
    } else {
      return const LoginScreen();
    }
  }
}
