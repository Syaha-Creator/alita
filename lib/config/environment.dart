enum Environment { staging, production }

class AppEnvironment {
  static const Environment current = Environment.production;

  static String get baseUrl {
    switch (current) {
      case Environment.staging:
        return "https://staging.alitav2.massindo.com/";
      case Environment.production:
        return "https://alitav2.massindo.com/";
    }
  }
}
