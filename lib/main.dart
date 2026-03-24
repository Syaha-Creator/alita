import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/utils/log.dart';
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

/// Data Connect memakai `@auth(level: USER)` — anonymous auth memenuhi token tanpa UI login terpisah.
Future<void> _ensureFirebaseAuthForDataConnect() async {
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e, st) {
    Log.error(e, st, reason: 'Firebase anonymous auth (Data Connect)');
  }
}

Future<bool> _initializeFirebaseWithRetry() async {
  const maxAttempts = 10;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      return true;
    } on PlatformException catch (e, st) {
      final isChannelError = e.code == 'channel-error';
      Log.error(
        e,
        st,
        reason: 'Firebase initialize attempt #$attempt',
      );
      if (!isChannelError || attempt == maxAttempts) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 250 * attempt));
    } catch (e, st) {
      Log.error(e, st, reason: 'Firebase initialize attempt #$attempt');
      return false;
    }
  }
  return false;
}

void main() {
  // Shared flag visible to both the zone body and the zone error handler.
  var isFirebaseReady = false;

  // Everything inside the same zone — eliminates the "Zone mismatch" warning
  // that breaks platform channels (channel-error on Firebase.initializeApp).
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (!kDebugMode) {
      ErrorWidget.builder = (details) => const _AppErrorFallback();
    }

    await dotenv.load(fileName: '.env');
    AppConfig.assertConfigured();

    isFirebaseReady = await _initializeFirebaseWithRetry();
    if (isFirebaseReady) {
      NotificationHandlerService.setFirebaseReady();
      Log.enableCrashlytics();
    }
    await initializeDateFormatting('id_ID');

    FlutterError.onError = (details) {
      if (isFirebaseReady) {
        if (_isTransientAssetError(details)) {
          FirebaseCrashlytics.instance.recordFlutterError(details);
          return;
        }
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } else {
        Log.error(
          details.exception,
          details.stack,
          reason: 'FlutterError without Firebase',
        );
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (isFirebaseReady) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } else {
        Log.error(error, stack, reason: 'Platform error without Firebase');
      }
      return true;
    };

    if (isFirebaseReady) {
      unawaited(_ensureFirebaseAuthForDataConnect());
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      unawaited(
        FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(!kDebugMode),
      );
    }

    // Defer non-critical work to avoid competing with surface creation.
    unawaited(Future.delayed(const Duration(seconds: 1), () {
      PdfAssetCache.warmUp();
      StorageService.migratePricelistCacheFromPrefs();
    }));

    runApp(
      const ProviderScope(
        child: AlitaPricelistApp(),
      ),
    );
  }, (error, stack) {
    if (isFirebaseReady) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } else {
      debugPrint('[Fatal zone error] $error\n$stack');
    }
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
  StreamSubscription<Uri?>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationHandlerService.registerScaffoldMessengerKey(_scaffoldKey);
    NotificationHandlerService.registerApprovalRefreshCallback(() {
      ref.read(approvalInboxProvider.notifier).fetchInbox();
    });

    _listenDeepLinks();

    // Delay heavy platform-channel work so first frame renders fast.
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      NotificationHandlerService.init();
      unawaited(ForceUpdateService.checkAndForceUpdate());
    });
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _listenDeepLinks() {
    _deepLinkSubscription?.cancel();
    try {
      final appLinks = AppLinks();
      _deepLinkSubscription = appLinks.uriLinkStream.listen((Uri? uri) {
        if (!mounted || uri == null || uri.path.isEmpty) return;
        final path =
            uri.query.isEmpty ? uri.path : '${uri.path}?${uri.query}';
        ref.read(routerProvider).go(path);
      });
    } catch (e, st) {
      Log.error(e, st, reason: 'AppLinks deep link listener');
    }
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
    // Defer precacheImage — it blocks main thread during decode. Running it
    // during surface creation increases ANR risk (pthread_cond_wait in libflutter).
    if (!_imagePrecached) {
      _imagePrecached = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          precacheImage(
            const AssetImage('assets/logo/whatsapp-icon.png'),
            context,
          );
        });
      });
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
