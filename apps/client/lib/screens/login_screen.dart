import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';

import '../providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(servicesProvider).auth;
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (_isSignUp) {
        await auth.signUpEmail(email, password);
      } else {
        await auth.signInEmail(email, password);
      }
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signIn(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(servicesProvider).auth;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Center(child: BrandMark()),
              const SizedBox(height: 8),
              Text(
                'Connect the public with trail builders,\nnonprofits, and associations.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: TqColors.slate,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Report issues. Find work. Get trails fixed.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: TqColors.forestGreen,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              TqPrimaryButton(
                label: _loading
                    ? 'Please wait…'
                    : (_isSignUp ? 'Create Account' : 'Sign In'),
                onPressed: _loading ? null : _submitEmail,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(
                  _isSignUp
                      ? 'Already have an account? Sign in'
                      : 'Need an account? Sign up',
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              TqOutlineButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata,
                onPressed: _loading
                    ? null
                    : () => _signIn(auth.signInGoogle),
              ),
              const SizedBox(height: 12),
              TqOutlineButton(
                label: 'Continue with Apple',
                icon: Icons.apple,
                onPressed: _loading
                    ? null
                    : () => _signIn(auth.signInApple),
              ),
              const SizedBox(height: 12),
              TqOutlineButton(
                label: 'Continue as Guest',
                icon: Icons.person_outline,
                onPressed: _loading
                    ? null
                    : () => _signIn(auth.signInAnonymously),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
