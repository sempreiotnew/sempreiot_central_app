import 'package:flutter/material.dart';

import '../../../../presentation/screens/main/main_screen.dart';

/// Thin wrapper kept for backward compatibility with [main.dart]'s _CentralRoot.
/// All layout lives in [MainScreen]; AppConfig.isCentral drives Central-specific UI.
class CentralMainScreen extends StatelessWidget {
  const CentralMainScreen({super.key});

  @override
  Widget build(BuildContext context) => const MainScreen();
}
