import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:joizone/admin/view/admin_home_screen.dart';
import 'package:joizone/services/notification_service.dart';
import 'package:joizone/user/services/background_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/js.dart';
import 'admin/model/user_model.dart';
import 'admin/view/login_screen.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await initializeService();
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
      _,
      ) {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    runApp(MyApp());
  });
  final notificationService = NotificationService();
  notificationService.firebaseInit(context as BuildContext);
  notificationService.setupInteractMessage(context as BuildContext);
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: (_) async => false,
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Track Me',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      //home: LoginScreen(),
       home: AdminHomeScreen(cid: "2"),
    );
  }
}
