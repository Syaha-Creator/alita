import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:upgrader/upgrader.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_handler_service.dart';
import 'core/services/pdf_asset_cache.dart';
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

    // In release, show a friendly error instead of the red error screen
    if (!kDebugMode) {
      ErrorWidget.builder = (details) => const _AppErrorFallback();
    }

    await dotenv.load(fileName: '.env');
    AppConfig.assertConfigured();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initializeDateFormatting('id_ID');

    // Background/terminated message handler (must be top-level registration)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground + tap handlers; permission request
    await NotificationHandlerService.init();

    // ── Crashlytics ──────────────────────────────────────────
    // Enable collection in release; disable in debug to avoid noise
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);

    // Flutter framework errors (rendering, layout, etc.)
    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    // Async errors from platform dispatchers (not caught by runZonedGuarded)
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Pre-load PDF fonts & logos in background so generation is instant later
    unawaited(PdfAssetCache.warmUp());

    runApp(
      const ProviderScope(
        child: AlitaPricelistApp(),
      ),
    );
  }, (error, stack) {
    // Dart async errors within the zone
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
  final Upgrader _upgrader = Upgrader(
    debugLogging: false,
    countryCode: 'id',
    languageCode: 'id',
    messages: _AlitaUpgraderMessages(),
    storeController: UpgraderStoreController(
      onAndroid: () => UpgraderPlayStore(),
      oniOS: () => UpgraderAppStore(),
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationHandlerService.registerScaffoldMessengerKey(_scaffoldKey);
    NotificationHandlerService.registerApprovalRefreshCallback(() {
      ref.read(approvalInboxProvider.notifier).fetchInbox();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    precacheImage(
      const AssetImage('assets/logo/whatsapp-icon.png'),
      context,
    );

    final router = ref.watch(routerProvider);
    NotificationHandlerService.registerNavigateCallback(router);

    // When user logs in, invalidate master data so it re-fetches with token
    // (fixes first-install: area/channel/brand empty because sync never ran)
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
          child: UpgradeAlert(
            upgrader: _upgrader,
            showIgnore: false,
            showLater: false,
            barrierDismissible: false,
            shouldPopScope: () => false,
            child: OfflineBannerWrapper(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

/// Friendly fallback shown in release when a widget fails to build.
/// Prevents the default red "error" screen from scaring users.
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

class _AlitaUpgraderMessages extends UpgraderMessages {
  _AlitaUpgraderMessages() : super(code: 'id');

  @override
  String get title => 'Pembaruan Tersedia';

  @override
  String get body => 'Versi baru aplikasi {{appName}} telah tersedia.\n'
      'Anda wajib memperbarui aplikasi untuk melanjutkan dan memastikan '
      'perhitungan harga akurat.\n\n'
      'Versi terpasang: {{currentInstalledVersion}}\n'
      'Versi terbaru: {{currentAppStoreVersion}}';

  @override
  String get prompt => 'Silakan perbarui aplikasi sekarang untuk melanjutkan.';

  @override
  String get buttonTitleUpdate => 'Perbarui Sekarang';
}
