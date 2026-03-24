import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/platform_utils.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_telemetry.dart';
import '../../logic/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);

    _emailFocus.addListener(() {
      if (mounted) setState(() {});
    });
    _passwordFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ── Side-effect listener ──────────────────────────────────────
  bool _didListenSetup = false;

  void _setupListener() {
    if (_didListenSetup) return;
    _didListenSetup = true;

    ref.listenManual<AuthState>(authProvider, (previous, next) {
      if (!mounted) return;

      final wasLoading = previous?.isLoading ?? false;
      if (!wasLoading || next.isLoading) return;

      if (next.isLoggedIn) {
        final greeting = next.userName.isNotEmpty
            ? 'Selamat Datang Kembali, ${next.userName}!'
            : 'Selamat Datang Kembali!';
        AppFeedback.show(
          context,
          message: greeting,
          type: AppFeedbackType.success,
          duration: const Duration(seconds: 3),
          floating: true,
        );
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) context.go('/');
        });
      } else if (next.errorMessage case final errorMsg?) {
        _shakeController.forward(from: 0);
        AppFeedback.show(
          context,
          message: errorMsg,
          type: AppFeedbackType.error,
          duration: const Duration(seconds: 3),
          floating: true,
        );
      }
    });
  }

  // ── Login handler ─────────────────────────────────────────────
  void _handleLogin() {
    ref.read(authProvider.notifier).clearError();

    if (!_formKey.currentState!.validate()) {
      _shakeController.forward(from: 0);
      AppTelemetry.event('login_validation_failed');
      return;
    }

    if (ref.read(isOfflineProvider)) {
      AppTelemetry.event('login_offline_blocked');
      return;
    }

    ref.read(authProvider.notifier).login(
          _emailController.text.trim().toLowerCase(),
          _passwordController.text,
        );
  }

  // ── Field with focus shadow ───────────────────────────────────
  Widget _focusableField({
    required FocusNode focusNode,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: focusNode.hasFocus
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: child,
    );
  }

  void _showForgotPasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(Icons.lock_reset_rounded,
                size: 48, color: AppColors.accent),
            const SizedBox(height: 16),
            const Text(
              'Lupa Password?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Password dikelola oleh Admin. '
              'Hubungi tim IT atau atasan Anda untuk mereset password.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Mengerti',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    _setupListener();

    const primary = AppColors.accent;
    final auth = ref.watch(authProvider);
    final isLoading = auth.isLoading;
    final errorMessage = auth.errorMessage;
    final offline = ref.watch(isOfflineProvider);

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primary, width: 1.5),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.surface, AppColors.surfaceLight],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 40.0,
                ),
                child: Form(
                  key: _formKey,
                  child: AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0),
                      child: child,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Logo ──────────────────────────────
                        Center(
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.15),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Typography ────────────────────────
                        const Text(
                          'Alita',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: primary,
                            letterSpacing: -1,
                          ),
                        ),
                        const Text(
                          'P R I C E L I S T',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textTertiary,
                            letterSpacing: 5,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // ── Email ─────────────────────────────
                        _focusableField(
                          focusNode: _emailFocus,
                          child: TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.next,
                            readOnly: isLoading,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Masukkan email Anda',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: _emailFocus.hasFocus
                                    ? primary
                                    : AppColors.textTertiary,
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: fieldBorder,
                              enabledBorder: fieldBorder,
                              focusedBorder: focusedBorder,
                              errorBorder: errorBorder,
                              focusedErrorBorder: errorBorder,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email tidak boleh kosong';
                              }
                              if (!value.contains('@')) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Password ──────────────────────────
                        _focusableField(
                          focusNode: _passwordFocus,
                          child: TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            readOnly: isLoading,
                            onFieldSubmitted: (_) {
                              if (!isLoading) _handleLogin();
                            },
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Masukkan password',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: _passwordFocus.hasFocus
                                    ? primary
                                    : AppColors.textTertiary,
                              ),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Tampilkan sandi'
                                    : 'Sembunyikan sandi',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textTertiary,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              border: fieldBorder,
                              enabledBorder: fieldBorder,
                              focusedBorder: focusedBorder,
                              errorBorder: errorBorder,
                              focusedErrorBorder: errorBorder,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── Lupa password ─────────────────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => _showForgotPasswordSheet(context),
                            child: const Text(
                              'Lupa Password?',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        // ── Error banner ──────────────────────
                        if (errorMessage != null) ...[
                          const SizedBox(height: 16),
                          _ErrorBanner(message: errorMessage),
                          const SizedBox(height: 16),
                        ] else
                          const SizedBox(height: 24),

                        // ── Login button ──────────────────────
                        _LoginButton(
                          isLoading: isLoading,
                          offline: offline,
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: 32),

                        // ── Footer ────────────────────────────
                        const Text(
                          'Gunakan email dan password yang telah diberikan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Private sub-widgets
// ─────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.isLoading,
    required this.offline,
    required this.onPressed,
  });

  final bool isLoading;
  final bool offline;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const primary = AppColors.accent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isLoading
            ? []
            : [
                BoxShadow(
                  color: primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: (isLoading || offline)
            ? null
            : () {
                hapticTap();
                onPressed();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: primary.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation(AppColors.onPrimary),
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                offline ? 'Offline' : 'Masuk',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
