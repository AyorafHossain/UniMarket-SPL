import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Constants & Utils
import 'constants/app_constants.dart';
import 'constants/app_colors.dart';
import 'utils/app_routes.dart';
import 'services/notification_service.dart';

// Providers
import 'providers/nav_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (wrapped in try-catch in case it's not configured yet)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, cart) => cart!..updateUserId(auth.user?.uid),
        ),
      ],
      child: const UniMarketApp(),
    ),
  );
}

class UniMarketApp extends StatefulWidget {
  const UniMarketApp({super.key});

  @override
  State<UniMarketApp> createState() => _UniMarketAppState();
}

class _UniMarketAppState extends State<UniMarketApp> {
  @override
  void initState() {
    super.initState();
    // Initialize Notification Service after a slight delay to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService().navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // Theme Data - Using Poppins for a modern, professional look
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.white,
          error: Colors.redAccent,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: AppColors.background,
        
        // Navigation Bar Theme
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.white,
          indicatorColor: AppColors.primary.withValues(alpha: 0.1),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      
      // Routing Configuration
      initialRoute: AppConstants.rootRoute,
      routes: AppRoutes.routes,
    );
  }
}
