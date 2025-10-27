
import 'package:go_router/go_router.dart';
import 'package:myapp/screens/auth/welcome_screen.dart';

class AppRouter {
  static final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
      ),
      // Add other routes here
    ],
  );
}
