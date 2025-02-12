import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/dependency_injection.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'navigation/app_router.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();
  await AuthService.isLoggedIn();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => locator<AuthBloc>(),
      child: ValueListenableBuilder<bool>(
        valueListenable: AuthService.authChangeNotifier,
        builder: (context, isLoggedIn, child) {
          return MaterialApp.router(
            title: 'Alita Pricelist',
            routerConfig: AppRouter.router,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
          );
        },
      ),
    );
  }
}
