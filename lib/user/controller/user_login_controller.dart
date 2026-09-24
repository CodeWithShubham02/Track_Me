import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../api_urls.dart';

class UserController {
  // final String baseUrl =
  //     "https://trackme.joizone.com/attendance";
 // http://trackme.joizone.com/trackme/
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
         ApiUrls.loginUser
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

        debugPrint("========================================");
        debugPrint("           LOGIN USER DATA");
        debugPrint("========================================");

        // =====================================================
        // BASIC USER DETAILS
        // =====================================================

        debugPrint("UID              : ${data["uid"]}");
        debugPrint("CID              : ${data["cid"]}");
        debugPrint("USER ID          : ${data["userid"]}");
        debugPrint("USER TOKEN       : ${data["user_token"]}");

        // =====================================================
        // NAME
        // =====================================================

        debugPrint("FULL NAME        : ${data["full_name"]}");
        debugPrint("FIRST NAME       : ${data["first_name"]}");
        debugPrint("MIDDLE NAME      : ${data["middle_name"]}");
        debugPrint("LAST NAME        : ${data["last_name"]}");

        // =====================================================
        // CONTACT
        // =====================================================

        debugPrint("EMAIL            : ${data["user_email"]}");
        debugPrint("PHONE            : ${data["user_phone"]}");

        // =====================================================
        // ROLE / DEPARTMENT
        // =====================================================

        debugPrint("ROLE             : ${data["role"]}");
        debugPrint("ROLE NAME        : ${data["rolename"]}");
        debugPrint("DEPARTMENT ID    : ${data["department_id"]}");
        debugPrint("DEPARTMENT NAME  : ${data["department_name"]}");

        // =====================================================
        // PRIMARY BRANCH
        // =====================================================

        debugPrint("========================================");
        debugPrint("           PRIMARY BRANCH");
        debugPrint("========================================");

        debugPrint("BRANCH ID        : ${data["branch_id"]}");
        debugPrint("BRANCH NAME      : ${data["branch_name"]}");
        debugPrint("BRANCH DISTANCE  : ${data["branch_distance"]}");
        debugPrint("BRANCH LAT       : ${data["branch_lat"]}");
        debugPrint("BRANCH LONG      : ${data["branch_long"]}");

        // =====================================================
        // SHIFT
        // =====================================================

        debugPrint("========================================");
        debugPrint("                SHIFT");
        debugPrint("========================================");

        debugPrint("SHIFT ID         : ${data["shift_id"]}");
        debugPrint("SHIFT START      : ${data["shift_start"]}");
        debugPrint("SHIFT END        : ${data["shift_end"]}");

        // =====================================================
        // OTHER DETAILS
        // =====================================================

        debugPrint("========================================");
        debugPrint("             OTHER DETAILS");
        debugPrint("========================================");

        debugPrint("DATE OF JOINING  : ${data["date_of_joining"]}");
        debugPrint("LAST WORKING     : ${data["last_working_date"]}");
        debugPrint("CITY             : ${data["city_name"]}");
        debugPrint("PIN CODE         : ${data["pin_code"]}");
        debugPrint("DISTRICT         : ${data["district_name"]}");
        debugPrint("REPORTING POS    : ${data["reporting_position"]}");

        // =====================================================
        // IMAGE
        // =====================================================

        debugPrint("USER IMAGE       : ${data["user_image"]}");
        debugPrint("IMAGE            : ${data["image"]}");

        // =====================================================
        // BRANCH MAP
        // =====================================================

        final List<dynamic> rawBranchMap =
            data["branch_map"] ?? [];

        debugPrint("========================================");
        debugPrint("              BRANCH MAP");
        debugPrint("========================================");

        debugPrint(
          "BRANCH COUNT     : ${rawBranchMap.length}",
        );

        if (rawBranchMap.isEmpty) {
          debugPrint("BRANCH MAP       : EMPTY");
        } else {
          for (int i = 0; i < rawBranchMap.length; i++) {
            final item = rawBranchMap[i];

            final branch =
            Map<String, dynamic>.from(item);

            debugPrint("----------------------------------------");
            debugPrint("BRANCH #${i + 1}");
            debugPrint("ID               : ${branch["id"]}");
            debugPrint("UID              : ${branch["uid"]}");
            debugPrint("CID              : ${branch["cid"]}");
            debugPrint("BRANCH ID        : ${branch["branch_id"]}");
            debugPrint("BRANCH NAME      : ${branch["branch_name"]}");
            debugPrint("DISTANCE         : ${branch["branch_distance"]}");
            debugPrint("LAT              : ${branch["branch_lat"]}");
            debugPrint("LONG             : ${branch["branch_long"]}");
            debugPrint("STATUS           : ${branch["status"]}");
          }
        }

        debugPrint("========================================");
        debugPrint("          COMPLETE API DATA");
        debugPrint("========================================");

        debugPrint(
          const JsonEncoder.withIndent("  ")
              .convert(data),
        );

        debugPrint("========================================");
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