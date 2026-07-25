import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/shared.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;
class AssignHolidayScreen extends StatefulWidget {
  final String cid;
  const AssignHolidayScreen({super.key,required this.cid});

  @override
  State<AssignHolidayScreen> createState() => _AssignHolidayScreenState();
}

class _AssignHolidayScreenState extends State<AssignHolidayScreen> {

  Future<void> uploadExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result == null) return;

    final bytes = result.files.single.bytes;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to read file")),
      );
      return;
    }

    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];

    if (sheet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Excel sheet")),
      );
      return;
    }

    // ✅ EXPECTED HEADERS
    List<String> expectedHeaders = [
      "cid",
      "uid",
      "userid",
      "user_type",
      "office_name",
      "status",
      "roster_date",
      "shift_start",
      "shift_end"
    ];

    // Normalize
    List<String> normalize(List<String> list) {
      return list.map((e) => e.toLowerCase().trim()).toList();
    }

    final headers =
    sheet.rows.first.map((e) => e?.value.toString() ?? '').toList();

    final normalizedHeaders = normalize(headers);
    final normalizedExpected = normalize(expectedHeaders);

// Flexible validation
    bool isValid = normalizedExpected.every(
          (h) => normalizedHeaders.contains(h),
    );


    if (!isValid) {
      print("Expected: $normalizedExpected");
      print("Found: $normalizedHeaders");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Something went wrong! Invalid Excel format")),
      );
      return;
    }

    // ✅ READ DATA
    List<Map<String, dynamic>> rows = [];

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      Map<String, dynamic> data = {};

      for (int j = 0; j < headers.length; j++) {
        data[headers[j]] =
        j < row.length ? row[j]?.value.toString() ?? '' : '';
      }

      rows.add(data);
    }

    await sendToApi(rows);
  }

  Future<void> sendToApi(List<Map<String, dynamic>> data) async {
    try {
      final res = await http.post(
        Uri.parse("http://15.206.209.30/attendance/user_holiday.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"records": data}),
      );
      print("data : $data");

      print("Status: ${res.statusCode}");
      print("Body: ${res.body}");

      if (res.statusCode != 200) {
        throw Exception(
          "Server Error ${res.statusCode}\n${res.body}",
        );
      }

      if (res.body.trim().isEmpty) {
        throw Exception("Empty response from server");
      }

      final response = jsonDecode(res.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Upload completed'),
          backgroundColor:
          response['status'] == true ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      print("-----------------------");
      print(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final res = await http.get(
      Uri.parse("http://15.206.209.30/attendance/get_users_cid.php?cid=${widget.cid}"),
    );

    final data = jsonDecode(res.body);

    if (data['status'] == true) {
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      return [];
    }
  }
  Future<void> downloadTemplate() async {
    try {
      if (!kIsWeb) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Storage permission denied")),
          );
          return;
        }
      }

      final excel = Excel.createExcel();

      // 🟢 Sheet 1 → Template
      final sheet1 = excel['Template'];

      sheet1.appendRow([
        TextCellValue("cid"),
        TextCellValue("uid"),
        TextCellValue("userid"),
        TextCellValue("user_type"),
        TextCellValue("office_name"),
        TextCellValue("status"),
        TextCellValue("roster_date"),
        TextCellValue("shift_start"),
        TextCellValue("shift_end"),
      ]);

      // 🟡 Sheet 2 → Users Data
      final sheet2 = excel['Users'];

      sheet2.appendRow([
        TextCellValue("cid"),
        TextCellValue("uid"),
        TextCellValue("userid"),
        TextCellValue("user_type"),
        TextCellValue("office_name"),
      ]);

      // 🔥 API CALL
      List<Map<String, dynamic>> users = await fetchUsers();

      // ⚠️ Safety check
      if (users.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No users data found")),
        );
      }

      // ✅ Fill Users Sheet
      for (var user in users) {
        sheet2.appendRow([
          TextCellValue("${user['cid'] ?? ''}"),
          TextCellValue("${user['uid'] ?? ''}"),
          TextCellValue("${user['userid'] ?? ''}"),
          TextCellValue("${user['department_name'] ?? ''}"),
          TextCellValue("${user['branch_name'] ?? ''}"),
        ]);
      }
      final sheet3 = excel['status'];

      List<String> roster_status = ['PRESENT', 'ABSENT', 'WO'];

      sheet3.appendRow([
        TextCellValue("status"),
      ]);

      if (roster_status.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No status data found")),
        );
      }

      for (var status in roster_status) {
        sheet3.appendRow([
          TextCellValue(status),
        ]);
      }
      // ❗ Default "Sheet1" remove (important)
      excel.delete('Sheet1');

      final fileBytes = excel.encode();
      if (fileBytes == null) return;

      if (kIsWeb) {
        downloadForWeb(fileBytes);
      } else {
        final dir = await getExternalStorageDirectory();
        final filePath = "${dir!.path}/roster_template.xlsx";

        final file = File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Saved at: $filePath")),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
  void downloadForWeb(List<int> bytes) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "roster_template.xlsx")
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xff2563EB),
                Color(0xff1D4ED8),
              ],
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text("Work Schedule", style: TextStyle(fontSize: 18,color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Image.asset("assets/image/rosterimg.JPG"),
                SizedBox(height: 10,),
                ElevatedButton.icon(
                  onPressed:downloadTemplate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff2563EB),
                    foregroundColor: Colors.white,
                    elevation: 5,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Download Templete"),
                ),
                Text(
                  "⚠ If the cid, uid, or office_name does not match, the roster upload will be rejected.",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                Card(
                  margin: EdgeInsets.all(12),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "📌 Roster Upload Rules",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text("• cid – Company ID (Numeric)"),
                        Text("• uid – User ID (Numeric)"),
                        Text("• userid – jzx001"),
                        Text("• user_type – User Type Name"),
                        Text("• office_name – Office Name"),
                        Text("• status – WO,PRESENT,ABSENT"),
                        Text("• roster_date – DD-MM-YYYY"),
                        Text("• shift_start – HH:MM AM (7:00 AM)"),
                        Text("• shift_end – HH:MM PM (2:00 PM)"),
                        SizedBox(height: 6),
                        Text(
                          "⚠ Date & Time format strictly follow karein.",
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                )
                    ,
                const SizedBox(height: 20),
                const Text(
                  "This formate excel file upload.",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: uploadExcel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff2563EB),
                    foregroundColor: Colors.white,
                    elevation: 5,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Select File"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
