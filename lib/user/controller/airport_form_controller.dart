import 'dart:convert';
import 'package:http/http.dart' as http;
import '../airport_form_model.dart';

class AirportFormController {
  static const String apiUrl =
      "http://15.206.209.30/attendance/add_report.php";

  static Future<bool> submitForm(AirportFormModel model) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(model.toJson()), // ✅ send JSON
      );

      print("API Response: ${response.body}");

      final jsonData = json.decode(response.body);

      return jsonData["status"] == true;
    } catch (e) {
      print("Error submitting form: $e");
      return false;
    }
  }
}
