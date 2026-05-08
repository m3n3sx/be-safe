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
  final _referral = TextEditingController();
  bool _isRegister = false;
  bool _ageConfirmed = false;
  bool _acceptedTerms = false;

  Future<void> _submit() async {
    if (_isRegister) {
      if (!_ageConfirmed) return _show('Musisz potwierdzić że masz 13 lat lub więcej');
      if (!_acceptedTerms) return _show('Musisz zaakceptować regulamin i politykę prywatności');
      if (_password.text.length < 6) return _show('Hasło musi mieć min. 6 znaków');
    }
    final auth = context.read<AuthProvider>();
    final ok = _isRegister
        ? await auth.register(_email.text, _password.text, _username.text, referralCode: _referral.text)
        : await auth.login(_email.text, _password.text);
    if (!ok && mounted) _show(_isRegister ? 'Błąd rejestracji' : 'Błędny email lub hasło');
  }

  void _show(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text('🛡️ be:Safe', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Bezpieczeństwo w Twoich rękach', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),

              if (_isRegister)
                TextField(controller: _username, decoration: InputDecoration(labelText: S.get('username'), border: const OutlineInputBorder())),
              if (_isRegister) const SizedBox(height: 12),

              TextField(controller: _email, decoration: InputDecoration(labelText: S.get('email'), border: const OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),

              TextField(controller: _password, decoration: InputDecoration(labelText: S.get('password'), border: const OutlineInputBorder()), obscureText: true),

              if (_isRegister) ...[
                const SizedBox(height: 12),
                TextField(controller: _referral,
                  decoration: const InputDecoration(
                    labelText: 'Kod polecający (opcjonalnie)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.card_giftcard),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _ageConfirmed,
                  onChanged: (v) => setState(() => _ageConfirmed = v ?? false),
                  title: const Text('Mam ukończone 13 lat', style: TextStyle(fontSize: 13)),
                  contentPadding: EdgeInsets.zero, dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                  title: RichText(text: TextSpan(
                    style: TextStyle(fontSize: 13, color: cs.onSurface),
                    children: [
                      const TextSpan(text: 'Akceptuję '),
                      TextSpan(
                        text: 'Regulamin',
                        style: TextStyle(color: cs.primary, decoration: TextDecoration.underline),
                        recognizer: null,
                      ),
                      const TextSpan(text: ' i '),
                      TextSpan(
                        text: 'Politykę prywatności',
                        style: TextStyle(color: cs.primary, decoration: TextDecoration.underline),
                      ),
                    ],
                  )),
                  contentPadding: EdgeInsets.zero, dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                Padding(padding: const EdgeInsets.only(left: 36),
                  child: Row(children: [
                    TextButton(onPressed: () => Navigator.pushNamed(context, '/terms'), child: const Text('Regulamin', style: TextStyle(fontSize: 11))),
                    TextButton(onPressed: () => Navigator.pushNamed(context, '/privacy'), child: const Text('Polityka', style: TextStyle(fontSize: 11))),
                  ]),
                ),
              ],

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.loading ? null : _submit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
                  child: auth.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isRegister ? S.get('register') : S.get('login'), style: const TextStyle(fontSize: 16)),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _isRegister = !_isRegister;
                  _ageConfirmed = false;
                  _acceptedTerms = false;
                }),
                child: Text(_isRegister ? S.get('has_account') : S.get('no_account')),
              ),
              const SizedBox(height: 12),
              Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('lub', style: TextStyle(color: Colors.grey.shade500))), const Expanded(child: Divider())]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: auth.loading ? null : () async {
                    if (_isRegister && (!_ageConfirmed || !_acceptedTerms)) {
                      return _show('Zaakceptuj wiek 13+ i regulamin');
                    }
                    await context.read<AuthProvider>().loginWithGoogle(referralCode: _isRegister ? _referral.text : null);
                  },
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                  icon: const Icon(Icons.account_circle, size: 20),
                  label: const Text('Kontynuuj z Google', style: TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: auth.loading ? null : () async {
                  await context.read<AuthProvider>().demoLogin();
                },
                icon: const Icon(Icons.explore, size: 18),
                label: const Text('Wypróbuj bez rejestracji (tryb demo)', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
