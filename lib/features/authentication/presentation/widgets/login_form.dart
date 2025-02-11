import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  bool isLoading = false;

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
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            controller: emailController,
            labelText: "Email",
            prefixIcon: Icons.email,
            isPassword: false,
            validator: ValidationHelper.validateEmail,
          ),
          const SizedBox(height: 10),
          CustomTextField(
            controller: passwordController,
            labelText: "Password",
            prefixIcon: Icons.lock,
            isPassword: true,
            validator: ValidationHelper.validatePassword,
          ),
          const SizedBox(height: 20),
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
