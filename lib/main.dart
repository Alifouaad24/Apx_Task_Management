import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:apx_task_management/core/api_client.dart';
import 'package:apx_task_management/core/constants.dart';
import 'package:apx_task_management/core/notifications.dart';
import 'package:apx_task_management/core/routes.dart';
import 'package:apx_task_management/core/services.dart';
import 'package:apx_task_management/core/storage.dart';
import 'package:apx_task_management/core/theme.dart';
import 'package:apx_task_management/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final firebaseAvailable = await _initFirebase();
  await _initServices(firebaseAvailable: firebaseAvailable);

  runApp(const ApxTaskApp());
}

Future<bool> _initFirebase() async {
  if (!DefaultFirebaseOptions.hasValidConfiguration) {
    AppLogger.w(
      'Firebase is not configured (lib/firebase_options.dart still holds '
      'placeholders). Run `flutterfire configure` to enable push notifications.',
    );
    return false;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    AppLogger.i('Firebase initialised');
    return true;
  } catch (e, s) {
    AppLogger.e('Firebase initialisation failed', e, s);
    return false;
  }
}

Future<void> _initServices({required bool firebaseAvailable}) async {
  final storage = Get.put(await AppStorage.init(), permanent: true);
  Get.put(ApiClient(storage), permanent: true);
  Get.put(ThemeService(storage), permanent: true);

  await Get.putAsync(
    () => AnalyticsService().init(available: firebaseAvailable),
    permanent: true,
  );
  await Get.putAsync(
    () => NotificationService(storage).init(firebaseAvailable: firebaseAvailable),
    permanent: true,
  );

  AppLogger.i('Services ready — mock API: ${AppConfig.useMockApi}');
}

class ApxTaskApp extends StatelessWidget {
  const ApxTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = Get.find<AnalyticsService>();

    return ScreenUtilInit(
      designSize: const Size(AppConfig.designWidth, AppConfig.designHeight),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetBuilder<ThemeService>(
          builder: (themeService) => GetMaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeService.themeMode,
            initialRoute: AppPages.initial,
            getPages: AppPages.routes,
            initialBinding: InitialBinding(),
            defaultTransition: Transition.cupertino,
            navigatorObservers: [
              if (analytics.observer != null) analytics.observer!,
            ],
            builder: (context, widget) {
              final scale = MediaQuery.textScalerOf(
                context,
              ).clamp(minScaleFactor: 0.9, maxScaleFactor: 1.25);
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: scale),
                child: widget ?? const SizedBox.shrink(),
              );
            },
          ),
        );
      },
    );
  }
}
