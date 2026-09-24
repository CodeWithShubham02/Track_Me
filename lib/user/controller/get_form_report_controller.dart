import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:joizone/api_urls.dart';
import '../model/client_form_report_model.dart';

class SubmitFormController {

  // static const String api =
  //     "https://trackme.joizone.com/attendance/get_reports_by_date.php";

  static Future<List<ClientFormReportModel>> fetchReports(
      String uid, String date) async {

    try {
      final res = await http.get(
        Uri.parse("${ApiUrls.getReportsByDate}?uid=$uid&date=$date"),
      );

      if (res.statusCode == 200) {

        final jsonData = json.decode(res.body);

        if (jsonData['status'] == true) {
          return (jsonData['data'] as List)
              .map((e) => ClientFormReportModel.fromJson(e))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print("Fetch Error: $e");
      return [];
    }
  }
}
