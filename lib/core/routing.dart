import 'package:go_router/go_router.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/register_screen.dart';

class AppRouter {
  static final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Add other routes here
    ],
  );
}
