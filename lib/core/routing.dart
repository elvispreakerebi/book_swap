import '../screens/auth/welcome_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import 'package:go_router/go_router.dart';

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
    ],
  );
}
