import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/client_form_report_model.dart';

class GetReportKioskController {
  static const String api =
      "http://15.206.209.30/attendance/get_reports_by_kiosk.php";

  static Future<List<ClientFormReportModel>> fetchReports(
      String kioskName, String date) async {

    try {
      final res = await http.get(
        Uri.parse("$api?kiosk_name=$kioskName&date=$date"),
      );

      if (res.statusCode == 200) {

        final jsonData = json.decode(res.body);
          print("---------Kiosk By-----------");
          print(jsonData);
          print("--------------------");
        if (jsonData['status'] == true) {
          return (jsonData['data'] as List)
              .map((e) => ClientFormReportModel.fromJson(e))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

}
