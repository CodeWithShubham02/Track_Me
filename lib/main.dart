import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

import 'package:joizone/services/notification_service.dart';
import 'package:joizone/user/services/background_service.dart';

import 'admin/view/admin_home_screen.dart';
import 'admin/view/login_screen.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(
    RemoteMessage message,
    ) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint(
    "📩 Background notification: ${message.messageId}",
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --------------------------------------------------
  // FIREBASE
  // --------------------------------------------------
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --------------------------------------------------
  // FCM BACKGROUND MESSAGE
  // --------------------------------------------------
  FirebaseMessaging.onBackgroundMessage(
    _firebaseBackgroundHandler,
  );

  // --------------------------------------------------
  // BACKGROUND LOCATION SERVICE
  // --------------------------------------------------
  //
  // Service automatically start nahi hoga.
  // Punch In ke baad manually start hoga.
  //
  if (!kIsWeb) {
    await initializeService();
  }

  // --------------------------------------------------
  // PORTRAIT MODE
  // --------------------------------------------------
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // --------------------------------------------------
  // START APP
  // --------------------------------------------------
  runApp(
    const MyApp(),
  );
}

// ======================================================
// BACKGROUND SERVICE CONFIGURATION
// ======================================================

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel =
  AndroidNotificationChannel(
    'track_me_location_channel',
    'Track Me Location',
    description: 'Track Me background location tracking',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,

      notificationChannelId:
      'track_me_location_channel',

      initialNotificationTitle:
      'Track Me',

      initialNotificationContent:
      'Location tracking is active',

      foregroundServiceNotificationId:
      888,
    ),

    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: iosBackground,
    ),
  );
}

// ======================================================
// iOS BACKGROUND
// ======================================================

@pragma('vm:entry-point')
Future<bool> iosBackground(
    ServiceInstance service,
    ) async {
  WidgetsFlutterBinding.ensureInitialized();

  DartPluginRegistrant.ensureInitialized();

  debugPrint(
    "🍎 iOS Background Service",
  );

  return true;
}

// ======================================================
// MY APP
// ======================================================

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

// ======================================================
// APP STATE
// ======================================================

class _MyAppState extends State<MyApp> {
  final NotificationService notificationService =
  NotificationService();

  @override
  void initState() {
    super.initState();

    // IMPORTANT:
    // BuildContext available hone ke baad notification
    // initialization karo.
    WidgetsBinding.instance.addPostFrameCallback(
          (_) {
        if (!mounted) return;

        notificationService.firebaseInit(
          context,
        );

        notificationService.setupInteractMessage(
          context,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Track Me',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
      ),

     //home: LoginScreen(),

      // Agar Admin test karna ho:
     home: AdminHomeScreen(cid: "1"),
    );
  }
}