/// be:Safe v2 — Login / Register Screen (Serenity Guard)
///
/// Calm hero (shield logo + tagline) above a clean card-like form.
/// Inputs use soft surfaceContainerLow fills, primary pill CTA,
/// Google OAuth + demo mode below.
///
/// Design source: design/stitch_v2/screens/logowanie/
library;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/design_tokens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  final _referral = TextEditingController();
  bool _isRegister = false;
  bool _ageConfirmed = false;
  bool _acceptedTerms = false;
  bool _obscurePass = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _username.dispose();
    _referral.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isRegister) {
      if (!_ageConfirmed) {
        return _show('Potwierdź że masz 13 lat lub więcej');
      }
      if (!_acceptedTerms) {
        return _show('Zaakceptuj regulamin i politykę prywatności');
      }
      if (_password.text.length < 6) {
        return _show('Hasło musi mieć min. 6 znaków');
      }
    }
    final auth = context.read<AuthProvider>();
    final ok = _isRegister
        ? await auth.register(
            _email.text,
            _password.text,
            _username.text,
            referralCode: _referral.text,
          )
        : await auth.login(_email.text, _password.text);
    if (!ok && mounted) {
      _show(_isRegister ? 'Błąd rejestracji' : 'Błędny email lub hasło');
    }
  }

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: SerenityColors.surfaceBright,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: SerenitySpacing.xl,
            vertical: SerenitySpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              _buildHero(),
              const SizedBox(height: 48),
              if (_isRegister) ...[
                _buildField(
                  controller: _username,
                  label: 'Nazwa użytkownika',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
              ],
              _buildField(
                controller: _email,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _password,
                label: 'Hasło',
                icon: Icons.lock_outline,
                obscure: _obscurePass,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePass ? Icons.visibility_off : Icons.visibility,
                    color: SerenityColors.onSurfaceVariant,
                    size: 20,
                  ),
                  tooltip: _obscurePass ? 'Pokaż hasło' : 'Ukryj hasło',
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              if (!_isRegister) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/forgot-password',
                    ),
                    child: Text(
                      'Zapomniałeś hasła?',
                      style: SerenityText.labelButton,
                    ),
                  ),
                ),
              ],
              if (_isRegister) ...[
                const SizedBox(height: 12),
                _buildField(
                  controller: _referral,
                  label: 'Kod polecający (opcjonalnie)',
                  icon: Icons.card_giftcard_outlined,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                _buildCheckbox(
                  value: _ageConfirmed,
                  onChanged: (v) => setState(() => _ageConfirmed = v ?? false),
                  label: const TextSpan(text: 'Mam ukończone 13 lat'),
                ),
                _buildCheckbox(
                  value: _acceptedTerms,
                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                  label: TextSpan(
                    style: SerenityText.bodyMain.copyWith(
                      fontSize: 13,
                      color: SerenityColors.primary,
                    ),
                    children: [
                      const TextSpan(text: 'Akceptuję '),
                      TextSpan(
                        text: 'Regulamin',
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap =
                              () => Navigator.pushNamed(context, '/terms'),
                      ),
                      const TextSpan(text: ' i '),
                      TextSpan(
                        text: 'Politykę prywatności',
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap =
                              () => Navigator.pushNamed(context, '/privacy'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _primaryPill(
                label: _isRegister ? 'Zarejestruj się' : 'Zaloguj się',
                onTap: auth.loading ? null : _submit,
                loading: auth.loading,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {
                  _isRegister = !_isRegister;
                  _ageConfirmed = false;
                  _acceptedTerms = false;
                }),
                child: Text(
                  _isRegister
                      ? 'Masz już konto? Zaloguj się'
                      : 'Nie masz konta? Zarejestruj się',
                  style: SerenityText.labelButton,
                ),
              ),
              const SizedBox(height: 16),
              _divider('lub'),
              const SizedBox(height: 16),
              _outlinePill(
                label: 'Kontynuuj z Google',
                icon: Icons.account_circle_outlined,
                onTap: auth.loading
                    ? null
                    : () async {
                        if (_isRegister &&
                            (!_ageConfirmed || !_acceptedTerms)) {
                          return _show('Zaakceptuj wiek 13+ i regulamin');
                        }
                        final ok =
                            await context.read<AuthProvider>().loginWithGoogle(
                                  referralCode:
                                      _isRegister ? _referral.text : null,
                                );
                        if (!ok && mounted) {
                          _show('Logowanie Google nie powiodło się');
                        }
                      },
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: auth.loading
                    ? null
                    : () async {
                        await context.read<AuthProvider>().demoLogin();
                      },
                icon: const Icon(
                  Icons.explore_outlined,
                  size: 18,
                  color: SerenityColors.onSurfaceVariant,
                ),
                label: Text(
                  'Tryb demo — bez rejestracji',
                  style: SerenityText.bodyMain.copyWith(fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                SerenityColors.glowSafeMint.withValues(alpha: 0.6),
                SerenityColors.glowSafeMint.withValues(alpha: 0),
              ],
              stops: const [0, 1],
            ),
          ),
          child: const Icon(
            Icons.shield,
            size: 44,
            color: SerenityColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'be:Safe',
          style: SerenityText.displayMd.copyWith(
            fontSize: 44,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bezpieczeństwo w Twoich rękach',
          style: SerenityText.bodyMain,
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: SerenityText.bodyMain.copyWith(color: SerenityColors.primary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: SerenityText.labelButton.copyWith(
          color: SerenityColors.onSurfaceVariant,
        ),
        prefixIcon: Icon(icon, color: SerenityColors.onSurfaceVariant, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: SerenityColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: SerenityShapes.input(),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SerenityShapes.input(),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SerenityShapes.input(),
          borderSide: BorderSide(color: SerenityColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required TextSpan label,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: SerenityColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: RichText(
                  text: TextSpan(
                    style: SerenityText.bodyMain.copyWith(
                      fontSize: 14,
                      color: SerenityColors.primary,
                    ),
                    children: [label],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryPill({
    required String label,
    required VoidCallback? onTap,
    bool loading = false,
  }) {
    final enabled = onTap != null && !loading;
    return Material(
      color: enabled
          ? SerenityColors.primaryContainer
          : SerenityColors.surfaceContainerHigh,
      borderRadius: SerenityShapes.pill(),
      child: InkWell(
        borderRadius: SerenityShapes.pill(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        SerenityColors.onPrimary,
                      ),
                    ),
                  )
                : Text(
                    label,
                    style: SerenityText.labelButton.copyWith(
                      fontSize: 16,
                      color: enabled
                          ? SerenityColors.onPrimary
                          : SerenityColors.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _outlinePill({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: SerenityShapes.pill(),
      child: InkWell(
        borderRadius: SerenityShapes.pill(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: SerenityShapes.pill(),
            border: Border.all(
              color: SerenityColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: SerenityColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: SerenityText.labelButton.copyWith(
                  fontSize: 15,
                  color: SerenityColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider(String text) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: SerenityColors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: SerenityText.labelCaps.copyWith(
              color: SerenityColors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: SerenityColors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
