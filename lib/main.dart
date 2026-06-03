import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/amplify_config.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/app/application/app_init_provider.dart';
import 'features/central/application/central_auth_provider.dart';
import 'features/central/presentation/screens/central_main_screen.dart';
import 'features/central/presentation/screens/central_pin_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/main/main_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.isApp) {
    await dotenv.load();
    await _configureAmplify();
  }
  runApp(const ProviderScope(child: SempreIoTApp()));
}

Future<void> _configureAmplify() async {
  try {
    await Amplify.addPlugin(AmplifyAuthCognito());
    await Amplify.configure(buildAmplifyConfig());
  } on AmplifyAlreadyConfiguredException {
    // safe to ignore during hot restart
  }
}

class SempreIoTApp extends ConsumerWidget {
  const SempreIoTApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'SempreIoT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: AppConfig.isCentral ? const _CentralRoot() : const _AppRoot(),
    );
  }
}

// ── APP mode ─────────────────────────────────────────────────────────────────

class _AppRoot extends ConsumerWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appInitProvider);
    return appState.when(
      data: (ready) => ready ? const MainScreen() : const LoginScreen(),
      loading: () => const SplashScreen(),
      error: (_, __) => const LoginScreen(),
    );
  }
}

// ── CENTRAL mode ──────────────────────────────────────────────────────────────

class _CentralRoot extends ConsumerWidget {
  const _CentralRoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(centralAuthProvider);
    return authState is CentralAuthenticated
        ? const CentralMainScreen()
        : const CentralPinScreen();
  }
}
