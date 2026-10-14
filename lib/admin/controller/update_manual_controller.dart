import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';

import '../../api_urls.dart';
import 'package:http/http.dart' as http;

class UpdateManualController {

  Future<bool> updateManualPunchOut({
    required String attendanceId,
    required String punchOutTime,
    required String punchOutLat,
    required String punchOutLng,
    required String punchOutRemark,
    required String punchOutImage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${ApiUrls.updateManualPunchOut}?attendance_id=$attendanceId',
        ),
        body: {
          "punch_out_time": punchOutTime,
          "punch_out_lat": punchOutLat,
          "punch_out_lng": punchOutLng,
          "punch_out_remark": punchOutRemark,
          "punch_out_image": punchOutImage,
        },
      );

      debugPrint("Update Punch Out Response:");
      debugPrint(response.body);

      if (response.statusCode != 200) {
        Get.snackbar(
          "Error",
          "Server error: ${response.statusCode}",
          snackPosition: SnackPosition.TOP,
        );

        return false;
      }

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        return true;
      }

      Get.snackbar(
        "Failed",
        data['message']?.toString() ?? "Attendance update failed",
        snackPosition: SnackPosition.TOP,
      );

      return false;

    } catch (e) {

      debugPrint("Update Punch Out Error: $e");

      Get.snackbar(
        "Error",
        "Something went wrong",
        snackPosition: SnackPosition.TOP,
      );

      return false;
    }
  }
}