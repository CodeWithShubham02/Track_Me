import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';
import 'package:universal_html/html.dart' as html;

class MonthlyAttendanceScreen extends StatefulWidget {
  final String cid;

  const MonthlyAttendanceScreen({super.key, required this.cid});

  @override
  State<MonthlyAttendanceScreen> createState() =>
      _MonthlyAttendanceScreenState();
}

class _MonthlyAttendanceScreenState extends State<MonthlyAttendanceScreen> {
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredRecords = [];
  void filterByName(String query) {
    setState(() {
      currentPage = 0; // ✅ reset page
      filteredRecords = attendanceRecords.where((row) {
        final name = row['name']?.toString().toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  List<Map<String, dynamic>> attendanceRecords = [];
  bool isLoading = false;

  // ---------------- PICK DATE ----------------
  DateTimeRange? selectedRange;

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026),
      lastDate: DateTime.now().add(Duration(days: 6)),
      saveText: "Submit",
      initialDateRange: selectedRange,
    );

    if (picked != null) {
      setState(() {
        selectedRange = picked;
        fromDate = picked.start;
        toDate = picked.end;
      });

      fetchAttendance(); // yahi par call karo
    }
  }
  //--------Pagination-----------
  int currentPage = 0;
  final int rowsPerPage = 10;
  List<Map<String, dynamic>> get paginatedRecords {
    final start = currentPage * rowsPerPage;
    final end = start + rowsPerPage;

    return filteredRecords.sublist(
      start,
      end > filteredRecords.length ? filteredRecords.length : end,
    );
  }
  //---------------------------
  // ---------------- FETCH API ----------------
  Future<void> fetchAttendance() async {
    setState(() => isLoading = true);

    final url = Uri.parse(
        "http://15.206.209.30/attendance/fetch_attendance_range.php?cid=${widget.cid}&from_date=${DateFormat('yyyy-MM-dd').format(fromDate)}&to_date=${DateFormat('yyyy-MM-dd').format(toDate)}");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
      print("---------------------------------------------");
      print("---------------------------------------------");
      print(res);
      print("---------------------------------------------");
      print("---------------------------------------------");
        if (res['status'] == true) {
          setState(() {
            attendanceRecords = List<Map<String, dynamic>>.from(res['data'] ?? []).map((e) {
              // Convert all numeric fields to String safely
              return {
                'id': e['id']?.toString() ?? '-',
                'uid': e['uid']?.toString() ?? '-',
                'userid': e['userid']?.toString() ?? '-',
                'city_name': e['city_name']?.toString() ?? '-',
                'name': e['name']?.toString() ?? '-',
                'department': e['department']?.toString() ?? '-',
                'office_name': e['office_name']?.toString() ?? '-',
                'status': e['status']?.toString() ?? '-',
                'punch_in_time': e['punch_in_time']?.toString() ?? '-',
                'punch_in_lat': e['punch_in_lat']?.toString() ?? '-',
                'punch_in_lng': e['punch_in_lng']?.toString() ?? '-',
                'punch_out_time': e['punch_out_time']?.toString() ?? '-',
                'punch_out_lat': e['punch_out_lat']?.toString() ?? '-',
                'punch_out_lng': e['punch_out_lng']?.toString() ?? '-',
                'shift_start': e['shift_start']?.toString() ?? '-',
                'shift_end': e['shift_end']?.toString() ?? '-',
                'punch_in_image': e['punch_in_image']?.toString() ?? '-',
                'punch_out_image': e['punch_out_image']?.toString() ?? '-',
                'punch_in_remark': e['punch_in_remark']?.toString() ?? '-',
                'punch_out_remark': e['punch_out_remark']?.toString() ?? '-',
                'total_break_minutes': e['total_break_minutes']?.toString() ?? '-',
                'late': e['late']?.toString() ?? '-',
                'working_minutes': e['working_minutes']?.toString() ?? '-',
                'total_working_minutes': e['total_working_minutes']?.toString() ?? '-',
                'created_at': e['created_at']?.toString() ?? '-',
              };
            }).toList();
            filteredRecords = attendanceRecords;
            print("--------------------filteredRecords-------------------------");
            print("---------------------------------------------");
            print(filteredRecords);
            print("---------------------------------------------");
            print("---------------------------------------------");
          });
        } else {
          setState(() {
            attendanceRecords = [];
          });
          Get.snackbar("Error", res['message'] ?? "Failed to fetch data");
        }
      } else {
        Get.snackbar("Error", "Server error: ${response.statusCode}");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch data");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> downloadExcel() async {
    if (filteredRecords.isEmpty) {
      Get.snackbar("No Data", "No attendance data to export");
      return;
    }

    final excel = Excel.createExcel();
    // Create your sheet FIRST
    final Sheet sheet = excel['Attendance'];

// Then delete all other sheets
    for (var sheetName in List.from(excel.tables.keys)) {
      if (sheetName != 'Attendance') {
        excel.delete(sheetName);
      }
    }


    // 🟢 HEADER ROW
    sheet.appendRow([
      TextCellValue("Date"),
     // TextCellValue("UID"),
      TextCellValue("City"),
      TextCellValue("User Id"),
      TextCellValue("User Name"),
      TextCellValue("User Type"),
      TextCellValue("Office Name"),
      TextCellValue("Status"),
      TextCellValue("Late Marks"),
      TextCellValue("Working Hours"),
      TextCellValue("Punch In Date"),
      TextCellValue("Punch In Time"),
      TextCellValue("Punch In Image"),
      TextCellValue("Punch Out Date"),
      TextCellValue("Punch Out Time"),
      TextCellValue("Punch Out Image"),
      TextCellValue("Shift Time"),
      TextCellValue("Punch In Address"),
      TextCellValue("Punch Out Address"),
      TextCellValue("Punch In Remark"),
      TextCellValue("Punch Out Remark"),


    ]);

    // 🔵 DATA ROWS
    for (var row in filteredRecords) {

      if (row['punch_in_lat'] != null &&
          row['punch_in_lng'] != null) {

        final lat = double.tryParse(row['punch_in_lat'].toString());
        final lng = double.tryParse(row['punch_in_lng'].toString());

        if (lat != null && lng != null) {
          final address = await getAddressFromLatLng(lat, lng);
          row['punch_in_address'] = address;
        } else {
          row['punch_in_address'] = '';
        }

      } else {
        row['punch_in_address'] = '';
      }

      if (row['punch_out_lat'] != null &&
          row['punch_out_lng'] != null) {

        final lat = double.tryParse(row['punch_out_lat'].toString());
        final lng = double.tryParse(row['punch_out_lng'].toString());

        if (lat != null && lng != null) {
          final address = await getAddressFromLatLng(lat, lng);
          row['punch_out_address'] = address;
        } else {
          row['punch_out_address'] = '';
        }

      } else {
        row['punch_out_address'] = '';
      }

      sheet.appendRow([
        TextCellValue(
          (() {
            final value = row['created_at'];
            if (value == null || value == '-' || value.toString().isEmpty) {
              return '';
            }

            final parsed = DateTime.tryParse(value.toString());
            if (parsed == null) return '';

            return DateFormat('dd-MM-yyyy').format(parsed); // ✅ Only Date
          })(),
        ),
        //TextCellValue(row['uid']?.toString() ?? ''),
        TextCellValue(row['city_name']?.toString() ?? ''),
        TextCellValue(row['userid']?.toString() ?? ''),
        TextCellValue(row['name']?.toString() ?? ''),
        TextCellValue(row['department']?.toString() ?? ''),
        TextCellValue(row['office_name']?.toString() ?? ''),
        TextCellValue(
          row['status']?.toString() == 'HOLYDAY'
              ? 'WO'
              : (row['status']?.toString() ?? ''),
        ),
        TextCellValue(row['late']?.toString() ?? ''),
        TextCellValue(
          (() {
            final value = row['working_minutes'];

            if (value == null || value.toString().isEmpty) {
              return '';
            }

            final totalMinutes = int.tryParse(value.toString());
            if (totalMinutes == null) return '';

            final hours = totalMinutes ~/ 60;
            final minutes = totalMinutes % 60;

            return "${hours}h ${minutes}m";
          })(),
        ),
        TextCellValue(
          (() {
            final value = row['punch_in_time'];
            if (value == null || value == '-' || value.toString().isEmpty) {
              return '';
            }

            final parsed = DateTime.tryParse(value.toString());
            if (parsed == null) return '';

            return DateFormat('dd-MM-yyyy').format(parsed); // ✅ Only Date
          })(),
        ),
        TextCellValue(
          (() {
            final value = row['punch_in_time'];
            if (value == null || value == '-' || value.toString().isEmpty) {
              return '';
            }

            final parsed = DateTime.tryParse(value.toString());
            if (parsed == null) return '';

            return DateFormat('hh:mm:ss a').format(parsed); // ✅ Only Time
          })(),
        ),
        TextCellValue(row['punch_in_image']?.toString() ?? ''),
        TextCellValue(
          (() {
            final value = row['punch_out_time'];
            if (value == null || value == '-' || value.toString().isEmpty) {
              return '';
            }

            final parsed = DateTime.tryParse(value.toString());
            if (parsed == null) return '';

            return DateFormat('dd-MM-yyyy').format(parsed); // ✅ Only Date
          })(),
        ),
        TextCellValue(
          (() {
            final value = row['punch_out_time'];
            if (value == null || value == '-' || value.toString().isEmpty) {
              return '';
            }

            final parsed = DateTime.tryParse(value.toString());
            if (parsed == null) return '';

            return DateFormat('hh:mm:ss a').format(parsed); // ✅ Only Time
          })(),
        ),
        TextCellValue(row['punch_out_image']?.toString() ?? ''),
        TextCellValue(
          (() {
            final start = row['shift_start'];
            final end = row['shift_end'];

            if (start == null || end == null) return '';

            final parsedStart = DateTime.tryParse("2000-01-01 $start");
            final parsedEnd = DateTime.tryParse("2000-01-01 $end");

            if (parsedStart == null || parsedEnd == null) return '';

            final formattedStart = DateFormat('hh:mm a').format(parsedStart);
            final formattedEnd = DateFormat('hh:mm a').format(parsedEnd);

            return "$formattedStart - $formattedEnd";
          })(),
        ),
        TextCellValue(row['punch_in_address'] ?? ''),
        TextCellValue(row['punch_out_address'] ?? ''),
        //TextCellValue(row['punch_out_lat']?.toString() ?? ''),
        TextCellValue(row['punch_in_remark']?.toString() ?? ''),
        TextCellValue(row['punch_out_remark']?.toString() ?? ''),


      ]);
    }

    final fileBytes = excel.encode();
    if (fileBytes == null) return;

    final fileName =
        "attendance_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx";

    if (kIsWeb) {
      // 🌐 WEB DOWNLOAD
      final content = base64Encode(fileBytes);
      final anchor = html.AnchorElement(
        href:
        "data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$content",
      )
        ..setAttribute("download", fileName)
        ..click();

      Get.snackbar("Success", "Downloading Excel file...");
    } else {
      // 📱 ANDROID / IOS DOWNLOAD

      final directory = await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/$fileName";

      final file = File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      await Share.shareXFiles(
        [XFile(filePath)],
        text: "Attendance Report",
      );
    }
  }

  Map<String, String> addressCache = {};
  Future<String> getAddressFromLatLng(double lat, double lng) async {
    final key = "$lat,$lng";

    // ✅ cache check
    if (addressCache.containsKey(key)) {
      return addressCache[key]!;
    }

    try {
      String address;

      if (kIsWeb) {
        // 🌐 WEB → Google Geocoding API
        const googleApiKey = "AIzaSyBF7OlUqnsWTXRMiwtwEk9ieQ4YkzIhq18";

        final url =
            "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleApiKey";

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['status'] == 'OK') {
            address = data['results'][0]['formatted_address'];
          } else {
            address = "Address not found";
          }
        } else {
          address = "Address not found";
        }
      } else {
        // 📱 ANDROID / IOS → Native geocoding
        List<Placemark> placemarks =
        await placemarkFromCoordinates(lat, lng);

        final place = placemarks.first;
        address =
        "${place.name}, ${place.street}, ${place.subLocality}, "
            "${place.locality}, ${place.administrativeArea} "
            "${place.postalCode}";
      }

      addressCache[key] = address;
      return address;
    } catch (e) {
      return "Address not found";
    }
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
  Set<String> selectedName = {};
  Set<String> selectedStatus = {};
  Set<String> selectedDepartment = {};
  Set<String> selectedOffice = {};

  void applyFilters() {
    setState(() {
      currentPage = 0; // ✅ reset page

      filteredRecords = attendanceRecords.where((row) {
        final nameMatch = selectedName.isEmpty ||
            selectedName.contains(row['name']);
        final statusMatch = selectedStatus.isEmpty ||
            selectedStatus.contains(row['status']);
        final deptMatch = selectedDepartment.isEmpty ||
            selectedDepartment.contains(row['department']);
        final officeMatch = selectedOffice.isEmpty ||
            selectedOffice.contains(row['office_name']);

        return nameMatch && statusMatch && deptMatch && officeMatch;
      }).toList();
    });
  }
  List<String> getUniqueValues(String key) {
    return attendanceRecords
        .map((e) => e[key]?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }
  void showFilterDialog({
    required String title,
    required List<String> options,
    required Set<String> selectedValues,
  }) {
    Get.defaultDialog(
      title: "Filter $title",
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: options.map((value) {
                  return CheckboxListTile(
                    value: selectedValues.contains(value),
                    title: Text(
                      value == 'HOLYDAY' ? 'WO' : value,
                    ),
                    onChanged: (checked) {
                      if (checked == true) {
                        selectedValues.add(value);
                      } else {
                        selectedValues.remove(value);
                      }
                      applyFilters();
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                selectedValues.clear();
                applyFilters();
                Navigator.pop(context);
              },
              child: const Text("Reset Filter"),
            )
          ],
        ),
      ),
    );
  }
  DateTime? safeParse(String? value) {
    if (value == null || value.isEmpty || value == '-') return null;
    return DateTime.tryParse(value);
  }
  DateTime? safeTimeParse(String? value) {
    if (value == null || value.isEmpty || value == '-') return null;
    try {
      return DateFormat('HH:mm:ss').parse(value);
    } catch (e) {
      return null;
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
        title: const Text("Monthly Attendance",style: TextStyle(color: Colors.white,fontSize: 18),),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: pickDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: downloadExcel,
          ),

          // 🔍 Search
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : attendanceRecords.isEmpty
          ? const Center(child: Text("No attendance records found"))
          : ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.trackpad,
          },
        ),
        child: Column(
          children: [

            // ✅ TABLE AREA (SCROLLABLE)
            Expanded(
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(
                  dragDevices: {
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.touch,
                    PointerDeviceKind.trackpad,
                  },
                ),
                child: Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 2600),
                      child: Scrollbar(
                        controller: _verticalController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _verticalController,
                          child: DataTable(
                              headingRowColor:
                              MaterialStateColor.resolveWith(
                                      (states) => Colors.grey.shade200),
                              border: TableBorder.all(
                                  color: Colors.grey.shade400, width: 1),
                              columnSpacing: 24,
                              columns: [
                                //DataColumn(label: Text("Attendance ID")),
                                const DataColumn(label: Text("Date")),
                               // const DataColumn(label: Text("UID")),
                                const DataColumn(label: Text("City")),
                                const DataColumn(label: Text("Userid")),
                                DataColumn(
                                  label: Row(
                                    children: [
                                      const Text("Name"),
                                      IconButton(
                                        icon: const Icon(Icons.filter_list, size: 18),
                                        onPressed: () {
                                          showFilterDialog(
                                            title: "Name",
                                            options: getUniqueValues('name'),
                                            selectedValues: selectedName,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                DataColumn(
                                  label: Row(
                                    children: [
                                      const Text("User Type"),
                                      IconButton(
                                        icon: const Icon(Icons.filter_list, size: 18),
                                        onPressed: () {
                                          showFilterDialog(
                                            title: "User Type",
                                            options: getUniqueValues('department'),
                                            selectedValues: selectedDepartment,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                DataColumn(
                                  label: Row(
                                    children: [
                                      const Text("Office Name"),
                                      IconButton(
                                        icon: const Icon(Icons.filter_list, size: 18),
                                        onPressed: () {
                                          showFilterDialog(
                                            title: "Office",
                                            options: getUniqueValues('office_name'),
                                            selectedValues: selectedOffice,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                DataColumn(
                                  label: Row(
                                    children: [
                                      const Text("Status"),
                                      IconButton(
                                        icon: const Icon(Icons.filter_list, size: 18),
                                        onPressed: () {
                                          showFilterDialog(
                                            title: "Status",
                                            options: getUniqueValues('status'),
                                            selectedValues: selectedStatus,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const DataColumn(label: Text("Late Marks")),
                                const DataColumn(label: Text("Total Working Minutes")),
                                const DataColumn(label: Text("Punch In Date")),
                                const DataColumn(label: Text("Punch In Time")),
                                const DataColumn(label: Text("Punch In Address")),
                                const DataColumn(label: Text("Punch Out Date")),
                                const DataColumn(label: Text("Punch Out Time")),
                                const DataColumn(label: Text("Punch Out Address")),
                                const DataColumn(label: Text("Shift Time")),
                                const DataColumn(label: Text("Punch In Image")),
                                const DataColumn(label: Text("Punch Out Image")),
                                const DataColumn(label: Text("Punch In Remark")),
                                const DataColumn(label: Text("Punch Out Remark")),
                                //DataColumn(label: Text("Total Break")),


                              ],
                              rows: paginatedRecords.map((data) {
                                DateTime? parse(dynamic v) {
                                  if (v == null) return null;
                                  try {
                                    return DateTime.parse(v.toString());
                                  } catch (_) {
                                    return null;
                                  }
                                }

                                return DataRow(cells: [
                                  //DataCell(Text(data['id'] ?? '-')),
                                  DataCell(
                                    Text(
                                      safeParse(data['created_at']) != null
                                          ? DateFormat('dd-MM-yyyy')
                                          .format(safeParse(data['created_at'])!)
                                          : '-',
                                    ),
                                  ),
                                  //DataCell(Text(data['uid'] ?? '-')),
                                  DataCell(Text(data['city_name'] ?? '-')),
                                  DataCell(Text(data['userid'] ?? '-')),
                                  DataCell(Text(data['name'] ?? '-')),
                                  DataCell(Text(data['department'] ?? '-')),
                                  DataCell(Text(data['office_name'] ?? '-')),
                                  DataCell(
                                    Text(
                                      data['status'] == 'HOLYDAY'
                                          ? 'WO'
                                          : (data['status'] ?? '-'),
                                    ),
                                  ),
                                  DataCell(Text(data['late'] ?? '-')),
                                  DataCell(
                                    Text(
                                      data['total_working_minutes'] != null
                                          ? (() {
                                        int totalMinutes = int.parse(data['total_working_minutes'].toString());
                                        int hours = totalMinutes ~/ 60;
                                        int minutes = totalMinutes % 60;
                                        return "${hours}h ${minutes}m";
                                      })()
                                          : '-',
                                    ),
                                  ),

                                  DataCell(
                                    Text(
                                      safeParse(data['punch_in_time']) != null
                                          ? DateFormat('dd-MM-yyyy')
                                          .format(safeParse(data['punch_in_time'])!)
                                          : '-',
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      safeParse(data['punch_in_time']) != null
                                          ? DateFormat('hh:mm:ss a')
                                          .format(safeParse(data['punch_in_time'])!)
                                          : '-',
                                    ),
                                  ),
                                  DataCell(
                                    InkWell(
                                      onTap: () async {
                                        final lat = double.tryParse(data['punch_in_lat'] ?? '');
                                        final lng = double.tryParse(data['punch_in_lng'] ?? '');

                                        if (lat != null && lng != null) {
                                          String address = await getAddressFromLatLng(lat, lng);

                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: Text("Address"),
                                              content: Text(address),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text("View Address",
                                          style: TextStyle(color: Colors.blue)),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      safeParse(data['punch_out_time']) != null
                                          ? DateFormat('dd-MM-yyyy')
                                          .format(safeParse(data['punch_out_time'])!)
                                          : '-',
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      safeParse(data['punch_out_time']) != null
                                          ? DateFormat('hh:mm:ss a')
                                          .format(safeParse(data['punch_out_time'])!)
                                          : '-',
                                    ),
                                  ),
                                  DataCell(
                                    InkWell(
                                      onTap: () async {
                                        final lat = double.tryParse(data['punch_out_lat'] ?? '');
                                        final lng = double.tryParse(data['punch_out_lng'] ?? '');

                                        if (lat != null && lng != null) {
                                          String address = await getAddressFromLatLng(lat, lng);

                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: Text("Address"),
                                              content: Text(address),
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text("View Address",
                                          style: TextStyle(color: Colors.blue)),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        Text(
                                          safeTimeParse(data['shift_start']) != null
                                              ? DateFormat('hh:mm a')
                                              .format(safeTimeParse(data['shift_start'])!)
                                              : '-',
                                        ),
                                        const Text(" - "),
                                        Text(
                                          safeTimeParse(data['shift_end']) != null
                                              ? DateFormat('hh:mm a')
                                              .format(safeTimeParse(data['shift_end'])!)
                                              : '-',
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    data['punch_in_image'] != null &&
                                        data['punch_in_image'].toString().isNotEmpty
                                        ? InkWell(
                                      onTap: () {
                                        _showImageDialog(
                                          context,
                                          data['punch_in_image'],
                                        );
                                      },
                                      child: Image.network(
                                        data['punch_in_image'],
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image),
                                      ),
                                    )
                                        : const Icon(Icons.image_not_supported),
                                  ),
                                  DataCell(
                                    data['punch_out_image'] != null &&
                                        data['punch_out_image'].toString().isNotEmpty
                                        ? InkWell(
                                      onTap: () {
                                        _showImageDialog(
                                          context,
                                          data['punch_out_image'],
                                        );
                                      },
                                      child: Image.network(
                                        data['punch_out_image'],
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image),
                                      ),
                                    )
                                        : const Icon(Icons.image_not_supported),
                                  ),
                                  DataCell(Text(data['punch_in_remark'] ?? '-')),
                                  DataCell(Text(data['punch_out_remark'] ?? '-')),
                                  //DataCell(Text(data['total_break_minutes'] ?? '-')),

                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ✅ PAGINATION (OUTSIDE SCROLL → PERFECT CENTER)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
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

                  const SizedBox(width: 20),

                  Text(
                    "Page ${currentPage + 1} of ${((filteredRecords.length - 1) ~/ rowsPerPage) + 1}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(width: 20),

                  ElevatedButton(
                    onPressed:
                    (currentPage + 1) * rowsPerPage < filteredRecords.length
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
            ),
          ],
        ),
      ),


    );
  }
}
