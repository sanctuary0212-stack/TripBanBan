import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_controller.dart';
import 'screens/app_shell.dart';
import 'theme.dart';

class TripBanBanApp extends StatelessWidget {
  const TripBanBanApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TripBanBan',
        theme: buildTripBanBanTheme(),
        locale: controller.locale,
        supportedLocales: const [
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
          Locale('en'),
          Locale('ja'),
          Locale('ko'),
        ],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: AppShell(controller: controller),
      ),
    );
  }
}
