flutter run -d chrome --web-port 52901 --dart-define=APP_MODE=central


flutter run \
  --dart-define=APP_MODE=central \
  --dart-define='FACTORY={"info":{"firmware_version":"1.0.0","hash":"a1b2c3","old_hash":"","created_at":"2026-06-25","updated_at":"2026-06-25"},"credentials":{"pin":"428412","root":"admin","password":"Teste@123"},"access":{"subId":"sub-9f3a21bc"}}'


Or for a release build:

flutter build apk \
  --dart-define=APP_MODE=central \
  --dart-define='FACTORY={"info":{"firmware_version":"1.0.0","hash":"a1b2c3","old_hash":"","created_at":"2026-06-25","updated_at":"2026-06-25"},"credentials":{"pin":"428412","root":"admin","password":"Teste@123"},"access":{"subId":"sub-9f3a21bc"}}'


flutter run -d 98cc396d \
  --dart-define=APP_MODE=central \
  --dart-define='FACTORY={"info":{"firmware_version":"1.0.0","hash":"a1b2c3","old_hash":"","created_at":"2026-06-25","updated_at":"2026-06-25"},"credentials":{"pin":"428412","root":"admin","password":"Teste@123"},"access":{"subId":"sub-9f3a21bc"}}'R