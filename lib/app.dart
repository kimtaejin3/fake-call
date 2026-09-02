import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget of AI Fake Call.
class AiFakeCallApp extends StatelessWidget {
  const AiFakeCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '핑계콜',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
