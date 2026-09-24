import 'dart:convert';
import 'package:googleapis/apigeeregistry/v1.dart';
import 'package:http/http.dart' as http;
import 'package:joizone/api_urls.dart';

Future<Map<String, dynamic>> startBreakApi({
  required String attendanceId,
  required String uid,
}) async {
  final url = Uri.parse(ApiUrls.attendanceBreakStart);

  final response = await http.post(
    url,
    body: {
      "attendance_id": attendanceId.toString(),
      "uid": uid.toString(),
    },
  );
  print("-------------------------");
    print(response.statusCode);
  if (response.statusCode == 200) {
    print(response.body);
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to call API");
  }
}

Future<Map<String, dynamic>> endBreakApi({
  required String attendanceId,
  required String uid,
}) async {
  final url = Uri.parse(ApiUrls.attendanceBreakEnd);

  final response = await http.post(
    url,
    body: {
      "attendance_id": attendanceId.toString(),
      "uid": uid.toString(),
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to call End Break API");
  }
}

