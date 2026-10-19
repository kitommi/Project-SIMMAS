import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/simmas_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/simmas_logo.dart';
import 'auth_controller.dart';
import 'login_branding.dart';

final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.auth});

  final AuthController auth;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _success = false;
  bool _submitted = false;
  String? _serverError;

  static const _demoAccounts = [
    ('admin@simmas.sch.id', 'Admin'),
    ('guru@simmas.sch.id', 'Guru'),
    ('siswa@simmas.sch.id', 'Siswa'),
  ];

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // Pesan validasi sama dengan skema zod situs asli.
  String? _validateEmail(String? value) {
    if (_serverError != null) return _serverError;
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Email wajib diisi';
    if (!_emailRegex.hasMatch(text)) return 'Format email tidak valid';
    return null;
  }

  String? _validatePassword(String? value) =>
      (value == null || value.isEmpty) ? 'Password wajib diisi' : null;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _serverError = null;
      _submitted = true;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    final result = await widget.auth.signIn(
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;

    if (result.success) {
      setState(() => _success = true);
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      context.go(result.user!.role.homePath);
    } else {
      setState(() {
        _loading = false;
        _serverError = result.error; // tampil di field email (setError('email'))
      });
      _formKey.currentState?.validate();
    }
  }

  Future<void> _forgotPassword() async {
    final messenger = ScaffoldMessenger.of(context);
    final email = _email.text.trim();
    if (!_emailRegex.hasMatch(email)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Isi email sekolah Anda terlebih dahulu.')),
      );
      return;
    }
    try {
      await widget.auth.sendPasswordReset(email);
      messenger.showSnackBar(
        const SnackBar(content: Text('Tautan reset password telah dikirim ke email Anda.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Gagal mengirim tautan reset. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) return const _SuccessOverlay();

    final c = context.sc;
    return Scaffold(
      backgroundColor: c.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final isDesktop = w >= Breakpoints.lg;
          final brandingWidth = w * (w >= Breakpoints.xl ? .42 : .46);
          final padX = w >= Breakpoints.xl
              ? 80.0
              : w >= Breakpoints.lg
                  ? 56.0
                  : w >= Breakpoints.sm
                      ? 48.0
                      : 24.0;

          final form = SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: padX, vertical: 32),
              child: ConstrainedBox(
                // Form selalu di tengah vertikal, tapi aman di landscape pendek.
                constraints: BoxConstraints(
                  minHeight: math.max(
                    0,
                    constraints.maxHeight -
                        64 -
                        MediaQuery.paddingOf(context).vertical,
                  ),
                ),
                child: Center(child: _buildFormCard(context, w, isDesktop)),
              ),
            ),
          );

          if (!isDesktop) return form;
          return Row(
            children: [
              SizedBox(
                width: brandingWidth,
                child: LoginBranding(onLogoTap: () => context.go('/')),
              ),
              Expanded(child: form),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, double w, bool isDesktop) {
    final c = context.sc;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDesktop) ...[
            InkWell(
              onTap: () => context.go('/'),
              borderRadius: BorderRadius.circular(12),
              child: const SimmasBrand(size: 36),
            ),
            const SizedBox(height: 48),
          ],
          Text(
            'PORTAL MASUK',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.4,
              color: c.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Masuk ke\n'),
                TextSpan(text: 'akun Anda.', style: TextStyle(color: c.primary)),
              ],
            ),
            style: TextStyle(
              fontSize: w >= Breakpoints.xl ? 36 : 30,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.9,
              color: c.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gunakan email sekolah dan password yang diberikan oleh admin '
            'sekolah Anda.',
            style: TextStyle(fontSize: 14, height: 1.6, color: c.mutedForeground),
          ),
          const SizedBox(height: 32),
          AutofillGroup(
            child: Form(
              key: _formKey,
              autovalidateMode: _submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                children: [
                  AppTextField(
                    label: 'Email Sekolah',
                    hint: 'nama@sekolah.sch.id',
                    controller: _email,
                    enabled: !_loading,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    validator: _validateEmail,
                    onChanged: (_) {
                      if (_serverError != null) _serverError = null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Password',
                    hint: 'Masukkan password',
                    controller: _password,
                    enabled: !_loading,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    validator: _validatePassword,
                    onFieldSubmitted: (_) => _submit(),
                    labelTrailing: InkWell(
                      onTap: _forgotPassword,
                      child: Text(
                        'LUPA?',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: c.primary,
                        ),
                      ),
                    ),
                    suffix: IconButton(
                      tooltip: 'Tampilkan/sembunyikan password',
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: c.mutedForeground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Masuk Dashboard',
                    loadingLabel: 'Mengautentikasi...',
                    loading: _loading,
                    trailingIcon: Icons.arrow_forward,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
          if (Env.showDemoAccounts) ...[
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.only(top: 24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AKUN DEMO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: c.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final (email, role) in _demoAccounts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DemoAccountTile(
                        email: email,
                        role: role,
                        onTap: () {
                          _email.text = email;
                          _serverError = null;
                        },
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Klik akun demo untuk mengisi email secara otomatis.',
                    style: TextStyle(fontSize: 10, color: c.mutedForeground),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DemoAccountTile extends StatefulWidget {
  const _DemoAccountTile({
    required this.email,
    required this.role,
    required this.onTap,
  });

  final String email;
  final String role;
  final VoidCallback onTap;

  @override
  State<_DemoAccountTile> createState() => _DemoAccountTileState();
}

class _DemoAccountTileState extends State<_DemoAccountTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(kRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(
              color: _hover ? c.primary.withValues(alpha: .4) : c.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  widget.email,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: c.foreground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.role.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: _hover ? c.primary : c.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Layar "Autentikasi Berhasil" sebelum masuk dashboard.
class _SuccessOverlay extends StatelessWidget {
  const _SuccessOverlay();

  @override
  Widget build(BuildContext context) {
    final c = context.sc;
    return Scaffold(
      backgroundColor: c.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.scale(scale: .95 + .05 * t, child: child),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 384),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.primary.withValues(alpha: .2)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 15,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const SimmasLogo(size: 48),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: c.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Autentikasi Berhasil',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mengalihkan ke Dashboard...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mohon tunggu sebentar, sedang menyiapkan data dashboard Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: c.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.muted,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: c.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Memuat data',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
