import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/i18n.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  bool _isRegister = false;

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final ok = _isRegister
        ? await auth.register(_email.text, _password.text, _username.text)
        : await auth.login(_email.text, _password.text);
    if (ok && mounted) {} // AuthGate handles navigation
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🛡️ be:Safe', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Bezpieczeństwo w Twoich rękach', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              if (_isRegister) TextField(controller: _username, decoration: InputDecoration(labelText: S.get('username'), border: const OutlineInputBorder())),
              if (_isRegister) const SizedBox(height: 12),
              TextField(controller: _email, decoration: InputDecoration(labelText: S.get('email'), border: const OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              TextField(controller: _password, decoration: InputDecoration(labelText: S.get('password'), border: const OutlineInputBorder()), obscureText: true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.loading ? null : _submit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: const Color(0xFF2979FF)),
                  child: auth.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isRegister ? S.get('register') : S.get('login'), style: const TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _isRegister = !_isRegister),
                child: Text(_isRegister ? S.get('has_account') : S.get('no_account')),
              ),
              const SizedBox(height: 12),
              Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('lub', style: TextStyle(color: Colors.grey.shade500))), const Expanded(child: Divider())]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: auth.loading ? null : () async {
                    final ok = await context.read<AuthProvider>().loginWithGoogle();
                    if (ok && mounted) Navigator.pushReplacementNamed(context, '/map');
                  },
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                  icon: Image.network('https://www.google.com/favicon.ico', width: 20, height: 20, errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata)),
                  label: const Text('Kontynuuj z Google', style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
