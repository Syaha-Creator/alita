// lib/features/authentication/presentation/widgets/login_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/utils/controller_disposal_mixin.dart';
import '../../../../core/utils/validation.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../navigation/navigation_service.dart';

import '../../../../services/auth_service.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/presentation/bloc/product_event.dart';
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
            validator: ValidationHelper.validateEmail,
            focusNode: emailFocus,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(passwordFocus);
            },
          ),
          const SizedBox(height: 15),
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                ),
                const Text("Remember Me"),
              ],
            ),
          ),
          const SizedBox(height: 10),
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (!mounted) return;

              if (state is AuthLoading) {
                CustomLoading.showLoadingDialog(context);
              } else {
                CustomLoading.hideLoadingDialog(context);
              }

              if (state is AuthSuccess) {
                context.read<ProductBloc>().add(FetchProducts());

                setState(() => isLoading = false);
                CustomToast.showToast("Login Berhasil!", ToastType.success);
                NavigationService.navigateAndReplace(RoutePaths.product);
              }

              if (state is AuthFailure) {
                setState(() => isLoading = false);
                CustomToast.showToast(state.error, ToastType.error);
              }
            },
            child: CustomButton(
              text: "Login",
              onPressed: isLoading ? () {} : _submitLogin,
              isLoading: isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
