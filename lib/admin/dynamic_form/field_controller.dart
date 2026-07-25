import 'dart:convert';
import 'package:http/http.dart' as http;

class FieldController {
  static const String baseUrl =
      "http://15.206.209.30/attendance";

  /// Add Field
  static Future<bool> addField({
    required String templateId,
    required String fieldLabel,
    required String fieldName,
    required String fieldType,
    required String isRequired,
    required String sortOrder,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/add_field.php"),
        body: {
          "template_id": templateId,
          "field_label": fieldLabel,
          "field_name": fieldName,
          "field_type": fieldType,
          "is_required": isRequired,
          "sort_order": sortOrder,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        return json["status"] == true;
      }

      return false;
    } catch (e) {
      print("Add Field Error : $e");
      return false;
    }
  }

  /// Get Fields
  static Future<List<dynamic>> getFields(String templateId) async {
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/get_fields.php?template_id=$templateId",
        ),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print("=======================================");
        print("=======================================");
        print(json);
        print("=======================================");
        print("=======================================");
        if (json["status"] == true) {
          return json["data"] ?? [];
        }
      }

      return [];
    } catch (e) {
      print("Get Fields Error : $e");
      return [];
    }
  }

  ///add option
  static Future<bool> addOption({
    required String fieldId,
    required String optionValue,
  }) async {

    final response = await http.post(
      Uri.parse("$baseUrl/add_option.php"),
      body: {
        "field_id": fieldId,
        "option_value": optionValue,
      },
    );

    final json = jsonDecode(response.body);

    return json["status"] == true;
  }
}