import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/device_token_service.dart';
import '../../../core/services/fcm_token_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/app_telemetry.dart';
import '../../../core/utils/log.dart';
import '../data/services/auth_service.dart';

// ─────────────────────────────────────────────────────────
//  Auth state
// ─────────────────────────────────────────────────────────

class AuthState {
  final bool isLoggedIn;
  final String userEmail;
  final String defaultArea;
  final bool isLoading;
  final String accessToken;
  final int userId;
  final String userName;
  final String userImageUrl;
  final String? errorMessage;

  const AuthState({
    this.isLoggedIn = false,
    this.userEmail = '',
    this.defaultArea = 'Jabodetabek',
    this.isLoading = true,
    this.accessToken = '',
    this.userId = 0,
    this.userName = '',
    this.userImageUrl = '',
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userEmail,
    String? defaultArea,
    bool? isLoading,
    String? accessToken,
    int? userId,
    String? userName,
    String? userImageUrl,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userEmail: userEmail ?? this.userEmail,
      defaultArea: defaultArea ?? this.defaultArea,
      isLoading: isLoading ?? this.isLoading,
      accessToken: accessToken ?? this.accessToken,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImageUrl: userImageUrl ?? this.userImageUrl,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Auth notifier
// ─────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final AuthService _authService = AuthService();

  /// Read persisted session on startup.
  Future<void> _init() async {
    final results = await Future.wait([
      StorageService.loadIsLoggedIn(), // 0
      StorageService.loadUserEmail(), // 1
      StorageService.loadDefaultArea(), // 2
      StorageService.loadAccessToken(), // 3
      StorageService.loadUserId(), // 4
      StorageService.loadUserName(), // 5
      StorageService.loadUserImageUrl(), // 6
    ]);

    final isLoggedIn = results[0] as bool;
    final email = results[1] as String;
    final area = results[2] as String;
    final token = results[3] as String;
    final uid = results[4] as int;
    final name = results[5] as String;
    final imageUrl = results[6] as String;

    // Yield to the next event-loop turn so the state mutation doesn't
    // overlap with Riverpod's vsync flush during the initial build frame.
    // Fixes ConcurrentModificationError in riverpod 2.6.1.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    state = AuthState(
      isLoggedIn: isLoggedIn,
      userEmail: email,
      defaultArea: area,
      accessToken: token,
      userId: uid,
      userName: name,
      userImageUrl: imageUrl,
      isLoading: false,
    );

    if (isLoggedIn && uid > 0 && token.isNotEmpty) {
      _initFcm(uid.toString(), token);
    }
  }

  /// Authenticate with [email] and [password].
  ///
  /// On success: persists session, sets `isLoggedIn = true`,
  /// syncs FCM token in background.
  /// On failure: sets `errorMessage` on state for the UI to display.
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final sw = Stopwatch()..start();
    AppTelemetry.event('login_attempted', data: {'email': email});

    try {
      final result = await _authService.login(email, password);

      final areaName = _mapAreaIdToName(result.areaId);

      await StorageService.saveAuth(
        isLoggedIn: true,
        email: result.userEmail,
        defaultArea: areaName,
        accessToken: result.accessToken,
        userId: result.userId,
        userName: result.userName,
        userImageUrl: result.userImageUrl,
      );

      state = AuthState(
        isLoggedIn: true,
        userEmail: result.userEmail,
        defaultArea: areaName,
        accessToken: result.accessToken,
        userId: result.userId,
        userName: result.userName,
        userImageUrl: result.userImageUrl,
        isLoading: false,
      );

      sw.stop();
      AppTelemetry.event('login_success', data: {
        'user_id': result.userId,
        'area': areaName,
        'duration_ms': sw.elapsedMilliseconds,
      });

      // Fire-and-forget — never let FCM failure override login success state.
      try {
        _initFcm(result.userId.toString(), result.accessToken);
      } catch (e, st) {
        Log.error(e, st, reason: 'Auth.login: FCM init (non-blocking)');
      }
    } on String catch (message) {
      sw.stop();
      AppTelemetry.error('login_failed', data: {
        'reason': message,
        'duration_ms': sw.elapsedMilliseconds,
      });
      state = state.copyWith(isLoading: false, errorMessage: message);
    } catch (e, st) {
      sw.stop();
      Log.error(e, st, reason: 'Auth.login');
      AppTelemetry.error('login_failed', data: {
        'reason': e.toString(),
        'duration_ms': sw.elapsedMilliseconds,
      });
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Clears the error so the banner disappears on next attempt.
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  /// Sync FCM token in background (fire-and-forget) + listen for rotations.
  ///
  /// Uses [DeviceTokenService] for the initial POST (with smart 422
  /// handling), then [FcmTokenService] for ongoing refresh subscription.
  void _initFcm(String userId, String accessToken) {
    Log.setUser(userId);

    // Background sync — never blocks UI or cancels login on failure
    DeviceTokenService.syncFcmToken(
      userId: userId,
      accessToken: accessToken,
    ).then((ok) {
      if (!ok) {
        Log.warning('Initial FCM sync returned false', tag: 'Auth');
      }
    });

    FcmTokenService.listenToRefresh(userId: userId, accessToken: accessToken);
  }

  String _mapAreaIdToName(int id) {
    const areaMap = {
      1: 'Jabodetabek',
      2: 'Jawa Barat',
      3: 'Sumatra Utara',
      4: 'Riau',
      5: 'Jawa Tengah',
      6: 'Jawa Timur',
      7: 'Kalimantan Timur',
      8: 'Maluku Utara',
      9: 'Sulawesi Selatan',
      10: 'Bali',
      11: 'Nusa Tenggara Barat',
      12: 'Kalimantan Selatan',
      14: 'Maluku',
      15: 'Sulawesi Tengah',
      16: 'Gorontalo',
      17: 'Sulawesi Utara',
      18: 'Kotamobagu',
      19: 'Kalimantan Barat',
      20: 'Sumatra Selatan',
      21: 'Singapore',
      23: 'Lampung',
      24: 'Sulawesi Tenggara',
      25: 'Nusa Tenggara Timur',
      26: 'Multi Niaga Integra Jakarta',
      27: 'Sumatra Barat',
    };
    return areaMap[id] ?? 'Unknown Area';
  }

  /// Logout — clears the session immediately, then deletes FCM token
  /// in the background so the UI never blocks on network requests.
  Future<void> logout() async {
    final uid = state.userId.toString();
    final token = state.accessToken;

    AppTelemetry.event('logout', data: {'user_id': state.userId});

    // Clear session first so UI navigates instantly
    await StorageService.clearAuth();
    state = const AuthState(isLoading: false);

    // Fire-and-forget cleanup — never blocks the user
    if (uid != '0' && token.isNotEmpty) {
      unawaited(FcmTokenService.cancelRefreshListener());
      unawaited(_revokeSession(token));
      unawaited(
          DeviceTokenService.deleteToken(userId: uid, accessToken: token));
    }
  }

  /// Revokes the access token on the server so it can't be reused.
  static Future<void> _revokeSession(String accessToken) async {
    try {
      await ApiClient.instance.deleteJson(
        '/sign_out',
        accessToken: accessToken,
      );
    } catch (e) {
      Log.warning('Session revoke failed: $e', tag: 'Auth');
    }
  }
}

// ─────────────────────────────────────────────────────────
//  Provider
// ─────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
