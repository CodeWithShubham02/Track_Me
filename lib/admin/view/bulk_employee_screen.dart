import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:joizone/api_urls.dart';

class BulkEmployeeUploadScreen extends StatefulWidget {
  final String cid;

  const BulkEmployeeUploadScreen({
    super.key,
    required this.cid,
  });

  @override
  State<BulkEmployeeUploadScreen> createState() =>
      _BulkEmployeeUploadScreenState();
}

class _BulkEmployeeUploadScreenState
    extends State<BulkEmployeeUploadScreen> {

  Uint8List? _fileBytes;
  String? _fileName;

  bool _isUploading = false;

  int _totalRows = 0;
  int _successRows = 0;
  int _failedRows = 0;

  List<String> _errors = [];

  // ============================================================
  // SELECT EXCEL FILE
  // ============================================================

  Future<void> selectExcelFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null) return;

      final file = result.files.first;

      if (file.bytes == null) {
        showMessage(
          "Unable to read selected file",
          Colors.red,
        );
        return;
      }

      setState(() {
        _fileBytes = file.bytes;
        _fileName = file.name;

        _totalRows = 0;
        _successRows = 0;
        _failedRows = 0;
        _errors.clear();
      });

      showMessage(
        "File selected successfully",
        Colors.green,
      );

    } catch (e) {
      showMessage(
        "File selection failed: $e",
        Colors.red,
      );
    }
  }

  // ============================================================
  // UPLOAD EXCEL
  // ============================================================

  Future<void> uploadExcel() async {

    if (_fileBytes == null) {
      showMessage(
        "Please select an Excel file first",
        Colors.orange,
      );
      return;
    }

    try {

      setState(() {
        _isUploading = true;
        _errors.clear();
        _successRows = 0;
        _failedRows = 0;
        _totalRows = 0;
      });

      // Read Excel
      final excel = Excel.decodeBytes(_fileBytes!);

      if (excel.tables.isEmpty) {
        throw "Excel file is empty";
      }

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null || sheet.rows.isEmpty) {
        throw "Excel sheet is empty";
      }

      // ========================================================
      // HEADER
      // ========================================================

      final headers = sheet.rows.first
          .map(
            (cell) => cell?.value
            ?.toString()
            .trim()
            .toLowerCase(),
      )
          .toList();

      debugPrint("Excel Headers: $headers");

      // ========================================================
      // REQUIRED COLUMNS
      // ========================================================

      final requiredColumns = [
        "userid",
        "password",
        "full_name",
      ];

      for (final column in requiredColumns) {
        if (!headers.contains(column)) {
          throw "Missing required column: $column";
        }
      }

      // ========================================================
      // CONVERT EXCEL ROWS
      // ========================================================

      final employees = <Map<String, dynamic>>[];

      for (int i = 1; i < sheet.rows.length; i++) {

        final row = sheet.rows[i];

        // Skip completely empty row
        bool isEmpty = row.every(
              (cell) =>
          cell?.value == null ||
              cell!.value.toString().trim().isEmpty,
        );

        if (isEmpty) continue;

        final Map<String, dynamic> employee = {};

        for (int j = 0; j < headers.length; j++) {

          if (j >= row.length) continue;

          final header = headers[j];

          if (header == null || header.isEmpty) continue;

          final value = row[j]?.value;

          employee[header] =
              value?.toString().trim() ?? "";
        }

        employees.add(employee);
      }

      _totalRows = employees.length;

      if (employees.isEmpty) {
        throw "No employee records found";
      }

      // ========================================================
      // UPLOAD TO PHP
      // ========================================================

      final response = await http.post(
        Uri.parse(
          ApiUrls.bulk_create_users,
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "cid": widget.cid,
          "employees": employees,
        }),
      );

      debugPrint(
        "Bulk API Response: ${response.body}",
      );

      if (response.statusCode != 200) {
        throw "Server error: ${response.statusCode}";
      }

      final data = jsonDecode(response.body);

      if (data["status"] != true) {
        throw data["message"] ?? "Upload failed";
      }
      print("=================================");
      print(response.body);
      print(data);
      setState(() {
        _successRows =
            data["data"]["success_count"] ?? 0;

        _failedRows =
            data["data"]["failed_count"] ?? 0;

        _errors =
        List<String>.from(
          data["data"]["errors"] ?? [],
        );
      });

      showMessage(
        data["message"] ?? "Employees uploaded successfully",
        Colors.green,
      );

    } catch (e) {

      showMessage(
        e.toString(),
        Colors.red,
      );

    } finally {

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(
      String message,
      Color color,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Bulk Employee Upload",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xff2563EB),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),

      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(30),

            child: Column(
              children: [

                const Icon(
                  Icons.upload_file,
                  size: 70,
                  color: Color(0xff2563EB),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Bulk Employee Upload",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Upload employee details using an Excel file",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 30),

                // =================================================
                // SELECT FILE
                // =================================================

                SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: OutlinedButton.icon(
                    onPressed:
                    _isUploading
                        ? null
                        : selectExcelFile,

                    icon: const Icon(
                      Icons.attach_file,
                    ),

                    label: Text(
                      _fileName ??
                          "Select Excel File",
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                if (_fileName != null)
                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      borderRadius:
                      BorderRadius.circular(8),
                      color:
                      Colors.grey.shade100,
                    ),

                    child: Row(
                      children: [

                        const Icon(
                          Icons.description,
                          color:
                          Color(0xff2563EB),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            _fileName!,
                            overflow:
                            TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // =================================================
                // UPLOAD BUTTON
                // =================================================

                SizedBox(
                  width: 220,
                  height: 50,

                  child: ElevatedButton.icon(
                    onPressed:
                    _isUploading
                        ? null
                        : uploadExcel,

                    icon: _isUploading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons.cloud_upload,
                    ),

                    label: Text(
                      _isUploading
                          ? "Uploading..."
                          : "Upload Employees",
                    ),

                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xff2563EB),
                      foregroundColor:
                      Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // =================================================
                // RESULT
                // =================================================

                if (_totalRows > 0)
                  Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.all(15),

                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                        Colors.grey.shade300,
                      ),
                      borderRadius:
                      BorderRadius.circular(10),
                    ),

                    child: Column(
                      children: [

                        Text(
                          "Total Employees: $_totalRows",
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Successfully Added: $_successRows",
                          style:
                          const TextStyle(
                            color: Colors.green,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Failed: $_failedRows",
                          style:
                          const TextStyle(
                            color: Colors.red,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_errors.isNotEmpty) ...[
                  const SizedBox(height: 20),

                  const Align(
                    alignment:
                    Alignment.centerLeft,
                    child: Text(
                      "Errors",
                      style: TextStyle(
                        fontWeight:
                        FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  ..._errors.map(
                        (error) => Align(
                      alignment:
                      Alignment.centerLeft,
                      child: Padding(
                        padding:
                        const EdgeInsets.only(
                          bottom: 5,
                        ),
                        child: Text(
                          error,
                          style:
                          const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}