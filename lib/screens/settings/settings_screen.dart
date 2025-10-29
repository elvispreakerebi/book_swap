import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as appAuth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../ui/app_bottom_nav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  void _showProfileSheet(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nameController = TextEditingController(text: user?.displayName ?? '');
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    // No confirmPwController
    final _formKey = GlobalKey<FormState>();
    bool isLoading = false;
    String? errorMessage;
    bool showCurrentPassword = false;
    bool showNewPassword = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 18,
            right: 18,
            top: 30,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Edit Profile',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Name required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Change Password',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: currentPwController,
                    obscureText: !showCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'Current password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showCurrentPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.pink,
                        ),
                        onPressed: () {
                          setState(() {
                            showCurrentPassword = !showCurrentPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: newPwController,
                    obscureText: !showNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.pink,
                        ),
                        onPressed: () {
                          setState(() {
                            showNewPassword = !showNewPassword;
                          });
                        },
                      ),
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && v.length < 6) {
                        return 'Use at least 6 chars';
                      }
                      return null;
                    },
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 13),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size.fromHeight(48),
                            side: const BorderSide(color: Colors.pink),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            minimumSize: const Size.fromHeight(48),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate())
                                    return;
                                  setState(() {
                                    isLoading = true;
                                    errorMessage = null;
                                  });
                                  try {
                                    // Update displayName
                                    if (user != null &&
                                        user.displayName !=
                                            nameController.text.trim()) {
                                      final newName = nameController.text
                                          .trim();
                                      await user.updateDisplayName(newName);
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid)
                                          .update({'displayName': newName});
                                    }
                                    // Change password if filled
                                    if (currentPwController.text.isNotEmpty &&
                                        newPwController.text.isNotEmpty) {
                                      final cred = EmailAuthProvider.credential(
                                        email: user!.email!,
                                        password: currentPwController.text
                                            .trim(),
                                      );
                                      await user.reauthenticateWithCredential(
                                        cred,
                                      );
                                      await user.updatePassword(
                                        newPwController.text.trim(),
                                      );
                                    }
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Profile updated!'),
                                        ),
                                      );
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    setState(() {
                                      errorMessage = e.message;
                                      isLoading = false;
                                    });
                                  }
                                  setState(() {
                                    isLoading = false;
                                  });
                                },
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.3,
                                  ),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Colors.pink),
            title: const Text('Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showProfileSheet(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Log Out'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Provider.of<appAuth.AuthProvider>(
                context,
                listen: false,
              ).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (idx) {
          switch (idx) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/my_listings');
              break;
            case 2:
              context.go('/settings');
              break;
          }
        },
      ),
    );
  }
}
