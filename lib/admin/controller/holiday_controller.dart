import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/assign_holiday_model.dart';

class HolidayController {
  final String baseUrl = "http://15.206.209.30/attendance/assign_holiday.php";

  Future<HolidayAssignModel> assignHoliday({
    required String cid,
    required String uid,
    required String name,
    required String department,
    required String officeName,
    required String status,
    required DateTime date,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      body: {
        "cid": cid,
        "uid": uid,
        "name": name,
        "department": department,
        "office_name": officeName,
        "status": status,
        "date": date.toIso8601String().split("T")[0],
      },
    );

    final data = jsonDecode(response.body);
    return HolidayAssignModel.fromJson(data);
  }
}
