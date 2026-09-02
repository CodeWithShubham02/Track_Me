import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;

class AssignHolidayScreen extends StatefulWidget {
  final String cid;

  const AssignHolidayScreen({
    super.key,
    required this.cid,
  });

  @override
  State<AssignHolidayScreen> createState() =>
      _AssignHolidayScreenState();
}

class _AssignHolidayScreenState
    extends State<AssignHolidayScreen> {

  bool isUploading = false;
  bool isDownloading = false;

  // ============================================================
  // UPLOAD EXCEL
  // ============================================================
  String formatRosterDate(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is DateTime) {
      return "${value.day.toString().padLeft(2, '0')}-"
          "${value.month.toString().padLeft(2, '0')}-"
          "${value.year}";
    }

    final String dateString =
    value.toString().trim();

    if (dateString.isEmpty ||
        dateString.toLowerCase() == 'null') {
      return '';
    }

    try {
      final date = DateTime.parse(dateString);

      return "${date.day.toString().padLeft(2, '0')}-"
          "${date.month.toString().padLeft(2, '0')}-"
          "${date.year}";
    } catch (_) {}

    final regex = RegExp(
      r'^(\d{1,2})-(\d{1,2})-(\d{4})$',
    );

    final match = regex.firstMatch(dateString);

    if (match != null) {
      final day =
      match.group(1)!.padLeft(2, '0');

      final month =
      match.group(2)!.padLeft(2, '0');

      final year =
      match.group(3)!;

      return "$day-$month-$year";
    }

    return dateString;
  }
  Future<void> uploadExcel() async {
    if (isUploading) return;

    try {
      setState(() {
        isUploading = true;
      });

      // ----------------------------------------------------------
      // PICK XLSX FILE
      // ----------------------------------------------------------

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result == null) {
        setState(() {
          isUploading = false;
        });
        return;
      }

      final bytes = result.files.single.bytes;

      if (bytes == null) {
        showMessage(
          "Unable to read Excel file",
          isError: true,
        );

        setState(() {
          isUploading = false;
        });

        return;
      }

      // ----------------------------------------------------------
      // READ EXCEL
      // ----------------------------------------------------------

      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        showMessage(
          "Invalid Excel file. No sheet found.",
          isError: true,
        );

        setState(() {
          isUploading = false;
        });

        return;
      }

      // ----------------------------------------------------------
      // GET FIRST SHEET
      // ----------------------------------------------------------

      final sheetName = excel.tables.keys.first;

      final sheet = excel.tables[sheetName];

      if (sheet == null || sheet.rows.isEmpty) {
        showMessage(
          "Excel sheet is empty",
          isError: true,
        );

        setState(() {
          isUploading = false;
        });

        return;
      }

      // ==========================================================
      // EXPECTED HEADERS
      // ==========================================================

      const List<String> expectedHeaders = [
        "cid",
        "uid",
        "userid",
        "user_type",
        "office_name",
        "status",
        "roster_date",
        "shift_start",
        "shift_end",
      ];

      // ==========================================================
      // READ EXCEL HEADERS
      // ==========================================================

      final List<String> headers = sheet.rows.first
          .map(
            (cell) =>
        cell?.value?.toString().trim() ?? '',
      )
          .toList();

      // ==========================================================
      // NORMALIZE HEADERS
      // ==========================================================

      final List<String> normalizedHeaders = headers
          .map(
            (header) =>
            header.toLowerCase().trim(),
      )
          .toList();

      // ==========================================================
      // FIND MISSING HEADERS
      // ==========================================================

      final List<String> missingHeaders =
      expectedHeaders.where(
            (header) =>
        !normalizedHeaders.contains(header),
      ).toList();

      if (missingHeaders.isNotEmpty) {
        print("Expected Headers: $expectedHeaders");
        print("Found Headers: $normalizedHeaders");
        print("Missing Headers: $missingHeaders");

        showMessage(
          "Invalid Excel format.\n\n"
              "Missing columns:\n"
              "${missingHeaders.join(', ')}",
          isError: true,
        );

        setState(() {
          isUploading = false;
        });

        return;
      }

      // ==========================================================
// READ EXCEL DATA
// ==========================================================

      final List<Map<String, dynamic>> rows = [];

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];

        // --------------------------------------------------------
        // CHECK EMPTY ROW
        // --------------------------------------------------------

        bool isEmptyRow = true;

        for (final cell in row) {
          final value =
              cell?.value?.toString().trim() ?? '';

          if (value.isNotEmpty) {
            isEmptyRow = false;
            break;
          }
        }

        // Skip completely empty row
        if (isEmptyRow) {
          print(
            "Skipping empty Excel row: ${i + 1}",
          );
          continue;
        }

        // --------------------------------------------------------
        // CREATE ROW DATA
        // --------------------------------------------------------

        final Map<String, dynamic> data = {};

        for (int j = 0;
        j < normalizedHeaders.length;
        j++) {

          final String key =
          normalizedHeaders[j];

          String value = '';

          if (j < row.length) {
            final cellValue = row[j]?.value;

            // ======================================================
            // ROSTER DATE
            // ======================================================

            if (key == "roster_date") {
              value = formatRosterDate(cellValue);
            }

            // ======================================================
            // OTHER VALUES
            // ======================================================

            else {
              value =
                  cellValue?.toString().trim() ?? '';
            }
          }

          data[key] = value;
        }

        // --------------------------------------------------------
        // PRINT ROW
        // --------------------------------------------------------

        print("======================================");
        print("Excel Row: ${i + 1}");
        print("CID: ${data["cid"]}");
        print("UID: ${data["uid"]}");
        print("User ID: ${data["userid"]}");
        print("Status: ${data["status"]}");
        print(
          "Roster Date: ${data["roster_date"]}",
        );
        print(
          "Shift Start: ${data["shift_start"]}",
        );
        print(
          "Shift End: ${data["shift_end"]}",
        );
        print("======================================");

        rows.add(data);
      }

      // ==========================================================
      // NO DATA CHECK
      // ==========================================================

      if (rows.isEmpty) {
        showMessage(
          "No roster records found in Excel",
          isError: true,
        );

        setState(() {
          isUploading = false;
        });

        return;
      }

      // ==========================================================
      // LOCAL VALIDATION
      // ==========================================================

      final validationError =
      validateRosterRows(rows);

      if (validationError != null) {
        showMessage(
          validationError,
          isError: true,
        );

        setState(() {
          isUploading = false;
        });

        return;
      }

      // ==========================================================
      // PRINT DATA
      // ==========================================================

      print("======================================");
      print("ROSTER EXCEL DATA");
      print("======================================");

      for (final row in rows) {
        print(row);
      }

      print("======================================");
      print("TOTAL RECORDS: ${rows.length}");
      print("======================================");

      // ==========================================================
      // SEND TO API
      // ==========================================================

      await sendToApi(rows);

    } catch (e) {
      print("Excel Upload Error: $e");

      if (mounted) {
        showMessage(
          "Excel upload error: $e",
          isError: true,
        );
      }

      setState(() {
        isUploading = false;
      });
    }
  }

  // ============================================================
  // VALIDATE ROSTER ROWS
  // ============================================================

  String? validateRosterRows(
      List<Map<String, dynamic>> rows,
      ) {
    const allowedStatuses = [
      "PRESENT",
      "ABSENT",
      "WO",
    ];

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];

      final excelRowNumber = i + 2;

      // ----------------------------------------------------------
      // CID
      // ----------------------------------------------------------

      final cid =
          row["cid"]?.toString().trim() ?? '';

      if (cid.isEmpty) {
        return "Row $excelRowNumber: CID is missing";
      }

      // ----------------------------------------------------------
      // UID
      // ----------------------------------------------------------

      final uid =
          row["uid"]?.toString().trim() ?? '';

      if (uid.isEmpty) {
        return "Row $excelRowNumber: UID is missing";
      }

      // ----------------------------------------------------------
      // USER ID
      // ----------------------------------------------------------

      final userid =
          row["userid"]?.toString().trim() ?? '';

      if (userid.isEmpty) {
        return "Row $excelRowNumber: User ID is missing";
      }

      // ----------------------------------------------------------
      // STATUS
      // ----------------------------------------------------------

      final status =
          row["status"]?.toString().trim().toUpperCase() ?? '';
      print("======================================");
      print("Status");
      print("======================================");
      print(status);

      if (status.isEmpty) {
        return "Row $excelRowNumber: Status is missing";
      }

      if (!allowedStatuses.contains(status)) {
        return "Row $excelRowNumber: "
            "Invalid status '$status'. "
            "Allowed: PRESENT, ABSENT, WO";
      }

      // ----------------------------------------------------------
      // ROSTER DATE
      // ----------------------------------------------------------

      final rosterDate =
          row["roster_date"]?.toString().trim() ?? '';

      if (rosterDate.isEmpty) {
        return "Row $excelRowNumber: Roster date is missing";
      }

      // ----------------------------------------------------------
      // SHIFT START
      // ----------------------------------------------------------

      final shiftStart =
          row["shift_start"]?.toString().trim() ?? '';

      if (shiftStart.isEmpty) {
        return "Row $excelRowNumber: Shift start is missing";
      }

      // ----------------------------------------------------------
      // SHIFT END
      // ----------------------------------------------------------

      final shiftEnd =
          row["shift_end"]?.toString().trim() ?? '';

      if (shiftEnd.isEmpty) {
        return "Row $excelRowNumber: Shift end is missing";
      }
    }

    return null;
  }

  // ============================================================
  // SEND DATA TO PHP API
  // ============================================================

  Future<void> sendToApi(
      List<Map<String, dynamic>> data,
      ) async {
    try {
      // ==========================================================
      // CLEAN DATA BEFORE API
      // ==========================================================

      final List<Map<String, dynamic>> cleanData = [];

      for (final row in data) {
        cleanData.add({
          "cid": row["cid"]?.toString().trim() ?? "",
          "uid": row["uid"]?.toString().trim() ?? "",
          "userid": row["userid"]?.toString().trim() ?? "",
          "user_type": row["user_type"]?.toString().trim() ?? "",
          "office_name":
          row["office_name"]?.toString().trim() ?? "",
          "status":
          row["status"]?.toString().trim().toUpperCase() ?? "",
          "roster_date":
          row["roster_date"]?.toString().trim() ?? "",
          "shift_start":
          row["shift_start"]?.toString().trim() ?? "",
          "shift_end":
          row["shift_end"]?.toString().trim() ?? "",
        });
      }

      print("======================================");
      print("DATA SENT TO API");
      print("======================================");

      for (final row in cleanData) {
        print(row);
      }

      print("======================================");

      final response = await http.post(
        Uri.parse(
          "http://15.206.209.30/attendance/user_holiday.php",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "records": cleanData,
        }),
      );

      print("======================================");
      print("ROSTER UPLOAD API");
      print("======================================");

      print("Status Code: ${response.statusCode}");
      print("Response:");
      print(response.body);

      print("======================================");

      if (response.statusCode != 200) {
        throw Exception(
          "Server Error ${response.statusCode}\n"
              "${response.body}",
        );
      }

      if (response.body.trim().isEmpty) {
        throw Exception(
          "Empty response from server",
        );
      }

      final responseData = jsonDecode(response.body);

      if (responseData["status"] == true) {
        final dataResponse =
            responseData["data"] ?? {};

        final int totalRecords =
            int.tryParse(
              "${dataResponse["total_records"] ?? 0}",
            ) ??
                0;

        final int success =
            int.tryParse(
              "${dataResponse["success"] ?? 0}",
            ) ??
                0;

        final int failed =
            int.tryParse(
              "${dataResponse["failed"] ?? 0}",
            ) ??
                0;

        final int rosterInserted =
            int.tryParse(
              "${dataResponse["roster_inserted"] ?? 0}",
            ) ??
                0;

        final int rosterUpdated =
            int.tryParse(
              "${dataResponse["roster_updated"] ?? 0}",
            ) ??
                0;

        final int attendanceInserted =
            int.tryParse(
              "${dataResponse["attendance_inserted"] ?? 0}",
            ) ??
                0;

        final int attendanceSkipped =
            int.tryParse(
              "${dataResponse["attendance_skipped"] ?? 0}",
            ) ??
                0;

        print("======================================");
        print("UPLOAD RESULT");
        print("======================================");

        print("Total Records: $totalRecords");
        print("Success: $success");
        print("Failed: $failed");
        print("Roster Inserted: $rosterInserted");
        print("Roster Updated: $rosterUpdated");
        print(
          "WO Attendance Inserted: "
              "$attendanceInserted",
        );
        print(
          "Attendance Skipped: "
              "$attendanceSkipped",
        );

        print("======================================");

        if (dataResponse["logs"] != null) {
          print("LOGS:");

          for (final log in dataResponse["logs"]) {
            print(log);
          }
        }

        if (!mounted) return;

        showUploadResultDialog(
          totalRecords: totalRecords,
          success: success,
          failed: failed,
          rosterInserted: rosterInserted,
          rosterUpdated: rosterUpdated,
          attendanceInserted: attendanceInserted,
          attendanceSkipped: attendanceSkipped,
        );
      } else {
        final message =
            responseData["message"] ??
                "Roster upload failed";

        if (!mounted) return;

        showMessage(
          message.toString(),
          isError: true,
        );
      }
    } catch (e) {
      print("API Upload Error: $e");

      if (!mounted) return;

      showMessage(
        "Upload failed:\n$e",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  // ============================================================
  // FETCH USERS
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://15.206.209.30/attendance/"
              "get_users_cid.php?cid=${widget.cid}",
        ),
      );

      print("Users API Status: ${response.statusCode}");
      print("Users API Response: ${response.body}");

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to fetch users: "
              "${response.statusCode}",
        );
      }

      if (response.body.trim().isEmpty) {
        throw Exception(
          "Empty response from users API",
        );
      }

      final data =
      jsonDecode(response.body);

      if (data["status"] == true) {
        final users = data["data"];

        if (users is List) {
          return List<Map<String, dynamic>>.from(
            users.map(
                  (user) =>
              Map<String, dynamic>.from(user),
            ),
          );
        }
      }

      return [];

    } catch (e) {
      print("Fetch Users Error: $e");
      rethrow;
    }
  }

  // ============================================================
  // DOWNLOAD TEMPLATE
  // ============================================================

  Future<void> downloadTemplate() async {
    if (isDownloading) return;

    try {
      setState(() {
        isDownloading = true;
      });

      // ========================================================
      // STORAGE PERMISSION
      // ========================================================

      if (!kIsWeb) {
        final permission =
        await Permission.storage.request();

        if (!permission.isGranted) {
          showMessage(
            "Storage permission denied",
            isError: true,
          );

          setState(() {
            isDownloading = false;
          });

          return;
        }
      }

      // ========================================================
      // CREATE EXCEL
      // ========================================================

      final excel = Excel.createExcel();

      // ========================================================
      // SHEET 1 - TEMPLATE
      // ========================================================

      final sheet1 =
      excel["Template"];

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

      // ========================================================
      // SHEET 2 - USERS
      // ========================================================

      final sheet2 =
      excel["Users"];

      sheet2.appendRow([
        TextCellValue("cid"),
        TextCellValue("uid"),
        TextCellValue("userid"),
        TextCellValue("user_type"),
        TextCellValue("office_name"),
      ]);

      // ========================================================
      // FETCH USERS
      // ========================================================

      List<Map<String, dynamic>> users =
      await fetchUsers();

      if (users.isEmpty) {
        print("No users found for CID: ${widget.cid}");
      }

      // ========================================================
      // ADD USERS TO EXCEL
      // ========================================================

      for (final user in users) {
        sheet2.appendRow([
          TextCellValue(
            "${user["cid"] ?? ""}",
          ),
          TextCellValue(
            "${user["uid"] ?? ""}",
          ),
          TextCellValue(
            "${user["userid"] ?? ""}",
          ),
          TextCellValue(
            "${user["department_name"] ?? ""}",
          ),
          TextCellValue(
            "${user["branch_name"] ?? ""}",
          ),
        ]);
      }

      // ========================================================
      // SHEET 3 - STATUS
      // ========================================================

      final sheet3 =
      excel["Status"];

      sheet3.appendRow([
        TextCellValue("status"),
      ]);

      const List<String> rosterStatus = [
        "PRESENT",
        "ABSENT",
        "WO",
      ];

      for (final status in rosterStatus) {
        sheet3.appendRow([
          TextCellValue(status),
        ]);
      }

      // ========================================================
      // DELETE DEFAULT SHEET
      // ========================================================

      if (excel.tables.containsKey("Sheet1")) {
        excel.delete("Sheet1");
      }

      // ========================================================
      // ENCODE
      // ========================================================

      final fileBytes = excel.encode();

      if (fileBytes == null) {
        throw Exception(
          "Unable to generate Excel file",
        );
      }

      // ========================================================
      // WEB
      // ========================================================

      if (kIsWeb) {
        downloadForWeb(fileBytes);
      }

      // ========================================================
      // ANDROID / IOS
      // ========================================================

      else {
        final directory =
        await getExternalStorageDirectory();

        if (directory == null) {
          throw Exception(
            "Unable to access storage directory",
          );
        }

        final filePath =
            "${directory.path}/roster_template.xlsx";

        final file = File(filePath);

        await file.create(
          recursive: true,
        );

        await file.writeAsBytes(
          fileBytes,
        );

        if (mounted) {
          showMessage(
            "Template saved successfully:\n$filePath",
          );
        }
      }

    } catch (e) {
      print("Download Template Error: $e");

      if (mounted) {
        showMessage(
          "Error: $e",
          isError: true,
        );
      }

    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
  }

  // ============================================================
  // WEB DOWNLOAD
  // ============================================================

  void downloadForWeb(
      List<int> bytes,
      ) {
    final blob =
    html.Blob([bytes]);

    final url =
    html.Url.createObjectUrlFromBlob(
      blob,
    );

    final anchor =
    html.AnchorElement(
      href: url,
    )
      ..setAttribute(
        "download",
        "roster_template.xlsx",
      )
      ..click();

    html.Url.revokeObjectUrl(
      url,
    );
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError
            ? Colors.red
            : Colors.green,
        duration:
        const Duration(seconds: 4),
      ),
    );
  }

  // ============================================================
  // UPLOAD RESULT DIALOG
  // ============================================================

  void showUploadResultDialog({
    required int totalRecords,
    required int success,
    required int failed,
    required int rosterInserted,
    required int rosterUpdated,
    required int attendanceInserted,
    required int attendanceSkipped,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              SizedBox(width: 8),
              Text("Upload Completed"),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                resultRow(
                  "Total Records",
                  totalRecords,
                ),
                resultRow(
                  "Successful",
                  success,
                ),
                resultRow(
                  "Failed",
                  failed,
                ),
                const Divider(),
                resultRow(
                  "Roster Inserted",
                  rosterInserted,
                ),
                resultRow(
                  "Roster Updated",
                  rosterUpdated,
                ),
                const Divider(),
                resultRow(
                  "WO Attendance Inserted",
                  attendanceInserted,
                ),
                resultRow(
                  "Attendance Skipped",
                  attendanceSkipped,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // RESULT ROW
  // ============================================================

  Widget resultRow(
      String title,
      int value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            "$value",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
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
        title: const Text(
          "Work Schedule",
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding:
          const EdgeInsets.all(12),
          child: Center(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.center,
              children: [

                const SizedBox(height: 20),

                // ==================================================
                // IMAGE
                // ==================================================

                Image.asset(
                  "assets/image/rosterimg.JPG",
                ),

                const SizedBox(height: 15),

                // ==================================================
                // DOWNLOAD TEMPLATE
                // ==================================================

                SizedBox(
                  width: 260,
                  child: ElevatedButton.icon(
                    onPressed:
                    isDownloading
                        ? null
                        : downloadTemplate,
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(
                        0xff2563EB,
                      ),
                      foregroundColor:
                      Colors.white,
                      elevation: 5,
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          6,
                        ),
                      ),
                    ),
                    icon:
                    isDownloading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                        Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons
                          .download,
                    ),
                    label: Text(
                      isDownloading
                          ? "Downloading..."
                          : "Download Template",
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // WARNING
                // ==================================================

                const Text(
                  "⚠ If the cid, uid, or office_name does not "
                      "match, the roster upload may be rejected.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // RULE CARD
                // ==================================================

                Card(
                  margin:
                  const EdgeInsets.all(4),
                  elevation: 3,
                  child: Padding(
                    padding:
                    const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "📌 Roster Upload Rules",
                          style:
                          TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        const Text(
                          "• cid – Company ID (Numeric)",
                        ),

                        const Text(
                          "• uid – User ID (Numeric)",
                        ),

                        const Text(
                          "• userid – Example: jzx001",
                        ),

                        const Text(
                          "• user_type – User Type Name",
                        ),

                        const Text(
                          "• office_name – Office Name",
                        ),

                        const Text(
                          "• status – PRESENT, ABSENT, WO",
                        ),

                        const Text(
                          "• roster_date – DD-MM-YYYY",
                        ),

                        const Text(
                          "• shift_start – Example: 5:00 AM",
                        ),

                        const Text(
                          "• shift_end – Example: 1:00 PM",
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        const Text(
                          "⚠ Date and time format must "
                              "follow the template.",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // UPLOAD TITLE
                // ==================================================

                const Text(
                  "Upload the formatted Excel file",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // UPLOAD BUTTON
                // ==================================================

                SizedBox(
                  width: 260,
                  child: ElevatedButton.icon(
                    onPressed:
                    isUploading
                        ? null
                        : uploadExcel,
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(
                        0xff2563EB,
                      ),
                      foregroundColor:
                      Colors.white,
                      elevation: 5,
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          6,
                        ),
                      ),
                    ),
                    icon:
                    isUploading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                        Colors.white,
                      ),
                    )
                        : const Icon(
                      Icons
                          .upload_file,
                    ),
                    label: Text(
                      isUploading
                          ? "Uploading..."
                          : "Select Excel File",
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // LOGIC INFORMATION
                // ==================================================

                Card(
                  elevation: 2,
                  child: Padding(
                    padding:
                    const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: const [

                        Text(
                          "Attendance Logic",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 10),

                        Text(
                          "PRESENT → Roster Shift saved, "
                              "Attendance not inserted.",
                        ),

                        SizedBox(height: 5),

                        Text(
                          "ABSENT → Roster Shift saved, "
                              "Attendance not inserted.",
                        ),

                        SizedBox(height: 5),

                        Text(
                          "WO → Roster Shift saved + "
                              "WO inserted into Attendance.",
                        ),

                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}