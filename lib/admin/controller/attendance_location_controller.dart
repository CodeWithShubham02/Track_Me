import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/attendance_location_model.dart';

class AttendanceLocationService {
  static const String apiUrl =
      "http://15.206.209.30/attendance/attendance_location_by_id.php";

  static Future<List<AttendanceLocationModel>> fetchByAttendanceId(
      String attendanceId) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        "uid": attendanceId,
      },
    );

    final decoded = json.decode(response.body);

    List list = decoded['data'];

    return list
        .map((e) => AttendanceLocationModel.fromJson(e))
        .toList();
  }
}
