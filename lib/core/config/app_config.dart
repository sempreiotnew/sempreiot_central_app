class AppConfig {
  static const _mode = String.fromEnvironment('APP_MODE', defaultValue: 'app');

  static bool get isCentral => _mode == 'central';
  static bool get isApp => !isCentral;
}
