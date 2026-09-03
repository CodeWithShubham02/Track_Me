import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;

import '../controller/attendance_summary_controller.dart';
import '../model/attendance_summary_model.dart';

class AttendanceSummaryScreen extends StatefulWidget {
  final String cid;
  const AttendanceSummaryScreen({super.key, required this.cid});

  @override
  State<AttendanceSummaryScreen> createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  bool isLoading = false;
  List<AttendanceSummary> records = [];

  Future<void> pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      saveText: "Submit",
    );

    if (picked != null) {
      setState(() => isLoading = true);

      final from = DateFormat('yyyy-MM-dd').format(picked.start);
      final to = DateFormat('yyyy-MM-dd').format(picked.end);

      records = await AttendanceSummaryController.fetchSummary(
        fromDate: from,
        toDate: to,
        cid: widget.cid
      );
      allRecords = records;

      officeList = allRecords.map((e) => e.officeName).toSet().toList();
      userTypeList = allRecords.map((e) => e.department).toSet().toList();
      setState(() => isLoading = false);

    }
  }

  String formatDate(String date) {
    if (date.isEmpty) return "-";
    return DateFormat('dd MMM yyyy')
        .format(DateTime.parse(date));
  }

  Future<void> downloadSummaryExcel(
  List<AttendanceSummary> recordsToExport,
  ) async {
  if (recordsToExport.isEmpty) {
  Get.snackbar("No Data", "No summary data to export");
  return;
  }

  final excel = Excel.createExcel();

  // Create your sheet FIRST
  final Sheet sheet = excel['Attendance_Summary'];

// Then delete all other sheets
    for (var sheetName in List.from(excel.tables.keys)) {
      if (sheetName != 'Attendance_Summary') {
        excel.delete(sheetName);
      }
    }


  // 🟢 HEADER ROW (same as DataTable)
  sheet.appendRow([
    TextCellValue("From Date"),
    TextCellValue("To Date"),
    TextCellValue("UID"),
    TextCellValue("Userid"),
    TextCellValue("City Name"),
    TextCellValue("Name"),
    TextCellValue("Executive"),
    TextCellValue("Office Name"),
    TextCellValue("Total Days"),
    TextCellValue("Total Present"),
    TextCellValue("Total Absent"),
    TextCellValue("Total WO"),
    TextCellValue("Total Late"),
    TextCellValue("Total HalfDay"),
    TextCellValue("Missed Punch"),
    TextCellValue("Total GPS Off"),
    TextCellValue("Total Internet Off"),
    TextCellValue("Total Outside Kiosk"),

    TextCellValue("Total Break Time \n (HH:MM:SS)"),
    TextCellValue("Total Working Time \n (HH:MM:SS)"),

  ]);

  // 🔵 DATA ROWS
  for (final r in records) {
    sheet.appendRow([
      TextCellValue(r.fromDate),
      TextCellValue(r.toDate),
      TextCellValue(r.uid.toString()),
      TextCellValue(r.userid),
      TextCellValue(r.city_name),
      TextCellValue(r.name),
      TextCellValue(r.department), // Executive
      TextCellValue(r.officeName),
      TextCellValue(r.totalDays.toString()),
      TextCellValue(r.totalPresent.toString()),
      TextCellValue(r.totalAbsent.toString()),
      TextCellValue(r.totalHoliday.toString()),
      TextCellValue(r.totalLate.toString()),
      TextCellValue(r.totalHalfDay.toString()),
      TextCellValue(r.missedPunchOut.toString()),
      TextCellValue(r.totalGps.toString()),
      TextCellValue(r.totalInternet.toString()),
      TextCellValue(r.totalOutside.toString()),
      TextCellValue(r.total_break_minutes.toString()),
      TextCellValue(r.totalTimeFormate.toString()),

    ]);
  }

  final fileBytes = excel.encode();
  if (fileBytes == null) return;

  final fileName =
  "Attendance_Summary_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx";

  if (kIsWeb) {
  // 🌐 WEB DOWNLOAD
  final content = base64Encode(fileBytes);
  final anchor =
  html.AnchorElement(
  href:
  "data:application/octet-stream;charset=utf-16le;base64,$content",
  )
  ..setAttribute("download", fileName)
  ..click();
  Get.snackbar("Success", "Downloading Excel file...");
  } else {
  // 📱 MOBILE DOWNLOAD (Android/iOS)

  final directory = await getApplicationDocumentsDirectory();
  final filePath =
  "${directory.path}/attendance_summary_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx";


  final file = File(filePath)
  ..createSync(recursive: true)
  ..writeAsBytesSync(fileBytes);

  await Share.shareXFiles([
  XFile(filePath),
  ], text: "Attendance Summary Report");
  }
  }

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }
  Set<String> selectedOffices = {};
  Set<String> selectedUserTypes = {};

  List<AttendanceSummary> allRecords = [];
  List<String> officeList = [];
  List<String> userTypeList = [];
  void applyFilter() {
    setState(() {
      records = allRecords.where((element) {
        final officeMatch = selectedOffices.isEmpty ||
            selectedOffices.contains(element.officeName);

        final userTypeMatch = selectedUserTypes.isEmpty ||
            selectedUserTypes.contains(element.department);

        return officeMatch && userTypeMatch;
      }).toList();
    });
  }
  void showMultiSelectFilter({
    required List<String> items,
    required Set<String> selectedValues,
    required Function(Set<String>) onApply,
  }) {
    final tempSelected = Set<String>.from(selectedValues);

    showDialog(
      context: context,
      builder: (context) {
        String searchText = "";

        return StatefulBuilder(
          builder: (context, setDialogState) {
            // 🔍 Search ke according items filter
            final filteredItems = items.where((item) {
              return item.toLowerCase().contains(
                searchText.toLowerCase(),
              );
            }).toList();

            return AlertDialog(
              title: const Text("Select Options"),

              content: SizedBox(
                width: 300,
                height: 450,
                child: Column(
                  children: [
                    // 🔍 Search Box
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search options...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchText.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setDialogState(() {
                              searchText = "";
                            });
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchText = value;
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    // ☑ Select All
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "Select All",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      value: tempSelected.length == items.length &&
                          items.isNotEmpty,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            tempSelected.addAll(items);
                          } else {
                            tempSelected.clear();
                          }
                        });
                      },
                    ),

                    const Divider(),

                    // 📋 Filtered Items
                    Expanded(
                      child: filteredItems.isEmpty
                          ? const Center(
                        child: Text(
                          "No options found",
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      )
                          : ListView(
                        children: filteredItems.map((item) {
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item),
                            value: tempSelected.contains(item),
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  tempSelected.add(item);
                                } else {
                                  tempSelected.remove(item);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Buttons
              actions: [
                TextButton(
                  onPressed: () {
                    tempSelected.clear();

                    onApply(
                      Set<String>.from(tempSelected),
                    );

                    Navigator.pop(context);
                  },
                  child: const Text("Clear"),
                ),

                ElevatedButton(
                  onPressed: () {
                    onApply(
                      Set<String>.from(tempSelected),
                    );

                    Navigator.pop(context);
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }
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
        title: const Text("Attendance Summary",style: TextStyle(color: Colors.white,fontSize: 18),),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: pickRange,
          ),
          IconButton(onPressed: (){downloadSummaryExcel(records);}, icon: Icon(Icons.download))
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : records.isEmpty
          ? const Center(child: Text("No Data Found"))
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: Scrollbar(
              controller: _verticalController,
              thumbVisibility: true,
              trackVisibility: true,
              child: SingleChildScrollView(
                controller: _verticalController,
                scrollDirection: Axis.vertical,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width,
                  ),
                  child: DataTable(
                    border: TableBorder.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                    headingRowColor:
                    MaterialStateProperty.all(
                        Colors.blue.shade50),
                    headingRowHeight: 48,
                    dataRowHeight: 46,
                    columns:  [
                      DataColumn(label: Text("From Date")),
                      DataColumn(label: Text("To Date")),
                      DataColumn(label: Text("UID")),
                      DataColumn(label: Text("UserId")),
                      DataColumn(label: Text("City Name")),
                      DataColumn(label: Text("Name")),
                      DataColumn(
                        label: Row(
                          children: [
                            Text("User Type"),
                            IconButton(
                              icon: Icon(
                                Icons.filter_list,
                                size: 18,
                                color: selectedOffices.isNotEmpty
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                              onPressed: () {
                                showMultiSelectFilter(
                                  items: userTypeList,
                                  selectedValues: selectedOffices,
                                  onApply: (values) {
                                    selectedOffices = values;
                                    applyFilter();
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Row(
                          children: [
                            Text("Office Name"),
                            IconButton(
                              icon: Icon(
                                Icons.filter_list,
                                size: 18,
                                color: selectedOffices.isNotEmpty
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                              onPressed: () {
                                showMultiSelectFilter(
                                  items: officeList,
                                  selectedValues: selectedOffices,
                                  onApply: (values) {
                                    selectedOffices = values;
                                    applyFilter();
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      DataColumn(label: Text("Total Days")),
                      DataColumn(label: Text("Total Present")),
                      DataColumn(label: Text("Total Absent")),
                      DataColumn(label: Text("Total WO")),
                      DataColumn(label: Text("Total Late Marks")),
                      DataColumn(label: Text("Total HalfDay Marks")),
                      DataColumn(label: Text("Missed Punch")),
                      DataColumn(label: Text("Total GPS Off")),
                      DataColumn(label: Text("Total Internet Off")),
                      DataColumn(label: Text("Total Outside Kiosk")),
                      DataColumn(label: Text("Total Break Time \n  (HH:MM:SS)")),
                      DataColumn(label: Text("Total Working Time \n  (HH:MM:SS)")),
                      //DataColumn(label: Text("Total Hours")),

                    ],
                    rows: records.map((r) {
                      return DataRow(
                        cells: [
                          DataCell(Text(formatDate(r.fromDate))),
                          DataCell(Text(formatDate(r.toDate))),
                          DataCell(Text(r.uid.toString())),
                          DataCell(Text(r.userid.toString())),
                          DataCell(Text(r.city_name.toString())),
                          DataCell(Text(r.name)),
                          DataCell(Text(r.department)),
                          DataCell(Text(r.officeName)),
                          DataCell(Text(r.totalDays.toString())),
                          DataCell(Text(r.totalPresent.toString())),
                          DataCell(Text(r.totalAbsent.toString())),
                          DataCell(Text(r.totalHoliday.toString())),
                          DataCell(Text(r.totalLate.toString())),
                          DataCell(Text(r.totalHalfDay.toString())),
                          DataCell(Text(r.missedPunchOut.toString())),
                          DataCell(Text(r.totalGps.toString())),
                          DataCell(Text(r.totalInternet.toString())),
                          DataCell(Text(r.totalOutside.toString())),
                          DataCell(Text(r.total_break_minutes.toString())),
                          DataCell(Text(r.totalTimeFormate.toString())),
                          //DataCell(Text(r.totalHour.toString())),

                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

    );
  }
}
