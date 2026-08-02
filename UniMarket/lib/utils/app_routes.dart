import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

import '../screens/chat/chat_screen.dart';
import '../screens/sell/sell_screen.dart';
import '../screens/wishlist/wishlist_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/product_details/product_details_screen.dart';
import '../screens/auth/auth_wrapper.dart';
import '../screens/notifications/notification_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes {
    return {
      AppConstants.rootRoute: (context) => const AuthWrapper(),
      AppConstants.loginRoute: (context) => const LoginScreen(),
      AppConstants.signupRoute: (context) => const SignupScreen(),
      AppConstants.productDetailsRoute: (context) => const ProductDetailsScreen(),
      AppConstants.chatRoute: (context) => const ChatScreen(),
      AppConstants.sellRoute: (context) => const SellScreen(),
      AppConstants.wishlistRoute: (context) => const WishlistScreen(),
      AppConstants.cartRoute: (context) => const CartScreen(),
      AppConstants.profileRoute: (context) => const ProfileScreen(),
      AppConstants.notificationsRoute: (context) => const NotificationScreen(),
    };
  }
}
