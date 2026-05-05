import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class TwelvePionsApp extends StatelessWidget {
  const TwelvePionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '12 Pions',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
