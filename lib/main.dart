import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/services/force_update_service.dart';
import 'core/services/notification_handler_service.dart';
import 'core/services/pdf_asset_cache.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/approval/logic/approval_inbox_provider.dart';
import 'features/auth/logic/auth_provider.dart';
import 'features/pricelist/logic/master_data_provider.dart';
import 'core/widgets/offline_banner.dart';
import 'firebase_options.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (!kDebugMode) {
      ErrorWidget.builder = (details) => const _AppErrorFallback();
    }

    await dotenv.load(fileName: '.env');
    AppConfig.assertConfigured();

    // Parallelize independent initializations to reduce startup time.
    await Future.wait([
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      initializeDateFormatting('id_ID'),
    ]);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Flag-only call — no need to block runApp().
    unawaited(
      FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode),
    );

    FlutterError.onError = (details) {
      if (_isTransientAssetError(details)) {
        FirebaseCrashlytics.instance.recordFlutterError(details);
        return;
      }
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    unawaited(PdfAssetCache.warmUp());
    unawaited(StorageService.migratePricelistCacheFromPrefs());

    runApp(
      const ProviderScope(
        child: AlitaPricelistApp(),
      ),
    );
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class AlitaPricelistApp extends ConsumerStatefulWidget {
  const AlitaPricelistApp({super.key});

  @override
  ConsumerState<AlitaPricelistApp> createState() => _AlitaPricelistAppState();
}

class _AlitaPricelistAppState extends ConsumerState<AlitaPricelistApp>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  bool _initialMessageHandled = false;
  bool _imagePrecached = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationHandlerService.registerScaffoldMessengerKey(_scaffoldKey);
    NotificationHandlerService.registerApprovalRefreshCallback(() {
      ref.read(approvalInboxProvider.notifier).fetchInbox();
    });

    // Delay heavy platform-channel work so first frame renders fast.
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      NotificationHandlerService.init();
      unawaited(ForceUpdateService.checkAndForceUpdate());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(masterDataProvider.notifier).syncIfStale();
      unawaited(ForceUpdateService.checkAndForceUpdate());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagePrecached) {
      _imagePrecached = true;
      precacheImage(
        const AssetImage('assets/logo/whatsapp-icon.png'),
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    NotificationHandlerService.registerNavigateCallback(router);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.isLoggedIn != true && next.isLoggedIn) {
        ref.invalidate(masterDataProvider);
      }
    });

    if (!_initialMessageHandled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_initialMessageHandled && mounted) {
          _initialMessageHandled = true;
          NotificationHandlerService.handleInitialMessage();
        }
      });
    }

    return MaterialApp.router(
      title: 'Alita Pricelist',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        return ScaffoldMessenger(
          key: _scaffoldKey,
          child: OfflineBannerWrapper(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

/// Transient asset-loading failures (images, fonts) caused by device/network
/// issues — not application bugs. Report as non-fatal.
bool _isTransientAssetError(FlutterErrorDetails details) {
  final exception = details.exception;
  if (exception is PathNotFoundException) return true;

  final message = details.exceptionAsString();
  return message.contains('image decoding') ||
      message.contains('Failed to submit') ||
      message.contains('ImageCodecException') ||
      message.contains('Cannot open file') ||
      message.contains('FileSystemException') ||
      message.contains('Failed to load font') ||
      message.contains('SocketException') ||
      message.contains('Connection abort');
}

/// Friendly fallback shown in release when a widget fails to build.
class _AppErrorFallback extends StatelessWidget {
  const _AppErrorFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 48, color: AppColors.warning),
              SizedBox(height: 16),
              Text(
                'Terjadi kesalahan tampilan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Coba kembali ke halaman sebelumnya\natau restart aplikasi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
