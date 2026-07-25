import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';
import 'package:joizone/admin/view/upload_remark_screen.dart';
import 'package:joizone/user/model/client_form_report_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import '../controller/form_reports_controller.dart';
import 'duplicate_form_screen.dart';

class AllFormReportScreen extends StatefulWidget {
  final String cid;
  const AllFormReportScreen({super.key, required this.cid});

  @override
  State<AllFormReportScreen> createState() => _AllFormReportScreenState();
}

class _AllFormReportScreenState extends State<AllFormReportScreen> {
  late Future<List<ClientFormReportModel>> reportsFuture;

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    reportsFuture = ReportController.fetchReports(widget.cid);
    print("=============");
    print("=============");
    print(reportsFuture);
    print("=============");
    print("=============");
  }
  int rowsPerPage = 10;
  int currentPage = 0;
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
                        child: CircularProgressIndicator(color: Colors.white),
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
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
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
            title: const Text("Form as Inactive?"),
            content: const Text(
              "Are you sure you want to inactive?",
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
      duplicateFrom: "yes", // ✅ correct value
    );

    if (success) {
      setState(() {
        reportsFuture = ReportController.fetchReports(widget.cid); // 🔥 refresh
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
      saveText: "Submit",
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(Duration(days: 2)),
        end: DateTime.now(),
      ),
    );

    if (pickedRange != null) {
      String fromDate =
          "${pickedRange.start.year}-${pickedRange.start.month.toString().padLeft(2, '0')}-${pickedRange.start.day.toString().padLeft(2, '0')}";

      String toDate =
          "${pickedRange.end.year}-${pickedRange.end.month.toString().padLeft(2, '0')}-${pickedRange.end.day.toString().padLeft(2, '0')}";

      setState(() {
        reportsFuture = ReportController.fetchReports1(
          fromDate: fromDate,
          toDate: toDate,
          cid: widget.cid,
        );
      });
    }
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
        TextCellValue(row.reportDate),
        TextCellValue(formatTime1(row.reportTime ?? "")),
        TextCellValue(row.applicationNo),
        TextCellValue(row.relation),
        TextCellValue(row.variant),
        TextCellValue(row.status),
        TextCellValue(row.remarks),
        TextCellValue(row.managerRemarks),
        TextCellValue(imageUrls),
        TextCellValue(row.contactNo),
        TextCellValue(address),
        TextCellValue(row.kioskName),
        TextCellValue("Not Found Application"),
        TextCellValue(
          DateFormat('yyyy-MM-dd').format(DateTime.parse(row.createdAt)),
        ),
      ]);
    }

    final List<int>? bytes = excel.encode();
    if (bytes == null) return;

    if (kIsWeb) {
      // Web download
      final blob = html.Blob([Uint8List.fromList(bytes)]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "Remarks_Update_Template_Joizone.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Android/iOS: Save to Documents folder
      final directory = await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/Remarks_Update_Template_Joizone.xlsx";
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
      TextCellValue("Bank Remark"),
      TextCellValue("Update Status"),
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
        TextCellValue(row.reportDate),
        TextCellValue(formatTime1(row.reportTime ?? "")),
        TextCellValue(row.applicationNo),
        TextCellValue(row.relation),
        TextCellValue(row.variant),
        TextCellValue(row.status),
        TextCellValue(row.remarks),
        TextCellValue(row.managerRemarks),
        TextCellValue(imageUrls),
        TextCellValue(row.contactNo),
        TextCellValue(address),
        TextCellValue(row.kioskName),
        TextCellValue(row.bankRemarks),
        TextCellValue(row.updateStatus),
        TextCellValue(
          DateFormat('yyyy-MM-dd').format(DateTime.parse(row.createdAt)),
        ),
      ]);
    }
    final List<int>? bytes = excel.encode();
    if (bytes == null) return;

    if (kIsWeb) {
      // Web download
      final blob = html.Blob([Uint8List.fromList(bytes)]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "Post_Upload_File.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Android/iOS: Save to Documents folder
      final directory = await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/Post_Upload_File.xlsx";
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Excel saved to $filePath")));
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

    Get.defaultDialog(
      title: "Edit Client Form",
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 10,),
              TextField(
                controller: applicationController,
                decoration: const InputDecoration(
                  labelText: "Application Number",
                ),
              ),
              SizedBox(height: 10,),
              DropdownButtonFormField<String>(
                value: selectedRelationListRemark,
                decoration: const InputDecoration(
                  labelText: "Relation",
                  border: OutlineInputBorder(),
                ),
                hint: const Text("Select Relation"),
                items: relationList.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRelationListRemark = value;
                    relationController.text = value!;
                  });
                },
              ),
              SizedBox(height: 10,),
              SizedBox(height: 10,),
              DropdownButtonFormField<String>(
                value: selectedVariantListRemark,
                decoration: const InputDecoration(
                  labelText: "Variant",
                  border: OutlineInputBorder(),
                ),
                hint: const Text("Select Variant"),
                items: variantList.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedVariantListRemark = value;
                    variantController.text = value!;
                  });
                },
              ),
              SizedBox(height: 10,),
              SizedBox(height: 10,),
              DropdownButtonFormField<String>(
                value: selectedStatusRemark,
                decoration: const InputDecoration(
                  labelText: "Status",
                  border: OutlineInputBorder(),
                ),
                hint: const Text("Select Status"),
                items: statusList.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStatusRemark = value;
                    statusController.text = value!;
                  });
                },
              ),
              SizedBox(height: 10,),
              TextField(
                controller: remarksController,
                decoration: const InputDecoration(labelText: "Remarks"),
              ),
              SizedBox(height: 10,),
              TextField(
                controller: managerRemark,
                decoration: const InputDecoration(labelText: "Manager Remark"),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () async {
                  bool success = await ReportController.updateFormDetails(
                    id: report.id,
                    applicationNo: applicationController.text,
                    relation: relationController.text,
                    variant: variantController.text,
                    status: statusController.text,
                    remarks: remarksController.text,
                    managerRemark: managerRemark.text,
                  );

                  if (success) {
                    Get.back(); // close dialog

                    setState(() {
                      reportsFuture = ReportController.fetchReports(widget.cid);
                    });
                    Get.snackbar(
                      "Success updated...",
                      "Successfully updated manager remark...",
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  } else {
                    Get.snackbar(
                      "Error",
                      "Update failed",
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                child: const Text("Update"),
              ),
            ],
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
    List<String> users = allReports.map((e) => e.userName).toSet().toList();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Filter by User Name"),
          content: SizedBox(
            width: 250,
            height: 300,
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                String name = users[index];

                return ListTile(
                  title: Text(name),
                  onTap: () {
                    setState(() {
                      selectedUserName = name;
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
                  selectedUserName = "";
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
                  title: Text(status),
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
  Future<String> getAddressCached(String gps) async {
    try {
      final parts = gps.split(',');

      double lat = double.parse(parts[0].trim());
      double lng = double.parse(parts[1].trim());

      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isEmpty) return gps;

      Placemark place = placemarks.first;

      List<String> addressParts = [
        place.name ?? "",
        place.street ?? "",
        place.subLocality ?? "",
        place.locality ?? "",
        place.administrativeArea ?? "",
        place.postalCode ?? "",
        place.country ?? "",
      ];

      // Remove empty values
      addressParts.removeWhere((e) => e.trim().isEmpty);

      return addressParts.join(", ");
    } catch (e) {
      return gps;
    }
  }
  //upload mai file

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
          ElevatedButton(onPressed: (){
            Get.to(() => DuplicateFormScreen(cid:widget.cid));
          }, style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5), // Perfect square corners
            ),
          ),child: Text("Inactive Forms")),// Get.to(()=>ShiftScreen(cid:widget.cid));
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
                Container(child: Text("Download Template")),
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
          ),child: Text("Upload Template")),
          SizedBox(
            width: 10,
          ),
          ElevatedButton(
            onPressed: () async {
              final reports = await reportsFuture;
              if (reports.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No reports to download")),
                );
                return;
              }
              await exportReportsToApprovedExcel(context, reports);
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5), // Perfect square corners
              ),
            ),
            child: Row(
              children: [
                Container(child: Text("Post/Final Download")),
              ],
            ),
          ),
          SizedBox(
            width: 10,
          ),
          IconButton(
            onPressed: _pickDateAndFetchReports,
            icon: Icon(Icons.calendar_month, color: Colors.white),
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

          final reports = allReports.where((e) {
            bool cityMatch = selectedCity.isEmpty || e.siteName == selectedCity;
            bool userMatch = selectedUserName.isEmpty || e.userName == selectedUserName;
            bool statusMatch = selectedStatus.isEmpty || e.status == selectedStatus;

            return cityMatch && userMatch && statusMatch;
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
                                DataColumn(label: Text("Action")),
                                DataColumn(label: Text("UID")),
                                DataColumn(label: Text("User Id")),
                                DataColumn(
                                  label: Row(
                                    children: [
                                      const Text("User Name"),
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
                                      const Text("City Name"),
                                      IconButton(
                                        icon: const Icon(Icons.filter_list, size: 18,color: Color(0xff2563EB),),
                                        onPressed: _showCityFilter,
                                      ),
                                    ],
                                  ),
                                ),
                                DataColumn(label: Text("Report Date")),
                                DataColumn(label: Text("Report Time")),
                                DataColumn(label: Text("Application Number")),
                                DataColumn(label: Text("Relation")),
                                DataColumn(label: Text("Variant")),
                                DataColumn(
                                  label: Row(
                                    children: [
                                      const Text("Status"),
                                      IconButton(
                                        icon: const Icon(Icons.filter_list, size: 18,color: Color(0xff2563EB),),
                                        onPressed: _showStatusFilter,
                                      ),
                                    ],
                                  ),
                                ),
                                DataColumn(label: Text("Remarks")),
                                DataColumn(label: Text("Manager Remarks")),
                                DataColumn(label: Text("Contact Number")),
                                DataColumn(label: Text("Snapshot")),
                                DataColumn(label: Text("Address")),
                                DataColumn(label: Text("Kiosk Name")),
                                DataColumn(label: Text("Bank Remark")),
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
                                DataColumn(label: Text("Update Status")),
                                DataColumn(label: Text("Remarks Date")),
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
                                        ],
                                      ),
                                    ),

                                    DataCell(Text(report.uid.toString())),
                                    DataCell(Text(report.userId)),
                                    DataCell(Text(report.userName)),
                                    DataCell(Text(report.siteName)),
                                    DataCell(Text(report.reportDate)),
                                    DataCell(Text(formatTime1(report.reportTime))),
                                    DataCell(Text(report.applicationNo)),
                                    DataCell(Text(report.relation)),
                                    DataCell(Text(report.variant)),

                                    // Status Color
                                    DataCell(
                                      Text(
                                        report.status,
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
                                          ? SizedBox(
                                              width: 150,
                                              child: ListView.builder(
                                                scrollDirection: Axis.horizontal,
                                                itemCount: report.imageUrls.length,
                                                itemBuilder: (context, index) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(
                                                      right: 6,
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(6),
                                                      child: InkWell(
                                                        onTap: () {
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

                                    DataCell(
                                      FutureBuilder<String>(
                                future: getAddressCached(report.gpsLocation),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Text("Loading...");
                                          }

                                          return SizedBox(
                                            width: 200,
                                            child: Text(
                                              snapshot.data ?? "Address not found",
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    DataCell(Text(report.kioskName)),
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
                          ? () => setState(() => currentPage--)
                          : null,
                      child: const Text("Previous"),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Page ${currentPage + 1} of ${(allReports.length / rowsPerPage).ceil()}",
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed:
                      (currentPage + 1) * rowsPerPage < allReports.length
                          ? () => setState(() => currentPage++)
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
