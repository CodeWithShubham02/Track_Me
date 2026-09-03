import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:joizone/admin/view/add_attedance.dart';
import 'package:joizone/admin/view/shift_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'assign_holiday_screen.dart';
import 'holiday_screen.dart';
import 'monthly_attendance_screen.dart';
import 'monthly_summary_screen.dart';

class AllEmployeeAttendanceScreen extends StatefulWidget {
  final String cid;

  const AllEmployeeAttendanceScreen({super.key, required this.cid});

  @override
  State<AllEmployeeAttendanceScreen> createState() =>
      _AllEmployeeAttendanceScreenState();
}

class _AllEmployeeAttendanceScreenState
    extends State<AllEmployeeAttendanceScreen> {
  DateTime selectedDate = DateTime.now();
  String? selectedDepartment;

  List<Map<String, dynamic>> attendanceRecords = [];
  bool isLoading = false;

  // ---------------- DATE KEY ----------------
  String dateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // ---------------- API CALL ----------------
  Future<void> fetchAttendanceByDate() async {
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(
          "http://15.206.209.30/attendance/fetch_attendance_by_date.php",
        ),
        body: {"cid": widget.cid, "date": dateKey(selectedDate)},
      );

      final jsonData = json.decode(response.body);
      print("----------");
      print(jsonData);
      if (jsonData['status'] == true) {
        setState(() {
          attendanceRecords = List<Map<String, dynamic>>.from(jsonData['data']);
        });
      } else {
        attendanceRecords = [];
      }
    } catch (e) {
      attendanceRecords = [];
    }

    setState(() => isLoading = false);
  }

  // ---------------- PICK DATE ----------------
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
      fetchAttendanceByDate();
    }
  }

  // ---------------- FILTER ----------------

  // ---------------- GOOGLE MAP ----------------
  Future<void> openGoogleMap(double lat, double lng) async {
    final url = "https://www.google.com/maps?q=$lat,$lng";
    final uri = Uri.parse(url);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.platformDefault, // 👈 IMPORTANT
    )) {
      throw 'Could not launch Google Maps';
    }
  }

  // ---------------- PDF EXPORT ----------------
  Future<void> exportAttendancePdf() async {
    if (attendanceRecords.isEmpty) return;

    var permission = await Permission.manageExternalStorage.request();
    if (!permission.isGranted) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) {
          return pw.Table.fromTextArray(
            headers: [
              "UID",
              "Name",
              "Department",
              "Date",
              "Punch In",
              "Punch Out",
              "Status",
              "Working Hours",
              "Break Minutes",
            ],
            data: attendanceRecords.map((e) {
              DateTime? punchIn = e['punch_in_time'] != null
                  ? DateTime.parse(e['punch_in_time'])
                  : null;
              DateTime? punchOut = e['punch_out_time'] != null
                  ? DateTime.parse(e['punch_out_time'])
                  : null;

              String working = "-";
              if (punchIn != null && punchOut != null) {
                final diff = punchOut.difference(punchIn);
                working = "${diff.inHours}h ${diff.inMinutes % 60}m";
              }

              return [
                e['uid'] ?? '-',
                e['name'] ?? '-',
                e['department'] ?? '-',
                punchIn != null
                    ? DateFormat('dd-MM-yyyy').format(punchIn)
                    : '-',
                punchIn != null ? DateFormat('HH:mm').format(punchIn) : '-',
                punchOut != null ? DateFormat('HH:mm').format(punchOut) : '-',
                e['status'] ?? '-',
                working,
                e['total_break_minutes']?.toString() ?? '-',
              ];
            }).toList(),
          );
        },
      ),
    );

    Directory dir = Directory("/storage/emulated/0/Download");
    final file = File("${dir.path}/Attendance_${Random().nextInt(9999)}.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)]);
  }

  @override
  void initState() {
    super.initState();
    fetchAttendanceByDate();
  }

  void showUpdateStatusDialog({
    required BuildContext context,
    required String attendanceId,
  }) {
    String selectedStatus = 'Present';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Update Attendance Status"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: "Select Status",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Present',
                        child: Text("Present"),
                      ),
                      DropdownMenuItem(value: 'ABSENT', child: Text("Absent")),
                      DropdownMenuItem(
                        value: 'HOLYDAY',
                        child: Text("Holiday"),
                      ),
                      DropdownMenuItem(
                        value: 'AUTO_PUNCH_OUT',
                        child: Text("Auto Punch Out"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await updateAttendanceStatus(
                      context: context,
                      attendanceId: attendanceId,
                      status: selectedStatus,
                    );
                  },
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> updateAttendanceStatus({
    required BuildContext context,
    required String attendanceId,
    required String status,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(
          "http://15.206.209.30/attendance/update_attendance_status.php",
        ),
        body: {"attendance_id": attendanceId, "status": status},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print(data);
        final isSuccess =
            data['status'] == true ||
            data['status'] == 1 ||
            data['status'].toString() == 'true';

        if (isSuccess) {
          Navigator.pop(context); // close dialog

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Attendance updated to $status"),
              backgroundColor: Colors.green,
            ),
          );

          // 🔄 OPTIONAL: refresh list
          // fetchAttendance();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? "Update failed"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

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

  // ---------------- FILTER SETS ----------------
  Set<String> selectedName = {};
  Set<String> selectedOffice = {};
  Set<String> selectedStatus = {};
  Set<String> selectedDepartment1 = {};

  void applyFilters() {
    setState(() {});
  }

  List<String> getUniqueValues(String key) {
    return attendanceRecords
        .map((e) => e[key]?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  void showMultiFilterDialog({
    required String title,
    required List<String> options,
    required Set<String> selectedValues,
  }) {
    showDialog(
      context: context,
      builder: (_) {
        String searchText = "";

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Search ke according options filter honge
            final filteredOptions = options.where((value) {
              return value.toLowerCase().contains(
                searchText.toLowerCase(),
              );
            }).toList();

            return AlertDialog(
              title: Text("Filter $title"),

              content: SizedBox(
                width: 300,
                height: 450,
                child: Column(
                  children: [
                    // 🔍 Search Box
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search $title...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchText.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setStateDialog(() {
                              searchText = "";
                            });
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (value) {
                        setStateDialog(() {
                          searchText = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Options
                    Expanded(
                      child: filteredOptions.isEmpty
                          ? const Center(
                        child: Text(
                          "No results found",
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      )
                          : ListView(
                        children: filteredOptions.map((value) {
                          return CheckboxListTile(
                            dense: true,
                            value: selectedValues.contains(value),
                            title: Text(value),
                            onChanged: (checked) {
                              setStateDialog(() {
                                if (checked == true) {
                                  selectedValues.add(value);
                                } else {
                                  selectedValues.remove(value);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedValues.clear();
                            });

                            applyFilters();

                            Navigator.pop(context);
                          },
                          child: const Text("Reset"),
                        ),

                        ElevatedButton(
                          onPressed: () {
                            applyFilters();

                            Navigator.pop(context);
                          },
                          child: const Text("Apply"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  //------Add the Pagination-------
  int currentPage = 0;
  final int rowsPerPage = 15;
  List<Map<String, dynamic>> getPaginatedRecords(
    List<Map<String, dynamic>> data,
  ) {
    final start = currentPage * rowsPerPage;
    final end = start + rowsPerPage;

    return data.sublist(start, end > data.length ? data.length : end);
  }
  //-------------------------------
//------------update weekly off----------
  Future<bool> updateHoliday({
    required String id,
    required DateTime date,
  }) async {
    final response = await http.post(
      Uri.parse("http://15.206.209.30/attendance/updateHoliday.php"),
      body: {
        "id": id,
        "date": DateFormat('yyyy-MM-dd').format(date),
      },
    );

    print(response.body);

    final json = jsonDecode(response.body);
    return json["status"] == true;
  }
  //----------------------------
  @override
  Widget build(BuildContext context) {
    final filteredRecords = attendanceRecords.where((row) {
      final officeMatch =
          selectedOffice.isEmpty || selectedOffice.contains(row['office_name']);
      final nameMatch =
          selectedName.isEmpty || selectedName.contains(row['name']);
      final statusMatch =
          selectedStatus.isEmpty || selectedStatus.contains(row['status']);

      final deptMatch =
          selectedDepartment1.isEmpty ||
          selectedDepartment1.contains(row['department']);

      return officeMatch && nameMatch && statusMatch && deptMatch;
    }).toList();

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
          "Daily Employee Attendance",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          // SizedBox(width: 10),
          // ElevatedButton(
          //   onPressed: () {
          //     //Get.to(()=>AddAttedance(cid: widget.cid));
          //     Get.to(() => HolidayScreen(cid: widget.cid));
          //   },
          //   style: ElevatedButton.styleFrom(
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(
          //         5,
          //       ), // Perfect square corners
          //     ),
          //   ),
          //   child: Text("Add WO"),
          // ),
          SizedBox(width: 10),
          // ElevatedButton(
          //   onPressed: () {
          //     Get.to(() => AddAttedance(cid: widget.cid));
          //   },
          //   style: ElevatedButton.styleFrom(
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(
          //         5,
          //       ), // Perfect square corners
          //     ),
          //   ),
          //   child: Text("Attendance Entry"),
          // ),
          SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              Get.to(() => MonthlyAttendanceScreen(cid: widget.cid));
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  5,
                ), // Perfect square corners
              ),
            ),
            child: Text("Monthly Attendance"),
          ),
          SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              Get.to(() => AttendanceSummaryScreen(cid: widget.cid,));
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  5,
                ), // Perfect square corners
              ),
            ),
            child: Text("Attendance Summary"),
          ),
          SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              Get.to(() => AssignHolidayScreen(cid:widget.cid));
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  5,
                ), // Perfect square corners
              ),
            ),
            child: Text("Roster Upload"),
          ), // Get.to(()=>ShiftScreen(cid:widget.cid));
          SizedBox(width: 10),

          IconButton(
            icon: const Icon(Icons.calendar_month,color: Colors.white,),
            onPressed: pickDate,
          ),
          SizedBox(width: 10),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredRecords.isEmpty
          ? const Center(child: Text("No attendance found"))
          : Scrollbar(
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
                        dataRowMinHeight: 60, // minimum height
                        dataRowMaxHeight: 100, // maximum height
                        headingRowHeight: 50, // heading row height
                        columnSpacing: 20,
                        headingRowColor: MaterialStateProperty.all(
                          Colors.grey.shade300,
                        ),
                        border: TableBorder.all(
                          color: Colors.black54,
                          width: 1,
                        ),
                        columns: [
                          const DataColumn(label: Text("Location",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                          const DataColumn(label: Text("Date",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                          const DataColumn(label: Text("userid",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                          //const DataColumn(label: Text("aid")),
                          DataColumn(
                            label: Row(
                              children: [
                                const Text("Name",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),),
                                const SizedBox(width: 5),
                                InkWell(
                                  onTap: () {
                                    showMultiFilterDialog(
                                      title: "Name",
                                      options: getUniqueValues('name'),
                                      selectedValues: selectedName,
                                    );
                                  },
                                  child: Icon(
                                    Icons.filter_list,
                                    size: 18,
                                    color: selectedName.isNotEmpty
                                        ? Colors.blue
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              children: [
                                const Text("Office Name",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),),
                                const SizedBox(width: 5),
                                InkWell(
                                  onTap: () {
                                    showMultiFilterDialog(
                                      title: "Office Name",
                                      options: getUniqueValues('office_name'),
                                      selectedValues: selectedOffice,
                                    );
                                  },
                                  child: Icon(
                                    Icons.filter_list,
                                    size: 18,
                                    color: selectedOffice.isNotEmpty
                                        ? Colors.blue
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              children: [
                                const Text("User Type",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),),
                                const SizedBox(width: 5),
                                InkWell(
                                  onTap: () {
                                    showMultiFilterDialog(
                                      title: "User Type",
                                      options: getUniqueValues('department'),
                                      selectedValues: selectedDepartment1,
                                    );
                                  },
                                  child: Icon(
                                    Icons.filter_list,
                                    size: 18,
                                    color: selectedDepartment1.isNotEmpty
                                        ? Colors.blue
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              children: [
                                const Text("Status",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),),
                                const SizedBox(width: 5),
                                InkWell(
                                  onTap: () {
                                    showMultiFilterDialog(
                                      title: "Status",
                                      options: getUniqueValues('status'),
                                      selectedValues: selectedStatus,
                                    );
                                  },
                                  child: Icon(
                                    Icons.filter_list,
                                    size: 18,
                                    color: selectedStatus.isNotEmpty
                                        ? Colors.blue
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const DataColumn(label: Text("Shift Time",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                          const DataColumn(label: Text("Punch In Time",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                          const DataColumn(label: Text("Punch In Remark",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                          const DataColumn(label: Text("Punch In Image",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                          const DataColumn(label: Text("Punch Out Time",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                          const DataColumn(label: Text("Punch Out Remark",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                          const DataColumn(label: Text("Punch Out Image",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),

                          // DataColumn(label: Text("Late")),
                          const DataColumn(label: Text("Working Hours",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 15,fontFamily: 'serif'),)),
                          // DataColumn(label: Text("Break Min")),
                        ],

                        rows: filteredRecords.map((e) {
                          DateTime? punchIn = e['punch_in_time'] != null
                              ? DateTime.parse(e['punch_in_time'])
                              : null;

                          DateTime? punchOut = e['punch_out_time'] != null
                              ? DateTime.parse(e['punch_out_time'])
                              : null;

                          String working = "-";
                          if (punchIn != null && punchOut != null) {
                            final diff = punchOut.difference(punchIn);
                            working =
                                "${diff.inHours}h ${diff.inMinutes % 60}m";
                          }

                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.location_on,
                                        color:   Color(0xff2563EB),
                                      ),
                                      onPressed: () async {
                                        final id = e['id'];
                                        final res = await http.get(
                                          Uri.parse(
                                            "http://15.206.209.30/attendance/fetch_current_location.php?attendance_id=$id",
                                          ),
                                        );
                                        print(res);
                                        final json = jsonDecode(res.body);
                                        print(json);
                                        if (json['status']) {
                                          double lat = double.parse(
                                            json['data']['latitude'],
                                          );
                                          double lng = double.parse(
                                            json['data']['longitude'],
                                          );

                                          openGoogleMap(lat, lng);
                                        }
                                      },
                                    ),
                                    e['status'] == 'HOLYDAY'
                                        ? IconButton(
                                            onPressed: () async {
                                              print(
                                                "Attendance id: ${e['id']}",
                                              );

                                              // 1. API Call
                                              // await getAttendanceDetails(e['id']);

                                              // 2. Open Dialog
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  DateTime? selectedDate;

                                                  return AlertDialog(
                                                    title: const Text(
                                                      "Update Weekly Off",
                                                    ),
                                                    content: StatefulBuilder(
                                                      builder: (context, setState) {
                                                        return Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            ElevatedButton.icon(
                                                              onPressed: () async {
                                                                DateTime?
                                                                picked = await showDatePicker(
                                                                  context:
                                                                      context,
                                                                  initialDate:
                                                                      DateTime.now(),
                                                                  firstDate:
                                                                  DateTime.now(),
                                                                  lastDate:
                                                                      DateTime(
                                                                        2050,
                                                                      ),
                                                                );

                                                                if (picked !=
                                                                    null) {
                                                                  setState(() {
                                                                    selectedDate =
                                                                        picked;
                                                                  });
                                                                }
                                                              },
                                                              icon: const Icon(
                                                                Icons
                                                                    .calendar_month,
                                                                color:   Color(0xff2563EB),
                                                              ),
                                                              label: Text(
                                                                selectedDate ==
                                                                        null
                                                                    ? "Select Date"
                                                                    : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                            ),
                                                        child: const Text(
                                                          "Cancel",
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () async {
                                                          if (selectedDate == null) return;

                                                          bool success = await updateHoliday(
                                                            id: e['id'].toString(),
                                                            date: selectedDate!,
                                                          );

                                                          if (success) {
                                                            Navigator.pop(context);

                                                            // Screen Refresh
                                                            await fetchAttendanceByDate(); // <-- Apni API method call karein

                                                            setState(() {});

                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(
                                                                content: Text("Weekly Off updated successfully"),
                                                                backgroundColor: Colors.green,
                                                              ),
                                                            );
                                                          } else {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(
                                                                content: Text("Update failed"),
                                                                backgroundColor: Colors.red,
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        child: const Text(
                                                          "Update",
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.edit,
                                              color:   Colors.redAccent,
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color:   Colors.black,
                                      ),
                                      onPressed: () async {
                                        final attendanceId = e['id'] ?? '-';

                                        bool confirm =
                                            await showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: Text("Confirm Delete"),
                                                  content: Text(
                                                    "Are you sure you want to delete this attendance?",
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(
                                                          context,
                                                          false,
                                                        ); // ❌ Cancel
                                                      },
                                                      child: Text("Cancel"),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.pop(
                                                          context,
                                                          true,
                                                        ); // ✅ Confirm
                                                      },
                                                      child: Text("Delete"),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ) ??
                                            false;

                                        // ❌ If user cancels → stop
                                        if (!confirm) return;

                                        print(attendanceId);

                                        final res = await http.post(
                                          Uri.parse(
                                            "http://15.206.209.30/attendance/delete_attendance_by_id.php",
                                          ),
                                          body: {"attendance_id": attendanceId},
                                        );

                                        if (res.statusCode == 200) {
                                          final data = jsonDecode(res.body);

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Attendance deleted (ID: $attendanceId)",
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );

                                          // 🔙 Go back & notify previous screen
                                          Navigator.pop(context, true);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              DataCell(
                                Text(
                                  e['created_at'] != null
                                      ? DateFormat('dd-MM-yyyy').format(
                                          DateTime.parse(e['created_at']),
                                        )
                                      : '-',
                                ),
                              ),
                              DataCell(Text(e['userid'] ?? '-')),
                              // DataCell(Text(e['id'] ?? '-')),
                              DataCell(Text(e['name'] ?? '-')),
                              DataCell(Text(e['office_name'] ?? '-')),
                              DataCell(Text(e['department'] ?? '-')),
                              DataCell(
                                Text(
                                  e['status'] == 'HOLYDAY'
                                      ? 'WO'
                                      : (e['status'] ?? '-'),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    Text(
                                      e['shift_start'] != null
                                          ? DateFormat('hh:mm a').format(
                                              DateFormat(
                                                'HH:mm:ss',
                                              ).parse(e['shift_start']),
                                            )
                                          : '-',
                                    ),
                                    const Text(" - "),
                                    Text(
                                      e['shift_end'] != null
                                          ? DateFormat('hh:mm a').format(
                                              DateFormat(
                                                'HH:mm:ss',
                                              ).parse(e['shift_end']),
                                            )
                                          : '-',
                                    ),
                                  ],
                                ),
                              ),

                              DataCell(
                                Text(
                                  punchIn != null
                                      ? DateFormat('hh:mm a').format(punchIn)
                                      : '-',
                                ),
                              ),
                              DataCell(Text(e['punch_in_remark'] ?? '-')),
                              DataCell(
                                e['punch_in_image'] != null &&
                                        e['punch_in_image']
                                            .toString()
                                            .isNotEmpty
                                    ? InkWell(
                                        onTap: () {
                                          _showImageDialog(
                                            context,
                                            e['punch_in_image'],
                                          );
                                        },
                                        child: Image.network(
                                          e['punch_in_image'],
                                          width: 100,
                                          height: 200,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.broken_image),
                                        ),
                                      )
                                    : const Icon(Icons.image_not_supported),
                              ),
                              DataCell(
                                Text(
                                  punchOut != null
                                      ? DateFormat('hh:mm a').format(punchOut)
                                      : '-',
                                ),
                              ),
                              DataCell(Text(e['punch_out_remark'] ?? '-')),
                              DataCell(
                                e['punch_out_image'] != null &&
                                        e['punch_out_image']
                                            .toString()
                                            .isNotEmpty
                                    ? InkWell(
                                        onTap: () {
                                          _showImageDialog(
                                            context,
                                            e['punch_out_image'],
                                          );
                                        },
                                        child: Image.network(
                                          e['punch_out_image'],
                                          width: 100,
                                          height: 200,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.broken_image),
                                        ),
                                      )
                                    : const Icon(Icons.image_not_supported),
                              ),

                              // DataCell(Text(e['late'] ?? '-')),
                              DataCell(Text(working)),
                              // DataCell(Text(
                              //     e['total_break_minutes']
                              //         ?.toString() ??
                              //         '-')),
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
  }
}
