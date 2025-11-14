// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/env_config.dart';
import 'config/dependency_injection.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/product/presentation/bloc/product_bloc.dart';
import 'features/approval/presentation/bloc/approval_bloc.dart';

import 'navigation/app_router.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/app_update_service.dart';
import 'core/widgets/force_update_dialog.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await EnvConfig().load();

  // Prevent runtime font fetching to avoid crashes when offline / no DNS
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  setupLocator();

  // Initialize Notification Service
  await NotificationService().initialize();

  await AuthService.isLoggedIn();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isCheckingUpdate = true;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      final updateService = locator<AppUpdateService>();
      final needsUpdate = await updateService.checkForUpdate();

      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });

        // Show force update dialog if needed
        if (needsUpdate) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showForceUpdateDialog();
          });
        }
      }
    } catch (e) {
      // If check fails, continue with app (don't block)
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  void _showForceUpdateDialog() {
    // Use navigatorKey from router to show dialog
    final navigatorKey = AppRouter.router.routerDelegate.navigatorKey;
    if (navigatorKey.currentContext != null) {
      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (context) => const ForceUpdateDialog(
          isForceUpdate: true,
          message:
              'Versi aplikasi Anda sudah tidak didukung. Silakan update aplikasi ke versi terbaru untuk melanjutkan.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => locator<AuthBloc>(),
        ),
        BlocProvider<ProductBloc>(
          create: (context) => locator<ProductBloc>(),
        ),
        BlocProvider(
          create: (context) => CartBloc(),
        ),
        BlocProvider<ApprovalBloc>(
          create: (context) => locator<ApprovalBloc>(),
        ),
      ],
      child: ValueListenableBuilder<bool>(
        valueListenable: AuthService.authChangeNotifier,
        builder: (context, isLoggedIn, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Alita Pricelist',
            routerConfig: AppRouter.router,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            builder: (context, child) {
              // Show loading indicator while checking for update
              if (_isCheckingUpdate) {
                return const MaterialApp(
                  home: Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }
              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
