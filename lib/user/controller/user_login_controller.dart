import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UserController {
  final String baseUrl =
      "http://15.206.209.30/attendance";

  // =========================================================
  // DEVICE ID
  // =========================================================

  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    try {
      // WEB
      if (kIsWeb) {
        final webInfo =
        await deviceInfo.webBrowserInfo;

        return webInfo.userAgent ??
            "WEB_DEVICE";
      }

      // ANDROID
      if (Platform.isAndroid) {
        final androidInfo =
        await deviceInfo.androidInfo;

        return androidInfo.id ??
            "ANDROID_UNKNOWN";
      }

      // IOS
      if (Platform.isIOS) {
        final iosInfo =
        await deviceInfo.iosInfo;

        return iosInfo.identifierForVendor ??
            "IOS_UNKNOWN";
      }

      return "UNKNOWN_DEVICE";

    } catch (e) {

      debugPrint(
        "Device ID Error: $e",
      );

      return "DEVICE_ERROR";
    }
  }

  // =========================================================
  // FCM TOKEN
  // =========================================================

  Future<String> getFcmToken() async {
    try {

      final FirebaseMessaging messaging =
          FirebaseMessaging.instance;

      // =====================================================
      // WEB
      // =====================================================

      if (kIsWeb) {

        final String? token =
        await messaging.getToken();

        debugPrint(
          "Web FCM Token: $token",
        );

        return token ?? "NO_TOKEN";
      }

      // =====================================================
      // ANDROID
      // =====================================================

      if (Platform.isAndroid) {

        final String? token =
        await messaging.getToken();

        debugPrint(
          "Android FCM Token: $token",
        );

        return token ?? "NO_TOKEN";
      }

      // =====================================================
      // IOS
      // =====================================================

      if (Platform.isIOS) {

        final NotificationSettings settings =
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        debugPrint(
          "Notification permission: "
              "${settings.authorizationStatus}",
        );

        if (
        settings.authorizationStatus !=
            AuthorizationStatus.authorized &&
            settings.authorizationStatus !=
                AuthorizationStatus.provisional
        ) {

          debugPrint(
            "Notification permission denied",
          );

          return "PERMISSION_DENIED";
        }

        String? apnsToken;

        for (int i = 0; i < 10; i++) {

          apnsToken =
          await messaging.getAPNSToken();

          debugPrint(
            "APNs Token attempt "
                "${i + 1}: $apnsToken",
          );

          if (apnsToken != null) {
            break;
          }

          await Future.delayed(
            const Duration(seconds: 1),
          );
        }

        if (apnsToken == null) {

          debugPrint(
            "APNs token is still NULL",
          );

          return "NO_APNS_TOKEN";
        }

        debugPrint(
          "APNs Token: $apnsToken",
        );

        final String? fcmToken =
        await messaging.getToken();

        debugPrint(
          "iOS FCM Token: $fcmToken",
        );

        return fcmToken ??
            "NO_FCM_TOKEN";
      }

      return "UNSUPPORTED_PLATFORM";

    } catch (e, stackTrace) {

      debugPrint(
        "FCM Error: $e",
      );

      debugPrint(
        "StackTrace: $stackTrace",
      );

      return "TOKEN_ERROR";
    }
  }

  // =========================================================
  // LOGIN USER
  // =========================================================

  Future<Map<String, dynamic>> loginUser({
    required String userid,
    required String password,
  }) async {

    try {

      // =====================================================
      // DEVICE
      // =====================================================

      final String imeiNo =
      await getDeviceId();

      debugPrint(
        "IMEI / Device ID: $imeiNo",
      );

      // =====================================================
      // FCM
      // =====================================================

      final String fcmToken =
      await getFcmToken();

      debugPrint(
        "FCM Token: $fcmToken",
      );

      // =====================================================
      // API
      // =====================================================

      final response = await http.post(

        Uri.parse(
          "$baseUrl/loginUser.php",
        ),

        headers: {
          "Content-Type":
          "application/x-www-form-urlencoded",
        },

        body: {

          "userid":
          userid,

          "password":
          password,

          "imei_no":
          imeiNo,

          "user_token":
          fcmToken,
        },
      );

      debugPrint(
        "------------------------------",
      );

      debugPrint(
        "Login Status: "
            "${response.statusCode}",
      );

      debugPrint(
        "Login Response: "
            "${response.body}",
      );

      debugPrint(
        "------------------------------",
      );

      // =====================================================
      // RESPONSE
      // =====================================================

      if (response.statusCode != 200) {

        return {
          "status": false,
          "message":
          "Server Error ${response.statusCode}"
        };
      }

      final Map<String, dynamic> result =
      jsonDecode(response.body);

      // =====================================================
      // LOGIN SUCCESS
      // =====================================================

      if (result["status"] == true) {

        final Map<String, dynamic> data =
        Map<String, dynamic>.from(
          result["data"] ?? {},
        );

        // ===================================================
        // BRANCH MAP
        // ===================================================

        final List<dynamic> rawBranchMap =
            data["branch_map"] ?? [];

        debugPrint(
          "================================",
        );

        debugPrint(
          "TOTAL BRANCHES: "
              "${rawBranchMap.length}",
        );

        for (final item in rawBranchMap) {

          final branch =
          Map<String, dynamic>.from(item);

          debugPrint(
            "--------------------------------",
          );

          debugPrint(
            "Branch ID: "
                "${branch["branch_id"]}",
          );

          debugPrint(
            "Branch Name: "
                "${branch["branch_name"]}",
          );

          debugPrint(
            "Branch Latitude: "
                "${branch["branch_lat"]}",
          );

          debugPrint(
            "Branch Longitude: "
                "${branch["branch_long"]}",
          );

          debugPrint(
            "Branch Distance: "
                "${branch["branch_distance"]}",
          );

          debugPrint(
            "Branch Status: "
                "${branch["status"]}",
          );
        }

        debugPrint(
          "================================",
        );
      }

      return result;

    } catch (e, stackTrace) {

      debugPrint(
        "LOGIN ERROR: $e",
      );

      debugPrint(
        "STACK TRACE: $stackTrace",
      );

      return {
        "status": false,
        "message": e.toString(),
      };
    }
  }
}