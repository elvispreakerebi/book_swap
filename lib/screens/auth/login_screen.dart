import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  final bool showAccountCreatedSnackbar;
  const LoginScreen({super.key, this.showAccountCreatedSnackbar = false});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.showAccountCreatedSnackbar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created successfully! Check your email to verify your account.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.pink),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email required';
                  if (!value.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.pink,
                    ),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) return 'Min 6 chars';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              authProvider.status == AuthStatus.loading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final success = await authProvider.login(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                            );
                            if (success) {
                              if (mounted) context.go('/home');
                            } else if (authProvider.errorMessage != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(authProvider.errorMessage!),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
              // Inline visible error for debug, so nothing is hidden
              if (authProvider.status == AuthStatus.error &&
                  authProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    authProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Don\'t have an account?'),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Create one'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (authProvider.canResendVerification)
                TextButton(
                  onPressed: authProvider.resendVerificationLink,
                  child: const Text('Resend verification email'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
