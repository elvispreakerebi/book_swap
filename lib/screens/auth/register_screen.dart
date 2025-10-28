import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
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
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 24.0),
                child: Text(
                  'Create your BookSwap account to start exchanging books with fellow students.',
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
              TextFormField(
                controller: _displayNameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Display Name (optional)',
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
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
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                textInputAction: TextInputAction.done,
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
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await authProvider.register(
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                            displayName: _displayNameController.text.trim(),
                          );
                          if (authProvider.status == AuthStatus.success) {
                            if (mounted) {
                              context.go('/login', extra: true);
                            }
                          }
                        }
                      },
                      child: const Text(
                        'Create Account',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
              const SizedBox(height: 16),
              if (authProvider.status == AuthStatus.error &&
                  authProvider.errorMessage != null)
                Text(
                  authProvider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              if (authProvider.status == AuthStatus.success)
                Column(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Check your inbox and verify your email before logging in.',
                      style: TextStyle(color: Colors.green),
                      textAlign: TextAlign.center,
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
