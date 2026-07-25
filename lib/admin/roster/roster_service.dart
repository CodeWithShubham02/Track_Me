import 'dart:convert';

import 'package:http/http.dart' as http;

class RosterService {

  static const String api =
      "http://15.206.209.30/attendance/user_holiday.php";

  static Future<Map<String, dynamic>> uploadRoster(
      List<Map<String, dynamic>> records) async {

    final response = await http.post(
      Uri.parse(api),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "records": records,
      }),
    );

    return jsonDecode(response.body);
  }
}