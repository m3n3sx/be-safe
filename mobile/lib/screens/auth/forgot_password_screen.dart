import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/design_tokens.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _api = ApiService();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool _isValidEmail(String s) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _error = 'Podaj prawidłowy adres e-mail');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _api.post('/auth/forgot-password', {'email': email});
      if (!mounted) return;
      setState(() {
        _sent = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Backend zawsze zwraca 200 (anti-enumeration), więc traktujemy
      // network error jako ogólny fail
      setState(() {
        _loading = false;
        _sent = true; // i tak pokazujemy success — backend wysłał lub nie istnieje
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SerenityColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Wróć',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _sent ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text(
          'Odzyskaj hasło',
          style: SerenityText.headlineHero.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 12),
        Text(
          'Podaj adres e-mail powiązany z kontem. Wyślemy link do zresetowania hasła.',
          style: SerenityText.bodyMain.copyWith(
            color: SerenityColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _loading ? null : _submit(),
          decoration: InputDecoration(
            labelText: 'E-mail',
            prefixIcon: const Icon(Icons.email_outlined),
            errorText: _error,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: SerenityShapes.pill()),
          ),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Wyślij link'),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Wróć do logowania'),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: SerenityColors.primaryContainer,
        ),
        const SizedBox(height: 24),
        Text(
          'Sprawdź skrzynkę',
          style: SerenityText.headlineHero.copyWith(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Jeśli adres ${_email.text.trim()} jest powiązany z kontem, wysłaliśmy na niego link do resetu hasła. Sprawdź także spam.',
          style: SerenityText.bodyMain.copyWith(
            color: SerenityColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: SerenityShapes.pill()),
          ),
          child: const Text('Wróć do logowania'),
        ),
      ],
    );
  }
}
