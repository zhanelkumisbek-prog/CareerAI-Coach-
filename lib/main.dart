import 'package:careerai_coach/app/app.dart';
import 'package:careerai_coach/core/services/firebase_support.dart';
import 'package:careerai_coach/core/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (supportsConfiguredFirebasePlatform) {
      final app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('[Firebase] initialized projectId=${app.options.projectId}');
    } else {
      debugPrint('[Firebase] skipped for this platform; running in local mode');
    }
  } catch (error, stackTrace) {
    debugPrint('[Firebase] initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  try {
    await NotificationService.instance.initialize();
  } catch (error, stackTrace) {
    debugPrint('[Notifications] initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const ProviderScope(child: CareerAiCoachApp()));
}
