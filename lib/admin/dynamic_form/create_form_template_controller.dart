import 'dart:convert';
import 'package:http/http.dart' as http;

Future<bool> createFormTemplate({
  required String cid,
  required String formName,
  required String description,
}) async {
  try {
    final response = await http.post(
      Uri.parse("http://15.206.209.30/attendance/form_templates.php"),
      body: {
        "cid": cid,
        "form_name": formName,
        "description": description,
      },
    );

    print(response.body);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      if (json["status"] == true) {
        return true;
      } else {
        print(json["message"]);
        return false;
      }
    }

    return false;
  } catch (e) {
    print(e);
    return false;
  }
}
