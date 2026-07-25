import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:joizone/admin/view/all_form_report_screen.dart';

class UploadRemarkScreen extends StatefulWidget {
  const UploadRemarkScreen({super.key});

  @override
  State<UploadRemarkScreen> createState() => _UploadRemarkScreenState();
}

class _UploadRemarkScreenState extends State<UploadRemarkScreen> {
  List<List<dynamic>> excelData = [];

  Future<void> uploadExcelData() async {

    if (excelData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload excel first")),
      );
      return;
    }

    List<Map<String, dynamic>> rows = [];

    for (int i = 1; i < excelData.length; i++) {

      rows.add({
        "application_number": excelData[i][6].toString(),
        "remark": excelData[i][16].toString(),
      });

    }

    try {

      var response = await http.post(
        Uri.parse("http://15.206.209.30/attendance/update_excel_remark.php"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: jsonEncode({"rows": rows}),
      );

      print("STATUS CODE: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.body.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Empty response from server")),
        );
        return;
      }

      var data = jsonDecode(response.body);

      if (data["status"] == true) {
        int uploadedCount = rows.length;
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => const AllFormReportScreen(),
        //   ),
        // );
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Upload Remark Successful. $uploadedCount file uploaded"),
             duration: const Duration(seconds: 4),),

        );

      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Upload Failed")),
        );

        setState(() {});
      }

    } catch (e) {

      print("API ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );

    }
  }
  // PICK EXCEL FILE
  Future<void> pickExcelFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result == null) return;

    var bytes = result.files.single.bytes;
    var excel = Excel.decodeBytes(bytes!);

    excelData.clear();

    // ✅ Check sheet exists
    if (excel.tables.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Excel has no sheets ❌")),
      );
      return;
    }

    // ✅ Get first sheet
    var sheet = excel.tables[excel.tables.keys.first];

    if (sheet == null || sheet.rows.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Excel sheet is empty ❌")),
      );
      return;
    }

    // ✅ Read data
    for (var row in sheet.rows) {
      excelData.add(row.map((cell) => cell?.value ?? "").toList());
    }

    // ✅ Check empty
    if (excelData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No data found ❌")),
      );
      return;
    }

    // ✅ EXPECTED HEADERS
    List<String> expectedHeaders = [
      "Report Id",
      "User ID",
      "User Name",
      "City Name",
      "Report Date",
      "Report Time",
      "Application Number",
      "Relation",
      "Variant",
      "Status",
      "Remarks",
      "Manager Remarks",
      "Snapshot",
      "Contact No",
      "Address",
      "Kiosk Name",
      "Bank Remark",
      "RemarksDate",
    ];

    // ✅ Normalize function (ignore case + spaces)
    String normalize(String s) =>
        s.replaceAll(" ", "").toLowerCase();

    List<String> fileHeaders =
    excelData.first.map((e) => normalize(e.toString())).toList();

    List<String> expected =
    expectedHeaders.map((e) => normalize(e)).toList();

    // ✅ Check missing & extra
    List<String> missing = [];
    List<String> extra = [];

    for (var col in expected) {
      if (!fileHeaders.contains(col)) missing.add(col);
    }

    for (var col in fileHeaders) {
      if (!expected.contains(col)) extra.add(col);
    }

    // ❌ Invalid file
    if (missing.isNotEmpty || extra.isNotEmpty) {
      excelData.clear();

      String error = "";

      if (missing.isNotEmpty) {
        error += "Missing Columns:\n${missing.join(", ")}\n\n";
      }

      if (extra.isNotEmpty) {
        error += "Extra Columns:\n${extra.join(", ")}";
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Invalid Excel ❌"),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );

      return;
    }

    // ✅ VALID FILE
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Valid Excel File ✅")),
    );

    setState(() {});
  }
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        backgroundColor: Colors.blue,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text("Upload Template",style: TextStyle(fontSize: 16,color: Colors.white),),
        actions: [
          ElevatedButton(
            onPressed: () {
              pickExcelFile();
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5), // Perfect square corners
              ),
            ),
            child: const Text("Select Remark File"),
          ),
          const SizedBox(
            width: 10,
          ),
          ElevatedButton(
            onPressed: () {
              uploadExcelData();
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5), // Perfect square corners
              ),
            ),
            child: const Text('Upload Remark File'),
          ),
          const SizedBox(
            width: 10,
          ),
          // IconButton(
          //   onPressed: () {
          //     showDialog(
          //       context: context,
          //       builder: (context) {
          //         return AlertDialog(
          //           title: const Text("Remarks Final Upload File"),
          //           content: const Text("-----------------------"),
          //           actions: [
          //             ElevatedButton(
          //               onPressed: () {
          //                 pickExcelFile();
          //                 Get.back();
          //               },
          //               child: Row(
          //                 children: [
          //                   Container(child: Text("Select Remark file")),
          //                 ],
          //               ),
          //             ),
          //             const SizedBox(
          //               height: 40,
          //             ),
          //             ElevatedButton(
          //               onPressed: () {
          //                 uploadExcelData();
          //               },
          //               child: Row(
          //                 children: [
          //                   Container(child: Text("Upload Remark file")),
          //                 ],
          //               ),
          //             ),
          //           ],
          //         );
          //       },
          //     );
          //   },
          //   icon: const Icon(Icons.menu),
          // ),
        ],
      ),
      body: excelData.isEmpty
          ? const Center(child: Text("Upload Excel File"))
          : Scrollbar(
        controller: _verticalController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _verticalController,
          scrollDirection: Axis.vertical,
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: excelData.first.length * 150,
                ),
                child: DataTable(
                  border: TableBorder.all(color: Colors.grey),
                  headingRowColor:
                  MaterialStateProperty.all(Colors.blue.shade100),

                  columns: excelData.first
                      .map(
                        (e) => DataColumn(
                      label: Text(
                        e.toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                      .toList(),

                  rows: excelData
                      .skip(1)
                      .map(
                        (row) => DataRow(
                      cells: row
                          .map(
                            (cell) => DataCell(
                          SizedBox(
                            width: 150,
                            child: Text(cell.toString()),
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
