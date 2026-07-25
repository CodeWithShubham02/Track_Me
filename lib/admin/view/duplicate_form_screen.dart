import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

import '../../user/model/client_form_report_model.dart';
import '../controller/form_reports_controller.dart';

class DuplicateFormScreen extends StatefulWidget {
  final String cid;
  const DuplicateFormScreen({super.key,required this.cid});

  @override
  State<DuplicateFormScreen> createState() => _DuplicateFormScreenState();
}

class _DuplicateFormScreenState extends State<DuplicateFormScreen> {

  late Future<List<ClientFormReportModel>> reportsFuture;

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    reportsFuture = ReportController.fetchReportDuplicate(widget.cid);
  }
  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: EdgeInsets.zero, // 🔥 full screen
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              // 🔍 Zoomable image
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
                ),
              ),

              // ❌ Close button
              Positioned(
                top: 30,
                right: 20,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> _confirmAndUpdateDuplicate(ClientFormReportModel report) async {
    bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Mark as active form?"),
            content: const Text(
              "Are you sure you want to mark this form active?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Yes"),
              ),
            ],
          ),
        ) ??
            false;

    if (!confirmed) return;

    // Loader message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Updating...")),
    );

    bool success = await ReportController.updateDuplicate(
      id: report.id,
      duplicateFrom: "no", // ✅ correct value
    );

    if (success) {
      setState(() {
        reportsFuture = ReportController.fetchReportDuplicate(widget.cid); // 🔥 refresh
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Form updated successfully")),
      );
    }
  }

  DateTime? selectedDate;
  Future<void> _pickDateAndFetchReports() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

    if (pickedRange != null) {
      String fromDate =
          "${pickedRange.start.year}-${pickedRange.start.month.toString().padLeft(2, '0')}-${pickedRange.start.day.toString().padLeft(2, '0')}";

      String toDate =
          "${pickedRange.end.year}-${pickedRange.end.month.toString().padLeft(2, '0')}-${pickedRange.end.day.toString().padLeft(2, '0')}";

      setState(() {
        reportsFuture =
            ReportController.fetchReports1(fromDate: fromDate, toDate: toDate);
      });
    }
  }
  Future<void> exportReportsToExcel(
      BuildContext context, List<ClientFormReportModel> reports) async {
    final Excel excel = Excel.createExcel();
    final Sheet sheet = excel['Reports'];

    // 🟢 HEADER ROW
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

    // 🔵 DATA ROWS
    for (var row in reports) {
      final imageUrls = row.imageUrls.isNotEmpty ? row.imageUrls.join(", ") : "";
      sheet.appendRow([
        TextCellValue(row.uid.toString()),
        TextCellValue(row.userId),
        TextCellValue(row.userName),
        TextCellValue(row.cityName),
        TextCellValue(row.reportDate),
        TextCellValue(row.reportTime),
        TextCellValue(row.applicationNo),
        TextCellValue(row.relation),
        TextCellValue(row.variant),
        TextCellValue(row.status),
        TextCellValue(row.remarks),
        TextCellValue(imageUrls),
        TextCellValue(row.contactNo),
        TextCellValue(row.gpsLocation),
        TextCellValue(row.kioskName),
        TextCellValue(row.createdAt),
      ]);
    }

    final List<int>? bytes = excel.encode();
    if (bytes == null) return;

    if (kIsWeb) {
      // Web download
      final blob = html.Blob([Uint8List.fromList(bytes)]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "client_form_reports.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Android/iOS: Save to Documents folder
      final directory = await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/client_form_reports.xlsx";
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Excel saved to $filePath")),
      );
    }
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
        title: const Text("Inactive Forms ",style: TextStyle(color: Colors.white,fontSize: 18),),
        actions: [
          IconButton(
            onPressed: () async {
              final reports = await reportsFuture;
              if (reports.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No reports to download")),
                );
                return;
              }
              await exportReportsToExcel(context, reports);
            },
            icon: const Icon(Icons.download, color: Colors.white),
          ),
          SizedBox(width: 20,),
          // IconButton(
          //   onPressed: _pickDateAndFetchReports,
          //   icon: Icon(Icons.calendar_month, color: Colors.white),
          // ),
        ],
      ),
      body: FutureBuilder<List<ClientFormReportModel>>(
        future: reportsFuture,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No reports found"));
          }

          final reports = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(10),
            child: Card(
              elevation: 4,
              child: Scrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _verticalController,
                  child: Scrollbar(
                    controller: _horizontalController,
                    thumbVisibility: true,
                    notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16,
                        headingRowHeight: 48,
                        dataRowHeight: 70,
                        headingRowColor: MaterialStateProperty.all(
                          Colors.grey.shade200,
                        ),
                        columns: const [
                          DataColumn(label: Text("Action")),
                          DataColumn(label: Text("UID")),
                          DataColumn(label: Text("User ID")),
                          DataColumn(label: Text("User Name")),
                          DataColumn(label: Text("City Name")),
                          DataColumn(label: Text("Report Date")),
                          DataColumn(label: Text("Report Time")),
                          DataColumn(label: Text("Application No")),
                          DataColumn(label: Text("Relation")),
                          DataColumn(label: Text("Variant")),
                          DataColumn(label: Text("Status")),
                          DataColumn(label: Text("Remarks")),
                          DataColumn(label: Text("Contact No")),
                          DataColumn(label: Text("Images")),
                          DataColumn(label: Text("GPS Location")),
                          DataColumn(label: Text("Kiosk Name")),
                          DataColumn(label: Text("Created At")),
                        ],
                        rows: reports.map<DataRow>((report) {
                          return DataRow(
                            cells: [

                              // Action
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.settings,color: Color(0xff2563EB),),
                                  onPressed: () {
                                    debugPrint(report.uid.toString());
                                    _confirmAndUpdateDuplicate(report);
                                  },
                                ),
                              ),

                              DataCell(Text(report.uid.toString())),
                              DataCell(Text(report.userId)),
                              DataCell(Text(report.userName)),
                              DataCell(Text(report.cityName)),
                              DataCell(Text(report.reportDate)),
                              DataCell(Text(report.reportTime)),
                              DataCell(Text(report.applicationNo)),
                              DataCell(Text(report.relation)),
                              DataCell(Text(report.variant)),

                              // Status Color
                              DataCell(
                                Text(
                                  report.status,
                                  style: TextStyle(
                                    color: report.status.toLowerCase() == "approved"
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              DataCell(Text(report.remarks)),
                              DataCell(Text(report.contactNo)),

                              // 🔥 Multiple Images
                              DataCell(
                                report.imageUrls.isNotEmpty
                                    ? SizedBox(
                                  width: 150,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: report.imageUrls.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: InkWell(
                                            onTap: (){
                                              _showImageDialog(
                                                context,
                                                report.imageUrls[index],
                                              );
                                            },
                                            child: Image.network(
                                              report.imageUrls[index],
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                                    : const Icon(Icons.image_not_supported),
                              ),

                              DataCell(Text(report.gpsLocation)),
                              DataCell(Text(report.kioskName)),

                              DataCell(Text(report.createdAt)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      // floatingActionButton: FloatingActionButton(onPressed: (){
      // },child: Icon(Icons.logout_outlined),),
    );
  }
}
