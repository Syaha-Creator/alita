import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/validation.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../navigation/navigation_service.dart';
import '../../../../navigation/route_path.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/event/auth_event.dart';
import '../bloc/state/auth_state.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      context.read<AuthBloc>().add(
            AuthLoginRequested(emailController.text, passwordController.text),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email Input
          Text(
            "Email",
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          CustomTextField(
            controller: emailController,
            labelText: "Enter your email",
            prefixIcon: Icons.email_outlined,
            isPassword: false,
            validator: ValidationHelper.validateEmail,
            focusNode: emailFocus,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(passwordFocus);
            },
          ),
          const SizedBox(height: 15),

          // Password Input
          Text(
            "Password",
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          CustomTextField(
            controller: passwordController,
            labelText: "Enter your password",
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: ValidationHelper.validatePassword,
            focusNode: passwordFocus,
          ),
          const SizedBox(height: 20),

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
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: CustomButton(
                    text: "Login",
                    onPressed: isLoading ? () {} : _submitLogin,
                    isLoading: isLoading,
                  ),
                ),
                const SizedBox(height: 15),

                // Forgot Password Button
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Tambahkan navigasi ke halaman reset password jika ada
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      "Forgot password?",
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFFADD8E6)
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
