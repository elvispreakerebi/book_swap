import '../screens/auth/welcome_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../screens/post_book/post_book_screen.dart';
import '../screens/home/listing_details_screen.dart';

class AppRouter {
  static final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final showSnackbar = state.extra == true;
          return LoginScreen(showAccountCreatedSnackbar: showSnackbar);
        },
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/listing/:id',
        builder: (context, state) {
          final listingId = state.pathParameters['id']!;
          return ListingDetailsScreen(listingId: listingId);
        },
      ),
      GoRoute(
        path: '/my_listings',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('My Listings')),
          body: const Center(child: Text('My Listings')),
        ),
      ),
      GoRoute(
        path: '/chats',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Chats')),
          body: const Center(child: Text('Chats')),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: const Center(child: Text('Settings')),
        ),
      ),
      GoRoute(
        path: '/post_book',
        builder: (context, state) => const PostBookScreen(),
      ),
    ],
  );
}
