import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' show ClientException;

import 'package:intl/date_symbol_data_local.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/services/app_analytics_service.dart';
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
/// [getIdToken(true)] memastikan credential terbaru terpasang sebelum panggilan gRPC.
Future<void> _ensureFirebaseAuthForDataConnect() async {
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    await FirebaseAuth.instance.currentUser?.getIdToken(true);
  } catch (e, st) {
    Log.error(e, st, reason: 'Firebase anonymous auth (Data Connect)');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kDebugMode) {
    ErrorWidget.builder = (details) => const _AppErrorFallback();
  }

  try {
    await dotenv.load(fileName: '.env');
    AppConfig.assertConfigured();
  } catch (e, st) {
    Log.error(e, st, reason: 'Gagal memuat .env atau konfigurasi');
  }

  var firebaseCoreOk = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseCoreOk = true;
  } catch (e, st) {
    Log.error(e, st, reason: 'Firebase Init Failed');
  }

  if (firebaseCoreOk) {
    try {
      // Tanpa ini, log: "No AppCheckProvider installed" dan Data Connect yang
      // enforce App Check mengembalikan UNAUTHENTICATED / "auth rejected".
      // Debug/profile: daftarkan token debug di Firebase Console → App Check.
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kReleaseMode
            ? const AndroidPlayIntegrityProvider()
            : const AndroidDebugProvider(),
        providerApple: kReleaseMode
            ? const AppleAppAttestWithDeviceCheckFallbackProvider()
            : const AppleDebugProvider(),
      );
    } catch (e, st) {
      Log.error(
        e,
        st,
        reason: 'Firebase App Check activate failed (Data Connect bisa ditolak)',
      );
    }

    try {
      await _ensureFirebaseAuthForDataConnect();
      NotificationHandlerService.setFirebaseReady();
      Log.enableCrashlytics();
      AppAnalyticsService.enable();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      unawaited(FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode));
    } catch (e, st) {
      Log.error(e, st, reason: 'Gagal setup Firebase Services');
    }
  }

  await initializeDateFormatting('id_ID');

  FlutterError.onError = (details) {
    if (_isTransientAssetError(details)) {
      try {
        FirebaseCrashlytics.instance.recordFlutterError(details);
      } catch (_) {}
      return;
    }
    try {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    } catch (_) {}
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (_isLikelyTransientNetworkError(error)) {
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
      } catch (_) {}
      return true;
    }
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (_) {}
    return true;
  };

  try {
    await StorageService.migrateQuotationsFromPrefsIfNeeded();
    await StorageService.migrateMasterDataJsonFromPrefsIfNeeded();
    await StorageService.migrateCartFromPrefsIfNeeded();
    await StorageService.migratePricelistCacheFromPrefs();
  } catch (e, st) {
    Log.error(e, st, reason: 'Storage migration at startup');
  }

  unawaited(Future.delayed(const Duration(seconds: 1), PdfAssetCache.warmUp));

  runApp(
    const ProviderScope(
      child: AlitaPricelistApp(),
    ),
  );
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
        final path = uri.query.isEmpty ? uri.path : '${uri.path}?${uri.query}';
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
  if (exception is ClientException) return true;
  if (exception is SocketException) return true;
  if (exception is TimeoutException) return true;

  final message = details.exceptionAsString();
  return message.contains('image decoding') ||
      message.contains('Failed to submit') ||
      message.contains('ImageCodecException') ||
      message.contains('Cannot open file') ||
      message.contains('FileSystemException') ||
      message.contains('Failed to load font') ||
      message.contains('SocketException') ||
      message.contains('Connection abort') ||
      message.contains('Connection closed') ||
      message.contains('ClientException') ||
      message.contains('HandshakeException') ||
      message.contains('Connection reset');
}

/// Network errors that often surface outside [FlutterError] (zones / isolates).
bool _isLikelyTransientNetworkError(Object error) {
  if (error is ClientException ||
      error is SocketException ||
      error is TimeoutException) {
    return true;
  }
  final s = error.toString().toLowerCase();
  return s.contains('clientexception') ||
      s.contains('socketexception') ||
      s.contains('connection closed') ||
      s.contains('connection reset') ||
      s.contains('failed host lookup') ||
      s.contains('network is unreachable');
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
