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
import 'core/router/app_router.dart';
import 'core/services/notification_handler_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/logic/auth_provider.dart';
import 'features/pricelist/logic/master_data_provider.dart';
import 'core/widgets/offline_banner.dart';
import 'firebase_options.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await dotenv.load(fileName: '.env');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initializeDateFormatting('id_ID');

    // Background/terminated message handler (must be top-level registration)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground + tap handlers; permission request
    await NotificationHandlerService.init();

    // Disable Crashlytics data collection in debug mode
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);

    // Forward all Flutter framework errors to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

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

class _AlitaPricelistAppState extends ConsumerState<AlitaPricelistApp> {
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
    NotificationHandlerService.registerScaffoldMessengerKey(_scaffoldKey);
  }

  @override
  Widget build(BuildContext context) {
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

class _AlitaUpgraderMessages extends UpgraderMessages {
  _AlitaUpgraderMessages() : super(code: 'id');

  @override
  String get title => 'Pembaruan Tersedia';

  @override
  String get body =>
      'Versi baru aplikasi {{appName}} telah tersedia.\n'
      'Anda wajib memperbarui aplikasi untuk melanjutkan dan memastikan '
      'perhitungan harga akurat.\n\n'
      'Versi terpasang: {{currentInstalledVersion}}\n'
      'Versi terbaru: {{currentAppStoreVersion}}';

  @override
  String get prompt => 'Silakan perbarui aplikasi sekarang untuk melanjutkan.';

  @override
  String get buttonTitleUpdate => 'Perbarui Sekarang';
}
