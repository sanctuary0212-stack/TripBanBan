import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app_controller.dart';
import 'app/app_services.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = AppServices.create();
  final controller = AppController(services);
  await controller.initialize();

  runApp(TripBanBanApp(controller: controller));

  // Both jobs are best-effort enhancements. Local SQLite remains authoritative
  // even when background scheduling is unavailable on a platform/build.
  unawaited(services.fx.updateDaily());
  unawaited(() async {
    try {
      await services.background.initialize();
      await services.background.enableDailyFx();
    } catch (_) {
      // Platform setup may not be present in local/dev builds yet.
    }
  }());
}
