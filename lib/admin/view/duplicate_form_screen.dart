import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

import '../../user/model/client_form_report_model.dart';
import '../controller/form_reports_controller.dart';

class DuplicateFormScreen extends StatefulWidget {
  final String cid;

  const DuplicateFormScreen({
    super.key,
    required this.cid,
  });

  @override
  State<DuplicateFormScreen> createState() => _DuplicateFormScreenState();
}

class _DuplicateFormScreenState extends State<DuplicateFormScreen> {
  late Future<List<ClientFormReportModel>> reportsFuture;

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  // ============================================================
  // FILTER VARIABLES
  // ============================================================

  String? selectedUserName;

  final TextEditingController applicationSearchController =
  TextEditingController();

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    reportsFuture =
        ReportController.fetchReportDuplicate(widget.cid);
  }

  // ============================================================
  // IMAGE DIALOG
  // ============================================================

  void _showImageDialog(
      BuildContext context,
      String imageUrl,
      ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              // ==================================================
              // ZOOMABLE IMAGE
              // ==================================================

              InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder:
                        (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 80,
                      );
                    },
                  ),
                ),
              ),

              // ==================================================
              // CLOSE BUTTON
              // ==================================================

              Positioned(
                top: 30,
                right: 20,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // UPDATE DUPLICATE
  // ============================================================

  Future<void> _confirmAndUpdateDuplicate(
      ClientFormReportModel report,
      ) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: const Text(
                "Mark as active form?",
              ),
              content: const Text(
                "Are you sure you want to mark this form active?",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text("No"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text("Yes"),
                ),
              ],
            );
          },
        ) ??
            false;

    if (!confirmed) return;

    // ==========================================================
    // SHOW LOADING MESSAGE
    // ==========================================================

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Updating..."),
      ),
    );

    // ==========================================================
    // API UPDATE
    // ==========================================================

    final bool success =
    await ReportController.updateDuplicate(
      id: report.id,
      duplicateFrom: "no",
    );

    // ==========================================================
    // SUCCESS
    // ==========================================================

    if (success) {
      setState(() {
        reportsFuture =
            ReportController.fetchReportDuplicate(
              widget.cid,
            );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Form has been marked active successfully.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Failed to activate the form. Please try again.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ============================================================
  // FILTER REPORTS
  // ============================================================

  List<ClientFormReportModel> _filterReports(
      List<ClientFormReportModel> reports,
      ) {
    final String searchText =
    applicationSearchController.text
        .trim()
        .toLowerCase();

    return reports.where((report) {
      // ========================================================
      // USER NAME FILTER
      // ========================================================

      final bool userNameMatch =
          selectedUserName == null ||
              selectedUserName!.isEmpty ||
              report.userName.trim().toLowerCase() ==
                  selectedUserName!.trim().toLowerCase();

      // ========================================================
      // APPLICATION NUMBER SEARCH
      // ========================================================

      final bool applicationMatch =
          searchText.isEmpty ||
              report.applicationNo
                  .toString()
                  .toLowerCase()
                  .contains(searchText);

      // ========================================================
      // BOTH CONDITIONS MUST MATCH
      // ========================================================

      return userNameMatch && applicationMatch;
    }).toList();
  }

  // ============================================================
  // DATE FILTER
  // ============================================================

  DateTime? selectedDate;

  Future<void> _pickDateAndFetchReports() async {
    final DateTimeRange? pickedRange =
    await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(
          const Duration(days: 7),
        ),
        end: DateTime.now(),
      ),
    );

    if (pickedRange != null) {
      final String fromDate =
          "${pickedRange.start.year}-"
          "${pickedRange.start.month.toString().padLeft(2, '0')}-"
          "${pickedRange.start.day.toString().padLeft(2, '0')}";

      final String toDate =
          "${pickedRange.end.year}-"
          "${pickedRange.end.month.toString().padLeft(2, '0')}-"
          "${pickedRange.end.day.toString().padLeft(2, '0')}";

      setState(() {
        reportsFuture =
            ReportController.fetchReports1(
              fromDate: fromDate,
              toDate: toDate,
            );
      });
    }
  }

  // ============================================================
  // EXPORT EXCEL
  // ============================================================

  Future<void> exportReportsToExcel(
      BuildContext context,
      List<ClientFormReportModel> reports,
      ) async {
    if (reports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "No reports to download",
          ),
        ),
      );

      return;
    }

    final Excel excel = Excel.createExcel();

    final Sheet sheet = excel['Reports'];

    // ==========================================================
    // HEADER
    // ==========================================================

    sheet.appendRow([
      TextCellValue("UID"),
      TextCellValue("User ID"),
      TextCellValue("User Name"),
      TextCellValue("City Name"),
      TextCellValue("Report Date"),
      TextCellValue("Report Time"),
      TextCellValue("Application No"),
      TextCellValue("Relation"),
      TextCellValue("Variant"),
      TextCellValue("Status"),
      TextCellValue("Remarks"),
      TextCellValue("Images"),
      TextCellValue("Contact No"),
      TextCellValue("GPS Location"),
      TextCellValue("Kiosk Name"),
      TextCellValue("Created At"),
    ]);

    // ==========================================================
    // DATA
    // ==========================================================

    for (final row in reports) {
      final String imageUrls =
      row.imageUrls.isNotEmpty
          ? row.imageUrls.join(", ")
          : "";

      sheet.appendRow([
        TextCellValue(
          row.uid.toString(),
        ),
        TextCellValue(
          row.userId,
        ),
        TextCellValue(
          row.userName,
        ),
        TextCellValue(
          row.cityName,
        ),
        TextCellValue(
          row.reportDate,
        ),
        TextCellValue(
          row.reportTime,
        ),
        TextCellValue(
          row.applicationNo,
        ),
        TextCellValue(
          row.relation,
        ),
        TextCellValue(
          row.variant,
        ),
        TextCellValue(
          row.status,
        ),
        TextCellValue(
          row.remarks,
        ),
        TextCellValue(
          imageUrls,
        ),
        TextCellValue(
          row.contactNo,
        ),
        TextCellValue(
          row.gpsLocation,
        ),
        TextCellValue(
          row.kioskName,
        ),
        TextCellValue(
          row.createdAt,
        ),
      ]);
    }

    // ==========================================================
    // ENCODE
    // ==========================================================

    final List<int>? bytes = excel.encode();

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Failed to create Excel file",
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // WEB
    // ==========================================================

    if (kIsWeb) {
      final blob = html.Blob([
        Uint8List.fromList(bytes),
      ]);

      final url =
      html.Url.createObjectUrlFromBlob(blob);

      final anchor =
      html.AnchorElement(href: url)
        ..setAttribute(
          "download",
          "inactive_forms.xlsx",
        )
        ..click();

      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Excel downloaded successfully",
          ),
        ),
      );
    }

    // ==========================================================
    // ANDROID / IOS
    // ==========================================================

    else {
      final directory =
      await getApplicationDocumentsDirectory();

      final filePath =
          "${directory.path}/inactive_forms.xlsx";

      final file = File(filePath);

      await file.writeAsBytes(
        bytes,
        flush: true,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Excel saved to $filePath",
          ),
        ),
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    applicationSearchController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ========================================================
      // APP BAR
      // ========================================================

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

        iconTheme: const IconThemeData(
          color: Colors.white,
        ),

        title: const Text(
          "Inactive Forms",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),

        actions: [
          // ====================================================
          // EXCEL DOWNLOAD
          // ====================================================

          IconButton(
            tooltip: "Download Excel",
            onPressed: () async {
              try {
                final reports =
                await reportsFuture;

                final filteredReports =
                _filterReports(reports);

                if (filteredReports.isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "No filtered reports to download",
                      ),
                    ),
                  );

                  return;
                }

                await exportReportsToExcel(
                  context,
                  filteredReports,
                );
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      "Download failed: $e",
                    ),
                  ),
                );
              }
            },
            icon: const Icon(
              Icons.download,
              color: Colors.white,
            ),
          ),

          const SizedBox(
            width: 20,
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: FutureBuilder<
          List<ClientFormReportModel>>(
        future: reportsFuture,

        builder: (context, snapshot) {
          // ====================================================
          // LOADING
          // ====================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ====================================================
          // ERROR
          // ====================================================

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
              ),
            );
          }

          // ====================================================
          // NO DATA
          // ====================================================

          if (!snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No reports found",
              ),
            );
          }

          // ====================================================
          // ALL REPORTS
          // ====================================================

          final List<ClientFormReportModel> reports =
          snapshot.data!;

          // ====================================================
          // FILTERED REPORTS
          // ====================================================

          final List<ClientFormReportModel>
          filteredReports =
          _filterReports(reports);

          // ====================================================
          // USER NAMES
          // ====================================================

          final List<String> userNames =
          reports
              .map(
                (e) => e.userName.trim(),
          )
              .where(
                (name) => name.isNotEmpty,
          )
              .toSet()
              .toList()
            ..sort();

          // ====================================================
          // UI
          // ====================================================

          return Padding(
            padding: const EdgeInsets.all(10),

            child: Card(
              elevation: 4,

              child: Padding(
                padding: const EdgeInsets.all(10),

                child: Column(
                  children: [
                    // ==========================================
                    // FILTER ROW
                    // ==========================================

                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        // ======================================
                        // USER NAME DROPDOWN
                        // ======================================

                        Expanded(
                          child:
                          DropdownButtonFormField<
                              String>(
                            value: selectedUserName,

                            isExpanded: true,

                            decoration:
                            InputDecoration(
                              labelText:
                              "Filter by User Name",

                              prefixIcon:
                              const Icon(
                                Icons.person_outline,
                              ),

                              border:
                              OutlineInputBorder(
                                borderRadius:
                                BorderRadius
                                    .circular(8),
                              ),

                              contentPadding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),

                            items: [
                              // =================================
                              // ALL USERS
                              // =================================

                              const DropdownMenuItem<
                                  String>(
                                value: null,
                                child:
                                Text("All Users"),
                              ),

                              // =================================
                              // USER NAMES
                              // =================================

                              ...userNames.map(
                                    (
                                    name,
                                    ) {
                                  return DropdownMenuItem<
                                      String>(
                                    value: name,

                                    child: Text(
                                      name,

                                      overflow:
                                      TextOverflow
                                          .ellipsis,
                                    ),
                                  );
                                },
                              ),
                            ],

                            onChanged: (
                                String? value,
                                ) {
                              setState(() {
                                selectedUserName =
                                    value;
                              });
                            },
                          ),
                        ),

                        const SizedBox(
                          width: 15,
                        ),

                        // ======================================
                        // APPLICATION NUMBER SEARCH
                        // ======================================

                        Expanded(
                          child: TextField(
                            controller:
                            applicationSearchController,

                            decoration:
                            InputDecoration(
                              labelText:
                              "Search Application Number",

                              hintText:
                              "Enter application number",

                              prefixIcon:
                              const Icon(
                                Icons.search,
                              ),

                              suffixIcon:
                              applicationSearchController
                                  .text
                                  .isNotEmpty
                                  ? IconButton(
                                tooltip:
                                "Clear search",

                                icon:
                                const Icon(
                                  Icons.clear,
                                ),

                                onPressed: () {
                                  applicationSearchController
                                      .clear();

                                  setState(
                                        () {},
                                  );
                                },
                              )
                                  : null,

                              border:
                              OutlineInputBorder(
                                borderRadius:
                                BorderRadius
                                    .circular(8),
                              ),

                              contentPadding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),

                            onChanged: (
                                String value,
                                ) {
                              setState(() {});
                            },
                          ),
                        ),

                        const SizedBox(
                          width: 15,
                        ),

                        // ======================================
                        // CLEAR FILTER BUTTON
                        // ======================================

                        SizedBox(
                          height: 55,

                          child:
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                selectedUserName =
                                null;

                                applicationSearchController
                                    .clear();
                              });
                            },

                            icon: const Icon(
                              Icons.clear,
                            ),

                            label: const Text(
                              "Clear",
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==========================================
                    // RESULT COUNT
                    // ==========================================

                    Align(
                      alignment:
                      Alignment.centerLeft,

                      child: Text(
                        "Showing ${filteredReports.length} "
                            "of ${reports.length} reports",

                        style: const TextStyle(
                          fontWeight:
                          FontWeight.w600,

                          color: Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // ==========================================
                    // TABLE
                    // ==========================================

                    Expanded(
                      child: Scrollbar(
                        controller:
                        _verticalController,

                        thumbVisibility: true,

                        child:
                        SingleChildScrollView(
                          controller:
                          _verticalController,

                          child: Scrollbar(
                            controller:
                            _horizontalController,

                            thumbVisibility: true,

                            notificationPredicate:
                                (notification) {
                              return notification
                                  .metrics
                                  .axis ==
                                  Axis.horizontal;
                            },

                            child:
                            SingleChildScrollView(
                              controller:
                              _horizontalController,

                              scrollDirection:
                              Axis.horizontal,

                              child: DataTable(
                                columnSpacing: 16,

                                headingRowHeight:
                                48,

                                dataRowHeight:
                                70,

                                headingRowColor:
                                MaterialStateProperty
                                    .all(
                                  Colors.grey.shade200,
                                ),

                                // =================================
                                // COLUMNS
                                // =================================

                                columns: const [
                                  DataColumn(
                                    label:
                                    Text("Action"),
                                  ),

                                  DataColumn(
                                    label:
                                    Text("UID"),
                                  ),

                                  DataColumn(
                                    label:
                                    Text("User ID"),
                                  ),

                                  DataColumn(
                                    label:
                                    Text("User Name"),
                                  ),

                                  DataColumn(
                                    label:
                                    Text("City Name"),
                                  ),

                                  DataColumn(
                                    label:
                                    Text("Report Date"),
                                  ),

                                  DataColumn(
                                    label:
                                    Text("Report Time"),
                                  ),

                                  DataColumn(
                                    label:
                                    Text("Application No"),
                                  ),

                                  DataColumn(
                                    label:
                                    Text("Relation"),
                                  ),

                                  DataColumn(
                                    label:
                                    Text("Variant"),
                                  ),

                                  DataColumn(
                                    label:
                                    Text("Status"),
                                  ),

                                  DataColumn(
                                    label:
                                    Text("Remarks"),
                                  ),

                                  DataColumn(
                                    label:
                                    Text("Contact No"),
                                  ),

                                  DataColumn(
                                    label:
                                    Text("Images"),
                                  ),

                                  DataColumn(
                                    label:
                                    Text("GPS Location"),
                                  ),

                                  DataColumn(
                                    label:
                                    Text("Kiosk Name"),
                                  ),

                                  DataColumn(
                                    label:
                                    Text("Created At"),
                                  ),
                                ],

                                // =================================
                                // ROWS
                                // =================================

                                rows:
                                filteredReports
                                    .map<DataRow>(
                                      (
                                      report,
                                      ) {
                                    return DataRow(
                                      cells: [
                                        // =================================
                                        // ACTION
                                        // =================================

                                        DataCell(
                                          IconButton(
                                            tooltip:
                                            "Mark as active",

                                            icon:
                                            const Icon(
                                              Icons.settings,
                                              color:
                                              Color(
                                                0xff2563EB,
                                              ),
                                            ),

                                            onPressed: () {
                                              debugPrint(
                                                "UID: "
                                                    "${report.uid}",
                                              );

                                              _confirmAndUpdateDuplicate(
                                                report,
                                              );
                                            },
                                          ),
                                        ),

                                        // =================================
                                        // UID
                                        // =================================

                                        DataCell(
                                          Text(
                                            report.uid
                                                .toString(),
                                          ),
                                        ),

                                        // =================================
                                        // USER ID
                                        // =================================

                                        DataCell(
                                          Text(
                                            report.userId,
                                          ),
                                        ),

                                        // =================================
                                        // USER NAME
                                        // =================================

                                        DataCell(
                                          Text(
                                            report.userName,
                                          ),
                                        ),

                                        // =================================
                                        // CITY
                                        // =================================

                                        DataCell(
                                          Text(
                                            report.cityName,
                                          ),
                                        ),

                                        // =================================
                                        // REPORT DATE
                                        // =================================

                                        DataCell(
                                          Text(
                                            report.reportDate,
                                          ),
                                        ),

                                        // =================================
                                        // REPORT TIME
                                        // =================================

                                        DataCell(
                                          Text(
                                            report.reportTime,
                                          ),
                                        ),

                                        // =================================
                                        // APPLICATION NUMBER
                                        // =================================

                                        DataCell(
                                          Text(
                                            report.applicationNo,
                                          ),
                                        ),

                                        // =================================
                                        // RELATION
                                        // =================================

                                        DataCell(
                                          Text(
                                            report.relation,
                                          ),
                                        ),

                                        // =================================
                                        // VARIANT
                                        // =================================

                                        DataCell(
                                          Text(
                                            report.variant,
                                          ),
                                        ),

                                        // =================================
                                        // STATUS
                                        // =================================

                                        DataCell(
                                          Text(
                                            report.status,

                                            style:
                                            TextStyle(
                                              color: report
                                                  .status
                                                  .toLowerCase() ==
                                                  "approved"
                                                  ? Colors
                                                  .green
                                                  : Colors
                                                  .red,

                                              fontWeight:
                                              FontWeight
                                                  .bold,
                                            ),
                                          ),
                                        ),

                                        // =================================
                                        // REMARKS
                                        // =================================

                                        DataCell(
                                          SizedBox(
                                            width: 180,

                                            child: Text(
                                              report
                                                  .remarks,

                                              maxLines: 2,

                                              overflow:
                                              TextOverflow
                                                  .ellipsis,
                                            ),
                                          ),
                                        ),

                                        // =================================
                                        // CONTACT
                                        // =================================

                                        DataCell(
                                          Text(
                                            report
                                                .contactNo,
                                          ),
                                        ),

                                        // =================================
                                        // IMAGES
                                        // =================================

                                        DataCell(
                                          report.imageUrls
                                              .isNotEmpty
                                              ? SizedBox(
                                            width: 150,

                                            child:
                                            ListView
                                                .builder(
                                              scrollDirection:
                                              Axis.horizontal,

                                              itemCount:
                                              report
                                                  .imageUrls
                                                  .length,

                                              itemBuilder:
                                                  (
                                                  context,
                                                  index,
                                                  ) {
                                                return Padding(
                                                  padding:
                                                  const EdgeInsets.only(
                                                    right:
                                                    6,
                                                  ),

                                                  child:
                                                  ClipRRect(
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                      6,
                                                    ),

                                                    child:
                                                    InkWell(
                                                      onTap:
                                                          () {
                                                        _showImageDialog(
                                                          context,
                                                          report.imageUrls[
                                                          index],
                                                        );
                                                      },

                                                      child:
                                                      Image.network(
                                                        report.imageUrls[
                                                        index],

                                                        width:
                                                        50,

                                                        height:
                                                        50,

                                                        fit:
                                                        BoxFit.cover,

                                                        errorBuilder:
                                                            (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                            ) {
                                                          return Container(
                                                            width:
                                                            50,
                                                            height:
                                                            50,
                                                            color:
                                                            Colors.grey.shade200,
                                                            child:
                                                            const Icon(
                                                              Icons.broken_image,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                              : const Icon(
                                            Icons
                                                .image_not_supported,
                                          ),
                                        ),

                                        // =================================
                                        // GPS
                                        // =================================

                                        DataCell(
                                          Text(
                                            report
                                                .gpsLocation,
                                          ),
                                        ),

                                        // =================================
                                        // KIOSK
                                        // =================================

                                        DataCell(
                                          Text(
                                            report
                                                .kioskName,
                                          ),
                                        ),

                                        // =================================
                                        // CREATED AT
                                        // =================================

                                        DataCell(
                                          Text(
                                            report
                                                .createdAt,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}