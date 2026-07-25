import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceController {
  static const String url =
      "http://15.206.209.30/attendance/fetch_attendance_by_kiosk.php";

  static Future<List<Map<String, dynamic>>> fetchAttendance({
    required String officeName,
    required String fromDate,
    required String toDate,
  }) async {

    final response = await http.post(
      Uri.parse(url),
      body: {
        "office_name": officeName,
        "from_date": fromDate,
        "to_date": toDate,
      },
    );

    final jsonData = jsonDecode(response.body);

    if (jsonData["status"] == true) {
      return List<Map<String, dynamic>>.from(jsonData["data"]);
    }

    return [];
  }
}