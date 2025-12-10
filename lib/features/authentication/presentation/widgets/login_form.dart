import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/controller_disposal_mixin.dart';
import '../../../../core/utils/validation.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../navigation/navigation_service.dart';
import '../../../../config/app_constant.dart';
import '../../../../theme/app_colors.dart';

import '../../../../services/auth_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> with ControllerDisposalMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final FocusNode emailFocus;
  late final FocusNode passwordFocus;

  bool isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    emailController = registerController();
    passwordController = registerController();
    emailFocus = registerFocusNode();
    passwordFocus = registerFocusNode();
    _loadSavedEmail();
  }

  void _loadSavedEmail() async {
    final savedEmail = await AuthService.getSavedEmail();
    if (savedEmail != null && mounted) {
      setState(() {
        emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  void _submitLogin() async {
    if (_formKey.currentState!.validate()) {
      if (_rememberMe) {
        await AuthService.saveEmail(emailController.text);
      } else {
        await AuthService.clearSavedEmail();
      }

      if (mounted) {
        setState(() => isLoading = true);
        context.read<AuthBloc>().add(
              AuthLoginRequested(emailController.text, passwordController.text),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email Field
          _buildTextField(
            controller: emailController,
            focusNode: emailFocus,
            label: 'Email',
            hint: 'Masukkan email Anda',
            icon: Icons.email_outlined,
            validator: ValidationHelper.validateEmail,
            isDark: isDark,
            colorScheme: colorScheme,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(passwordFocus);
            },
          ),

          const SizedBox(height: AppPadding.p16),

          // Password Field
          _buildTextField(
            controller: passwordController,
            focusNode: passwordFocus,
            label: 'Password',
            hint: 'Masukkan password Anda',
            icon: Icons.lock_outline,
            validator: ValidationHelper.validatePassword,
            isDark: isDark,
            colorScheme: colorScheme,
            isPassword: true,
            obscureText: _obscurePassword,
            onToggleObscure: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),

          const SizedBox(height: AppPadding.p12),

          // Remember Me
          GestureDetector(
            onTap: () => setState(() => _rememberMe = !_rememberMe),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color:
                        _rememberMe ? colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _rememberMe
                          ? colorScheme.primary
                          : (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: _rememberMe
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: AppPadding.p10),
                Text(
                  'Ingat saya',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppPadding.p24),

          // Login Button
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (!mounted) return;

              if (state is AuthLoading) {
                CustomLoading.showLoadingDialog(context);
              } else {
                CustomLoading.hideLoadingDialog(context);
              }

              if (state is AuthSuccess) {
                setState(() => isLoading = false);
                CustomToast.showToast("Login Berhasil!", ToastType.success);
                NavigationService.navigateAndReplace(RoutePaths.product);
              }

              if (state is AuthFailure) {
                setState(() => isLoading = false);
                CustomToast.showToast(state.error, ToastType.error);
              }
            },
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      colorScheme.primary.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: isLoading ? 0 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login_rounded, size: 20),
                          const SizedBox(width: AppPadding.p8),
                          const Text(
                            'Masuk',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    required bool isDark,
    required ColorScheme colorScheme,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppPadding.p8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          obscureText: isPassword && obscureText,
          onFieldSubmitted: onFieldSubmitted,
          style: TextStyle(
            fontSize: 15,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: colorScheme.primary.withValues(alpha: 0.7),
              size: 20,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.error,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
