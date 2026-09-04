import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/client_form_report_model.dart';

class GetReportKioskController {
  static const String api =
      "http://15.206.209.30/attendance/get_reports_by_kiosk.php";

  static Future<List<ClientFormReportModel>> fetchReports(
      List<String> kioskNames,
      String date,
      ) async {
    try {
      final kioskName = kioskNames.join(',');

      final uri = Uri.parse(api).replace(
        queryParameters: {
          'kiosk_name': kioskName,
          'date': date,
        },
      );

      print("API: $uri");

      final res = await http.get(uri);

      print("Response: ${res.body}");

      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);

        if (jsonData['status'] == true) {
          return (jsonData['data'] as List)
              .map(
                (e) => ClientFormReportModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
              .toList();
        }
      }

      return [];
    } catch (e) {
      print("❌ Error: $e");
      return [];
    }
  }
}