import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:joizone/services/notification_service.dart';

class UserController {
  final String baseUrl = "http://15.206.209.30/attendance"; // emulator
  // For real device → replace with your PC's IP

  // Get Android device ID
  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      if (kIsWeb) {
        // ✅ Flutter Web safe ID
        final webInfo = await deviceInfo.webBrowserInfo;
        return webInfo.userAgent ?? "WEB_DEVICE";
      }

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id ?? "ANDROID_UNKNOWN";
      }

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? "IOS_UNKNOWN";
      }

      return "UNKNOWN_DEVICE";
    } catch (e) {
      return "DEVICE_ERROR";
    }
  }
  Future<String> getFcmToken() async {
    try {

      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request permission (important for iOS)
      await messaging.requestPermission();

      String? token = await messaging.getToken();

      debugPrint("FCM Token: $token");

      return token ?? "NO_TOKEN";
    } catch (e) {
      debugPrint("FCM Error: $e");
      return "TOKEN_ERROR";
    }
  }

  Future<Map<String, dynamic>> loginUser({
    required String userid,
    required String password,
  }) async {
    try {
      final imeiNo = await getDeviceId();
      final fcmToken = await getFcmToken();

      final response = await http.post(
        Uri.parse("$baseUrl/user_login.php"),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "userid": userid,
          "password": password,
          "imei_no": imeiNo,
          "user_token":fcmToken.toString(),
        },
      );
      print("-------------");
      print(response);
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        "status": false,
        "message": "Server Error ${response.statusCode}"
      };
    } catch (e) {
      print("Login Error: $e");

      return {
        "status": false,
        "message": e.toString(),
      };
    }
  }
}