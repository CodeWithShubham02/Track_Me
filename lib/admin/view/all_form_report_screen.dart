import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:joizone/admin/view/bulk_upload_form_screen.dart';
import 'package:joizone/admin/view/upload_remark_screen.dart';
import 'package:joizone/user/model/client_form_report_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import '../controller/form_reports_controller.dart';
import 'custom_date_range_picker.dart';
import 'duplicate_form_screen.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';



class AllFormReportScreen extends StatefulWidget {
  final String cid;
  const AllFormReportScreen({super.key, required this.cid});

  @override
  State<AllFormReportScreen> createState() => _AllFormReportScreenState();
}

class _AllFormReportScreenState extends State<AllFormReportScreen> {


  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  DateTime? selectedFromDate;
  DateTime? selectedToDate;

  late Future<List<ClientFormReportModel>> reportsFuture;
  @override
  void initState() {
    super.initState();
    // Initial
    reportsFuture = ReportController.fetchReports(widget.cid);

  }
  int rowsPerPage = 10;
  int currentPage = 0;
  void _showImagesDialog(
      BuildContext context,
      List<String> imageUrls,
      ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: 700,
            height: 600,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Images (${imageUrls.length})",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const Divider(),

                // Images
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          _showFullImage(
                            context,
                            imageUrls[index],
                          );
                        },
                        child: ClipRRect(
                          borderRadius:
                          BorderRadius.circular(10),
                          child: Image.network(
                            imageUrls[index],
                            fit: BoxFit.cover,
                            loadingBuilder:
                                (context, child, progress) {
                              if (progress == null) {
                                return child;
                              }

                              return const Center(
                                child:
                                CircularProgressIndicator(),
                              );
                            },
                            errorBuilder:
                                (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  void _showFullImage(
      BuildContext context,
      String imageUrl,
      ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: 700,
                  errorBuilder:
                      (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 60,
                      ),
                    );
                  },
                ),
              ),

              Positioned(
                top: 5,
                right: 5,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Future<void> _confirmAndUpdateDuplicate(
      ClientFormReportModel report) async {

    // ==========================================================
    // CONFIRMATION DIALOG
    // ==========================================================

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),

              title: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF59E0B),
                    size: 26,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Form as Inactive?",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              content: const Text(
                "Are you sure you want to mark this form as inactive?",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                ),
              ),

              actionsPadding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                14,
              ),

              actions: [

                // NO
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child: const Text(
                    "No",
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // YES
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    "Yes, Inactive",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
            false;

    // User clicked No
    if (!confirmed) return;

    // ==========================================================
    // SHOW LOADING
    // ==========================================================

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                AlwaysStoppedAnimation<Color>(
                  Colors.white,
                ),
              ),
            ),

            SizedBox(width: 12),

            Expanded(
              child: Text(
                "Updating form...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        backgroundColor:
        const Color(0xFF2563EB),

        behavior:
        SnackBarBehavior.floating,

        margin:
        const EdgeInsets.all(16),

        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(10),
        ),

        duration:
        const Duration(seconds: 2),
      ),
    );

    // ==========================================================
    // UPDATE API
    // ==========================================================

    final bool success =
    await ReportController.updateDuplicate(
      id: report.id,
      duplicateFrom: "yes",
    );

    // ==========================================================
    // SUCCESS
    // ==========================================================

    if (success) {

      // Remove old loading snackbar
      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      // Refresh SAME selected date/date range
      refreshReports();

      // Success message
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
                  "Form has been marked inactive successfully.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          backgroundColor:
          const Color(0xFF16A34A),

          behavior:
          SnackBarBehavior.floating,

          margin:
          const EdgeInsets.all(16),

          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(10),
          ),

          duration:
          const Duration(seconds: 3),
        ),
      );

    }

    // ==========================================================
    // FAILED
    // ==========================================================

    else {

      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

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
                  "Failed to deactivate the form. Please try again.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          backgroundColor:
          const Color(0xFFDC2626),

          behavior:
          SnackBarBehavior.floating,

          margin:
          const EdgeInsets.all(16),

          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(10),
          ),

          duration:
          const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _pickDateAndFetchReports() async {
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) {
        return CustomDateRangePicker(
          initialRange:
          selectedFromDate != null &&
              selectedToDate != null
              ? DateTimeRange(
            start: selectedFromDate!,
            end: selectedToDate!,
          )
              : null,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
      },
    );

    if (picked == null) return;

    setState(() {
      selectedFromDate = picked.start;
      selectedToDate = picked.end;

      currentPage = 0;

      reportsFuture = ReportController.fetchReports1(
        fromDate: DateFormat('yyyy-MM-dd')
            .format(picked.start),
        toDate: DateFormat('yyyy-MM-dd')
            .format(picked.end),
        cid: widget.cid,
      );
    });
  }

  Future<String> getAddressFromLatLng(String gps) async {
    try {
      if (gps.isEmpty) return "Location not available";

      final parts = gps.split(',');

      if (parts.length < 2) return gps;

      double lat = double.parse(parts[0].trim());
      double lng = double.parse(parts[1].trim());

      final placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isEmpty) return "Address not found";

      final p = placemarks.first;

      String address = [
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
        p.country,
      ].where((e) => e != null && e!.isNotEmpty).join(", ");

      return address.isEmpty ? "Address not found" : address;
    } catch (e) {
      print("Geocode error: $e");
      return "Address not available";
    }
  }

  Future<void> exportReportsToExcel(
    BuildContext context,
    List<ClientFormReportModel> reports,
  ) async {
    final Excel excel = Excel.createExcel();
// Create your sheet FIRST
    final Sheet sheet = excel['Reports'];

// Then delete all other sheets
    for (var sheetName in List.from(excel.tables.keys)) {
      if (sheetName != 'Reports') {
        excel.delete(sheetName);
      }
    }
    // 🟢 HEADER ROW
    sheet.appendRow([
      TextCellValue("Report Id"),
      TextCellValue("User ID"),
      TextCellValue("User Name"),
      TextCellValue("City Name"),
      TextCellValue("Report Date"),
      TextCellValue("Report Time"),
      TextCellValue("Application Number"),
      TextCellValue("Relation"),
      TextCellValue("Variant"),
      TextCellValue("Status"),
      TextCellValue("Remarks"),
      TextCellValue("Manager Remarks"),
      TextCellValue("Snapshot"),
      TextCellValue("Contact No"),
      TextCellValue("Address"),
      TextCellValue("Kiosk Name"),
      TextCellValue("Site Name"),
      TextCellValue("Bank Remark"),
      TextCellValue("RemarksDate"),
    ]);

    // 🔵 DATA ROWS
    for (var row in reports) {
      final imageUrls = row.imageUrls.isNotEmpty
          ? row.imageUrls.join(", ")
          : "";
      String address = await getAddressCached(row.gpsLocation);
      sheet.appendRow([
        TextCellValue(row.id.toString()),
        TextCellValue(row.userId),
        TextCellValue(row.userName),
        TextCellValue(row.siteName),
        TextCellValue(
          DateFormat('dd-MM-yyyy').format(
            DateTime.parse(row.reportDate),
          ),
        ),//i want this formate dd-mm-yyyy
        TextCellValue(formatTime1(row.reportTime ?? "")),
        TextCellValue(row.applicationNo),
        TextCellValue(row.relation),
        TextCellValue(row.variant),
        TextCellValue(row.status.toUpperCase()),
        TextCellValue(row.remarks),
        TextCellValue(row.managerRemarks),
        TextCellValue(imageUrls),
        TextCellValue(row.contactNo),
        TextCellValue(address),
        TextCellValue(row.kioskName),
        TextCellValue(row.attendanceSiteName),
        TextCellValue(" "),
        TextCellValue(" "),
        // TextCellValue(
        //   DateFormat('yyyy-MM-dd').format(DateTime.parse(row.createdAt)),
        // ),
      ]);
    }

    final List<int>? bytes = excel.encode();
    if (bytes == null) return;
    final now = DateTime.now();
    final date =
        "${now.day.toString().padLeft(2, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.year}";

    final fileName = "Export_Template_Joizone_$date.xlsx";
    if (kIsWeb) {
      // Web download
      final blob = html.Blob([Uint8List.fromList(bytes)]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);

      Get.snackbar(
        "Success",
        "Export Template download successfully: $fileName",
        snackPosition: SnackPosition.TOP,

        backgroundColor: const Color(0xFF16A34A),
        colorText: Colors.white,

        icon: const Icon(
          Icons.check_circle_outline,
          color: Colors.white,
          size: 22,
        ),

        margin: const EdgeInsets.all(16),
        borderRadius: 10,

        duration: const Duration(seconds: 5),

        // Optional
        snackStyle: SnackStyle.FLOATING,
        isDismissible: true,
      );
    } else {
      // Android/iOS: Save to Documents folder
      final directory = await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/$fileName";
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Excel saved to $filePath")));
    }
  }

  Future<void> exportReportsToApprovedExcel(
      BuildContext context,
      List<ClientFormReportModel> reports,
      ) async {
    final Excel excel = Excel.createExcel();

    // Create Reports sheet
    final Sheet sheet = excel['Reports'];

    // Delete all other sheets
    for (var sheetName in List.from(excel.tables.keys)) {
      if (sheetName != 'Reports') {
        excel.delete(sheetName);
      }
    }

    // HEADER ROW
    sheet.appendRow([
      TextCellValue("Report Id"),
      TextCellValue("User ID"),
      TextCellValue("User Name"),
      TextCellValue("City Name"),
      TextCellValue("Report Date"),
      TextCellValue("Report Time"),
      TextCellValue("Application Number"),
      TextCellValue("Relation"),
      TextCellValue("Variant"),
      TextCellValue("Status"),
      TextCellValue("Remarks"),
      TextCellValue("Manager Remarks"),
      TextCellValue("Snapshot"),
      TextCellValue("Contact No"),
      TextCellValue("Address"),
      TextCellValue("Kiosk Name"),
      TextCellValue("Bank Remark"),
      TextCellValue("Update Status"),
      TextCellValue("RemarksDate"),
    ]);

    // DATA ROWS
    for (var row in reports) {
      final imageUrls = row.imageUrls.isNotEmpty
          ? row.imageUrls.join(", ")
          : "";

      final String address =
      await getAddressCached(row.gpsLocation);

      sheet.appendRow([
        TextCellValue(row.id.toString()),
        TextCellValue(row.userId),
        TextCellValue(row.userName),
        TextCellValue(row.siteName),

        TextCellValue(
          DateFormat('dd-MM-yyyy').format(
            DateTime.parse(row.reportDate),
          ),
        ),

        TextCellValue(
          formatTime1(row.reportTime ?? ""),
        ),

        TextCellValue(row.applicationNo),
        TextCellValue(row.relation),
        TextCellValue(row.variant),
        TextCellValue(row.status.toUpperCase()),
        TextCellValue(row.remarks),
        TextCellValue(row.managerRemarks),
        TextCellValue(imageUrls),
        TextCellValue(row.contactNo),
        TextCellValue(address),
        TextCellValue(row.kioskName),

        // Bank Remark
        TextCellValue(row.bankRemarks),

        // Update Status
        TextCellValue(row.updateStatus),

        TextCellValue(
          DateFormat('yyyy-MM-dd').format(
            DateTime.parse(row.createdAt),
          ),
        ),
      ]);
    }

    final List<int>? bytes = excel.encode();

    if (bytes == null) {
      Get.snackbar(
        "Error",
        "Excel file not create..",
        snackPosition: SnackPosition.TOP,

        backgroundColor: const Color(0xFF16A34A),
        colorText: Colors.white,

        icon: const Icon(
          Icons.check_circle_outline,
          color: Colors.white,
          size: 22,
        ),

        margin: const EdgeInsets.all(16),
        borderRadius: 10,

        duration: const Duration(seconds: 5),

        // Optional
        snackStyle: SnackStyle.FLOATING,
        isDismissible: true,
      );
      return;
    }

    if (kIsWeb) {
      // WEB
      final blob = html.Blob([
        Uint8List.fromList(bytes),
      ]);

      final url =
      html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(
        href: url,
      )
        ..setAttribute(
          "download",
          "Post_Upload_File.xlsx",
        )
        ..click();

      html.Url.revokeObjectUrl(url);

      Get.snackbar(
        "Success",
        "Post/Final Excel downloaded successfully",
        snackPosition: SnackPosition.TOP,

        backgroundColor: const Color(0xFF16A34A),
        colorText: Colors.white,

        icon: const Icon(
          Icons.check_circle_outline,
          color: Colors.white,
          size: 22,
        ),

        margin: const EdgeInsets.all(16),
        borderRadius: 10,

        duration: const Duration(seconds: 5),

        // Optional
        snackStyle: SnackStyle.FLOATING,
        isDismissible: true,
      );
    } else {
      // ANDROID / iOS
      final directory =
      await getApplicationDocumentsDirectory();

      final filePath =
          "${directory.path}/Post_Upload_File.xlsx";

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
  String formatTime1(String time) {
    try {
      final parsedTime = DateFormat("HH:mm:ss").parse(time);
      return DateFormat("hh:mm a").format(parsedTime);
    } catch (e) {
      return time;
    }
  }

  void refreshReports() {
    if (selectedFromDate != null && selectedToDate != null) {
      reportsFuture = ReportController.fetchReports1(
        fromDate: DateFormat('yyyy-MM-dd')
            .format(selectedFromDate!),
        toDate: DateFormat('yyyy-MM-dd')
            .format(selectedToDate!),
        cid: widget.cid,
      );
    } else {
      reportsFuture =
          ReportController.fetchReports(widget.cid);
    }

    currentPage = 0;

    setState(() {});
  }
  //edit form
  final List<String> statusList = [
    "Rejected",
    "Review",
    "Partial",
    "Carded",
  ];
  final List<String> relationList = ["ETB", "NTB"];
  final List<String> variantList = ["Platinum", "Signature"];
  String? selectedStatusRemark;
  String? selectedRelationListRemark;
  String? selectedVariantListRemark;


  void _showEditDialog(ClientFormReportModel report) {
    final applicationController = TextEditingController(
      text: report.applicationNo,
    );
    final relationController = TextEditingController(text: report.relation);
    final variantController = TextEditingController(text: report.variant);
    final statusController = TextEditingController(text: report.status);
    final remarksController = TextEditingController(text: report.remarks);
    TextEditingController managerRemark = TextEditingController(text: report.managerRemarks);

    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 520,
            maxHeight: 700,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ================= HEADER =================

                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Color(0xFF2563EB),
                        size: 25,
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Edit Client Form",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Update client application details",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),

                    InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 19,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Divider(
                  color: Color(0xFFE5E7EB),
                  height: 1,
                ),

                const SizedBox(height: 22),

                // ================= APPLICATION NUMBER =================

                const Text(
                  "Application Details",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: applicationController,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                  decoration: InputDecoration(
                    labelText: "Application Number",
                    hintText: "Enter application number",
                    prefixIcon: const Icon(
                      Icons.confirmation_number_outlined,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ================= RELATION =================

                DropdownButtonFormField<String>(
                  value: report.relation,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Relation",
                    prefixIcon: const Icon(
                      Icons.people_outline_rounded,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.5,
                      ),
                    ),
                  ),
                  hint: const Text("Select Relation"),
                  items: relationList.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRelationListRemark = value;
                      relationController.text = value ?? "";
                    });
                  },
                ),

                const SizedBox(height: 16),

                // ================= VARIANT =================

                DropdownButtonFormField<String>(
                  value: report.variant,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Variant",
                    prefixIcon: const Icon(
                      Icons.category_outlined,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.5,
                      ),
                    ),
                  ),
                  hint: const Text("Select Variant"),
                  items: variantList.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedVariantListRemark = value;
                      variantController.text = value ?? "";
                    });
                  },
                ),

                const SizedBox(height: 16),

                // ================= STATUS =================

                DropdownButtonFormField<String>(
                  value: report.status,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Status",
                    prefixIcon: const Icon(
                      Icons.flag_outlined,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.5,
                      ),
                    ),
                  ),
                  hint: const Text("Select Status"),
                  items: statusList.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStatusRemark = value;
                      statusController.text = value ?? "";
                    });
                  },
                ),

                const SizedBox(height: 18),

                // ================= REMARKS =================

                TextField(
                  controller: remarksController,
                  maxLines: 3,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                  decoration: InputDecoration(
                    labelText: "Remarks",
                    hintText: "Enter remarks",
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 35),
                      child: Icon(
                        Icons.notes_rounded,
                        size: 20,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ================= MANAGER REMARK =================

                TextField(
                  controller: managerRemark,
                  maxLines: 3,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                  decoration: InputDecoration(
                    labelText: "Manager Remark",
                    hintText: "Enter manager remark",
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 35),
                      child: Icon(
                        Icons.manage_accounts_outlined,
                        size: 20,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(
                        color: Color(0xFF2563EB),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ================= BUTTONS =================

                Row(
                  children: [

                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Get.back();
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          side: const BorderSide(
                            color: Color(0xFFD1D5DB),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {

                          bool success =
                          await ReportController.updateFormDetails(
                            id: report.id,
                            applicationNo:
                            applicationController.text.trim(),
                            relation:
                            relationController.text.trim(),
                            variant:
                            variantController.text.trim(),
                            status:
                            statusController.text.trim(),
                            remarks:
                            remarksController.text.trim(),
                            managerRemark:
                            managerRemark.text.trim(),
                          );

                          if (success) {
                            Get.back();

                            refreshReports();

                            Get.snackbar(
                              "Success",
                              "Client form updated successfully.",
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          } else {

                            Get.snackbar(
                              "Update Failed",
                              "Unable to update the client form.",
                              snackPosition: SnackPosition.BOTTOM,
                              margin: const EdgeInsets.all(12),
                              borderRadius: 10,
                              backgroundColor:
                              const Color(0xFFDC2626),
                              colorText: Colors.white,
                              icon: const Icon(
                                Icons.error_outline,
                                color: Colors.white,
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.save_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          "Update",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String selectedCity = "";
  String selectedUserName = "";
  String selectedStatus = "";
  String selectedBankStatus = "";
  List<ClientFormReportModel> allReports = [];
  void _showCityFilter() {
    List<String> cities = allReports.map((e) => e.siteName).toSet().toList();
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Filter by City"),
          content: SizedBox(
            width: 250,
            height: 300,
            child: ListView.builder(
              itemCount: cities.length,
              itemBuilder: (context, index) {
                String city = cities[index];

                return ListTile(
                  title: Text(city),
                  onTap: () {
                    setState(() {
                      selectedCity = city;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  selectedCity = "";
                });
                Navigator.pop(context);
              },
              child: const Text("Clear Filter"),
            ),
          ],
        );
      },
    );
  }

  void _showUserFilter() {
    List<String> users =
    allReports.map((e) => e.userName).toSet().toList();

    users.sort();

    showDialog(
      context: context,
      builder: (_) {
        String searchText = "";

        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Search ke according users filter
            final filteredUsers = users.where((name) {
              return name.toLowerCase().contains(
                searchText.toLowerCase(),
              );
            }).toList();

            return AlertDialog(
              title: const Text("Filter by User Name"),

              content: SizedBox(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    // 🔍 Search Box
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search user name...",
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

                    const SizedBox(height: 12),

                    // 👤 User List
                    Expanded(
                      child: filteredUsers.isEmpty
                          ? const Center(
                        child: Text(
                          "No user found",
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      )
                          : ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final name = filteredUsers[index];

                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(name),
                            trailing: selectedUserName == name
                                ? const Icon(
                              Icons.check,
                              color: Colors.green,
                            )
                                : null,
                            onTap: () {
                              setState(() {
                                selectedUserName = name;
                                currentPage = 0;
                              });

                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Actions
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedUserName = "";
                      currentPage = 0;
                    });

                    Navigator.pop(context);
                  },
                  child: const Text("Clear Filter"),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showStatusFilter() {
    List<String> statuses = allReports.map((e) => e.status).toSet().toList();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Filter by Status"),
          content: SizedBox(
            width: 250,
            height: 250,
            child: ListView.builder(
              itemCount: statuses.length,
              itemBuilder: (context, index) {
                String status = statuses[index];

                return ListTile(
                  title: Text(status.toUpperCase()),
                  onTap: () {
                    setState(() {
                      selectedStatus = status;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  selectedStatus = "";
                });
                Navigator.pop(context);
              },
              child: const Text("Clear Filter"),
            ),
          ],
        );
      },
    );
  }
  void _showBankStatusFilter() {
    List<String> statuses = allReports.map((e) => e.bankRemarks).toSet().toList();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Filter by Bank Remarks"),
          content: SizedBox(
            width: 250,
            height: 250,
            child: ListView.builder(
              itemCount: statuses.length,
              itemBuilder: (context, index) {
                String status = statuses[index];

                return ListTile(
                  title: Text(status),
                  onTap: () {
                    setState(() {
                      selectedBankStatus = status;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  selectedBankStatus = "";
                });
                Navigator.pop(context);
              },
              child: const Text("Clear Filter"),
            ),
          ],
        );
      },
    );
  }
  final Map<String, String> addressCache = {};
  Future<String> getAddressCached(String gps) async {
    try {
      if (gps.trim().isEmpty) {
        return "Address not found";
      }

      // =========================
      // GPS PARSE
      // =========================

      final parts = gps.split(',');

      if (parts.length < 2) {
        return "Invalid GPS";
      }

      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());

      if (lat == null || lng == null) {
        return "Invalid GPS";
      }

      final key = "$lat,$lng";

      debugPrint("Getting address for: $lat, $lng");

      // =========================
      // CACHE CHECK
      // =========================

      if (addressCache.containsKey(key)) {
        debugPrint("✅ Address found in cache");

        return addressCache[key]!;
      }

      String address = "Address not found";

      // =========================
      // WEB
      // =========================

      if (kIsWeb) {
        const googleApiKey =
            "AIzaSyBF7OlUqnsWTXRMiwtwEk9ieQ4YkzIhq18";

        final url =
            "https://maps.googleapis.com/maps/api/geocode/json"
            "?latlng=$lat,$lng"
            "&key=$googleApiKey";

        debugPrint("🌐 Calling Google Geocoding API");

        final response = await http.get(
          Uri.parse(url),
        );

        debugPrint(
          "Geocoding Status Code: ${response.statusCode}",
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);

          if (responseData['status'] == 'OK' &&
              responseData['results'] != null &&
              responseData['results'].isNotEmpty) {

            address =
                responseData['results'][0]['formatted_address']
                    ?.toString() ??
                    "Address not found";
          } else {
            debugPrint(
              "❌ Google Geocoding Status: "
                  "${responseData['status']}",
            );

            address = "Address not found";
          }
        } else {
          debugPrint(
            "❌ HTTP Error: ${response.statusCode}",
          );

          address = "Address not found";
        }
      }

      // =========================
      // ANDROID / IOS
      // =========================

      else {
        debugPrint("📱 Using native geocoding");

        final List<Placemark> placemarks =
        await placemarkFromCoordinates(
          lat,
          lng,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          final addressParts = <String>[
            if (place.name?.trim().isNotEmpty == true)
              place.name!.trim(),

            if (place.street?.trim().isNotEmpty == true)
              place.street!.trim(),

            if (place.subLocality?.trim().isNotEmpty == true)
              place.subLocality!.trim(),

            if (place.locality?.trim().isNotEmpty == true)
              place.locality!.trim(),

            if (place.subAdministrativeArea
                ?.trim()
                .isNotEmpty ==
                true)
              place.subAdministrativeArea!.trim(),

            if (place.administrativeArea?.trim().isNotEmpty == true)
              place.administrativeArea!.trim(),

            if (place.postalCode?.trim().isNotEmpty == true)
              place.postalCode!.trim(),

            if (place.country?.trim().isNotEmpty == true)
              place.country!.trim(),
          ];

          if (addressParts.isNotEmpty) {
            address = addressParts.join(", ");
          }
        }
      }

      // =========================
      // SAVE CACHE
      // =========================

      addressCache[key] = address;

      debugPrint("✅ Address: $address");

      return address;
    } catch (e, stackTrace) {
      debugPrint(
        "❌ Reverse Geocoding Error: $e",
      );

      debugPrint("$stackTrace");

      return "Address not found";
    }
  }
  String formatGpsLocation(String gps) {
    try {
      final parts = gps.split(',');

      if (parts.length < 2) {
        return "Invalid location";
      }

      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());

      if (lat == null || lng == null) {
        return "Invalid location";
      }

      final latDirection = lat >= 0 ? "N" : "S";
      final lngDirection = lng >= 0 ? "E" : "W";

      return "${lat.abs().toStringAsFixed(6)}° $latDirection, "
          "${lng.abs().toStringAsFixed(6)}° $lngDirection";
    } catch (e) {
      return "Invalid location";
    }
  }
  //upload mai file
//search box
  final TextEditingController applicationSearchController =
  TextEditingController();
  @override
  void dispose() {
    applicationSearchController.dispose();
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
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
        title: const Text(
          "Client Submission Form ",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          SizedBox(width: 20,),
          ElevatedButton(
            onPressed: () async {
              await Get.to(
                    () => BulkUploadFormScreen(
                  cid: widget.cid,
                ),
              );

              // User returned from inactive screen
              if (mounted) {
                refreshReports();
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: const Text("Bulk Upload"),
          ),
          SizedBox(width: 20,),
          ElevatedButton(
            onPressed: () async {
              await Get.to(
                    () => DuplicateFormScreen(
                  cid: widget.cid,
                ),
              );

              // User returned from inactive screen
              if (mounted) {
                refreshReports();
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: const Text("Inactive Forms"),
          ),// Get.to(()=>ShiftScreen(cid:widget.cid));
          SizedBox(
            width: 10,
          ),
          ElevatedButton(
            onPressed: () async {
              final reports = await reportsFuture;
              if (reports.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("No reports to download"),
                  ),
                );
                return;
              }
              await exportReportsToExcel(context, reports);
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5), // Perfect square corners
              ),
            ),
            child: Row(
              children: [
                Container(child: Text("Export Template")),//Download Template
              ],
            ),
          ),
          SizedBox(
            width: 10,
          ),
          ElevatedButton(onPressed: (){
            Get.to(()=>UploadRemarkScreen());
          }, style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5), // Perfect square corners
            ),
          ),child: Text("Import Template")),//
          SizedBox(
            width: 10,
          ),
          ElevatedButton(
            onPressed: () async {
              final reports = await reportsFuture;

              if (reports.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("No reports to download"),
                  ),
                );
                return;
              }

              // Sirf wahi rows jisme Bank Remark ya Update Status available hai
              final postFinalReports = reports.where((report) {
                final bankRemark = report.bankRemarks.trim();
                final updateStatus = report.updateStatus.trim();

                return bankRemark.isNotEmpty || updateStatus.isNotEmpty;
              }).toList();

              // Agar kisi bhi row me Bank Remark / Update Status nahi hai
              if (postFinalReports.isEmpty) {
                Get.snackbar(
                  "Error",
                  "No Post/Final records available. Bank Remark or Update Status is required.",
                  snackPosition: SnackPosition.TOP,

                  backgroundColor: const Color(0xFF16A34A),
                  colorText: Colors.white,

                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 22,
                  ),

                  margin: const EdgeInsets.all(16),
                  borderRadius: 10,

                  duration: const Duration(seconds: 5),

                  // Optional
                  snackStyle: SnackStyle.FLOATING,
                  isDismissible: true,
                );
                return;
              }

              // Sirf filtered rows export hongi
              await exportReportsToApprovedExcel(
                context,
                postFinalReports,
              );
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Post/Final Download"),
              ],
            ),
          ),
          SizedBox(
            width: 10,
          ),

          InkWell(
            onTap: _pickDateAndFetchReports,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 19,
                    color: Color(0xFF2563EB),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    selectedFromDate != null &&
                        selectedToDate != null
                        ? "${DateFormat('dd-MM-yyyy').format(selectedFromDate!)}"
                        " → "
                        "${DateFormat('dd-MM-yyyy').format(selectedToDate!)}"
                        : "Select Date Range",

                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 10,
          ),
          // IconButton(
          //   onPressed: () {
          //     showDialog(
          //       context: context,
          //       builder: (context) {
          //         return AlertDialog(
          //           title: const Text("Remark"),
          //           content: const Text("Download the template file and post update status file."),
          //           actions: [
          //             ElevatedButton(
          //               onPressed: () async {
          //                 final reports = await reportsFuture;
          //                 if (reports.isEmpty) {
          //                   ScaffoldMessenger.of(context).showSnackBar(
          //                     const SnackBar(
          //                       content: Text("No reports to download"),
          //                     ),
          //                   );
          //                   return;
          //                 }
          //                 await exportReportsToExcel(context, reports);
          //               },
          //               child: Row(
          //                 children: [
          //                   Container(child: Text("Download Template")),
          //                 ],
          //               ),
          //             ),
          //             const SizedBox(
          //               height: 40,
          //             ),
          //             ElevatedButton(
          //         onPressed: () async {
          //         final reports = await reportsFuture;
          //         if (reports.isEmpty) {
          //         ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(content: Text("No reports to download")),
          //         );
          //         return;
          //         }
          //         await exportReportsToApprovedExcel(context, reports);
          //         },
          //               child: Row(
          //                 children: [
          //                   Container(child: Text("Post/Final Download")),
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

          allReports = snapshot.data!;

          final applicationSearch =
          applicationSearchController.text.trim().toLowerCase();

          final reports = allReports.where((e) {
            final cityMatch =
                selectedCity.isEmpty || e.siteName == selectedCity;

            final userMatch =
                selectedUserName.isEmpty || e.userName == selectedUserName;

            final statusMatch =
                selectedStatus.isEmpty || e.status == selectedStatus;

            final applicationMatch =
                applicationSearch.isEmpty ||
                    e.applicationNo.toLowerCase().contains(applicationSearch);

            return cityMatch &&
                userMatch &&
                statusMatch &&
                applicationMatch;
          }).toList();
          // 👉 PAGINATION LOGIC
          final paginatedReports = reports
              .skip(currentPage * rowsPerPage)
              .take(rowsPerPage)
              .toList();

          return Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Container(
                  width: 400,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: applicationSearchController,
                    onChanged: (value) {
                      setState(() {
                        currentPage = 0;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search Application Number",
                      labelText: "Application Number",
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xff2563EB),
                      ),
                      suffixIcon: applicationSearchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          applicationSearchController.clear();

                          setState(() {
                            currentPage = 0;
                          });
                        },
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xff2563EB),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
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
                              columns: [
                                DataColumn(label: Text("Action",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Report Id",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif')
                                  ,)),
                                DataColumn(label: Text("User Id",
                                  style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif')
                                  ,)),
                                DataColumn(
                                  label: Row(
                                    children: [
                                      const Text("User Name",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),),
                                      IconButton(
                                        icon: const Icon(Icons.filter_list, size: 18,color: Color(0xff2563EB),),
                                        onPressed: _showUserFilter,
                                      ),
                                    ],
                                  ),
                                ),
                                DataColumn(
                                  label: Row(
                                    children: [
                                      const Text("City Name",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),),
                                      IconButton(
                                        icon: const Icon(Icons.filter_list, size: 18,color: Color(0xff2563EB),),
                                        onPressed: _showCityFilter,
                                      ),
                                    ],
                                  ),
                                ),
                                DataColumn(label: Text("Report Date",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Report Time",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Application Number",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Relation",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Variant",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(
                                  label: Row(
                                    children: [
                                      const Text("Status",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),),
                                      IconButton(
                                        icon: const Icon(Icons.filter_list, size: 18,color: Color(0xff2563EB),),
                                        onPressed: _showStatusFilter,
                                      ),
                                    ],
                                  ),
                                ),
                                DataColumn(label: Text("Remarks",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Manager Remarks",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Contact Number",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Snapshot",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Address",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Kiosk Name",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Site Name",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Bank Remark",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),

                                // DataColumn(
                                //   label: Row(
                                //     children: [
                                //       const Text("Bank Remark"),
                                //       IconButton(
                                //         icon: const Icon(Icons.filter_list, size: 18),
                                //         onPressed: _showBankStatusFilter,
                                //       ),
                                //     ],
                                //   ),
                                // ),

                                DataColumn(label: Text("Update Status",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                                DataColumn(label: Text("Remarks Date",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                              ],
                              rows: paginatedReports.map<DataRow>((report) {
                                return DataRow(
                                  cells: [
                                    // Action
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit,color: Color(0xff2563EB),),
                                            onPressed: () {
                                              _showEditDialog(report);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.highlight_off,color: Colors.black,),
                                            onPressed: () {
                                              debugPrint(report.uid.toString());
                                              _confirmAndUpdateDuplicate(report);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.location_on_outlined,
                                              color: Colors.black,
                                            ),
                                            onPressed: () async {
                                              debugPrint(report.uid.toString());
                                              debugPrint(report.gpsLocation.toString());

                                              final location = report.gpsLocation;

                                              if (location == null || location.toString().trim().isEmpty) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text("Location not available"),
                                                  ),
                                                );
                                                return;
                                              }

                                              try {
                                                // Agar gpsLocation "19.0760,72.8777" format mein hai
                                                final parts = location.toString().split(',');

                                                if (parts.length < 2) {
                                                  throw Exception("Invalid latitude/longitude");
                                                }

                                                final latitude = parts[0].trim();
                                                final longitude = parts[1].trim();

                                                final Uri googleMapUrl = Uri.parse(
                                                  "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude",
                                                );

                                                if (await canLaunchUrl(googleMapUrl)) {
                                                  await launchUrl(
                                                    googleMapUrl,
                                                    mode: LaunchMode.externalApplication,
                                                  );
                                                } else {
                                                  throw Exception("Could not open Google Maps");
                                                }
                                              } catch (e) {
                                                debugPrint("Map Error: $e");

                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text("Unable to open location: $e"),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),

                                    DataCell(Text(report.id.toString())),
                                    DataCell(Text(report.userId)),
                                    DataCell(Text(report.userName)),
                                    DataCell(Text(report.siteName)),
                                    DataCell(
                                      Text(
                                        DateFormat('dd-MM-yyyy').format(
                                          DateTime.parse(report.reportDate),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(formatTime1(report.reportTime))),
                                    DataCell(Text(report.applicationNo)),
                                    DataCell(Text(report.relation.toUpperCase())),
                                    DataCell(Text(report.variant.toUpperCase())),

                                    // Status Color
                                    DataCell(
                                      Text(
                                        report.status.toUpperCase(),
                                        style: TextStyle(
                                          color:
                                              report.bankRemarks.toLowerCase() ==
                                                  "approved"
                                              ? Colors.green
                                              : Color(0xff2563EB),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    DataCell(Text(report.remarks)),
                                    DataCell(
                                      Text(report.managerRemarks, maxLines: 5),
                                    ),
                                    DataCell(Text(report.contactNo)),

                                    // 🔥 Multiple Images
                                    DataCell(
                                      report.imageUrls.isNotEmpty
                                          ? ElevatedButton.icon(
                                        onPressed: () {
                                          _showImagesDialog(
                                            context,
                                            report.imageUrls,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.image,
                                          size: 18,
                                        ),
                                        label: const Text("View Image"),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                      )
                                          : const Text(
                                        "No Image",
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),

                                    DataCell(
                                      FutureBuilder<String>(
                                        future: getAddressCached(report.gpsLocation),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const SizedBox(
                                              width: 250,
                                              child: Text(
                                                "Loading address...",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            );
                                          }

                                          if (snapshot.hasError) {
                                            return const SizedBox(
                                              width: 250,
                                              child: Text(
                                                "Address not found",
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            );
                                          }

                                          final address = snapshot.data;

                                          if (address == null || address.trim().isEmpty) {
                                            return const SizedBox(
                                              width: 250,
                                              child: Text("Address not found"),
                                            );
                                          }

                                          return SizedBox(
                                            width: 250,
                                            child: Text(
                                              address,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    DataCell(Text(report.kioskName)),
                                    DataCell(Text(report.attendanceSiteName)),
                                    DataCell(Text(report.bankRemarks)),
                                    DataCell(Text(report.updateStatus)),

                                    DataCell(
                                      Text(
                                        DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(DateTime.parse(report.createdAt)),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                ),

                const SizedBox(height: 10),

                // Pagination stays OUTSIDE Expanded
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: currentPage > 0
                          ? () {
                        setState(() {
                          currentPage--;
                        });
                      }
                          : null,
                      child: const Text("Previous"),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Page ${currentPage + 1} of "
                          "${(reports.length / rowsPerPage).ceil() == 0
                          ? 1
                          : (reports.length / rowsPerPage).ceil()}",
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed:
                      (currentPage + 1) * rowsPerPage < reports.length
                          ? () {
                        setState(() {
                          currentPage++;
                        });
                      }
                          : null,
                      child: const Text("Next"),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
