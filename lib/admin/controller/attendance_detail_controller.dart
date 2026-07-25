import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/attendance_detail_model.dart';

class AttendanceMultiService {
  static Future<AttendanceMultiModel?> fetchAttendance(
      String uid, String date) async {
    final response = await http.post(
      Uri.parse("https://fms.bizipac.com/apinew/attendance/attendance_details.php"),
      body: {
        "uid": uid,
        "date": date,
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData['status'] == true) {
        return AttendanceMultiModel.fromJson(jsonData);
      }
    }

    return null;
  }
}
