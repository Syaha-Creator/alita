class AuthService {
  static bool _isLoggedIn = false;

  static bool isLoggedIn() {
    return _isLoggedIn;
  }

  static void login() {
    _isLoggedIn = true;
  }

  static void logout() {
    _isLoggedIn = false;
  }
}
