import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:joizone/admin/model/user_model.dart';
import '../controller/attendance_by_kiosk_controller.dart';
import '../controller/attendance_controller.dart';
import 'package:http/http.dart' as http;
class OfficeAttendanceScreen extends StatefulWidget {
  final String officeName;
final UserModel userModel;
  const OfficeAttendanceScreen({
    super.key,
    required this.officeName,
    required this.userModel
  });

  @override
  State<OfficeAttendanceScreen> createState() =>
      _OfficeAttendanceScreenState();
}

class _OfficeAttendanceScreenState extends State<OfficeAttendanceScreen> {
  bool isLoading = false;
  bool isSearching = false;

  DateTimeRange? selectedRange;

  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> attendanceRecords = [];
  List<Map<String, dynamic>> filteredRecords = [];

  /// 📅 PICK DATE RANGE
  Future<void> pickDateRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month - 2, now.day), // Previous 2 months
      lastDate: now.add(const Duration(days: 6)), // Next 6 days
      initialDateRange: selectedRange,
    );

    if (picked != null) {
      setState(() {
        selectedRange = picked;
        isLoading = true;
        attendanceRecords.clear();
        filteredRecords.clear();
      });

      await fetchAttendance(picked);
    }
  }

  /// 🌐 FETCH ATTENDANCE
  Future<void> fetchAttendance(DateTimeRange range) async {
    try {
      final from = DateFormat('yyyy-MM-dd').format(range.start);
      final to = DateFormat('yyyy-MM-dd').format(range.end);

      List<Map<String, dynamic>> allAttendance = [];

      // branchMap empty → officeName use karo
      if (widget.userModel.branchMap.isEmpty) {
        print(
          "branchMap empty → Fetching attendance for: ${widget.officeName}",
        );

        final records = await AttendanceController.fetchAttendance(
          officeName: widget.officeName,
          fromDate: from,
          toDate: to,
        );

        allAttendance.addAll(records);
      }

      // branchMap available → branch-wise attendance fetch karo
      else {
        for (final branch in widget.userModel.branchMap) {
          final branchName = branch['branch_name']?.toString();

          if (branchName == null || branchName.isEmpty) {
            continue;
          }

          print("Fetching attendance for branch: $branchName");

          final records = await AttendanceController.fetchAttendance(
            officeName: branchName,
            fromDate: from,
            toDate: to,
          );

          allAttendance.addAll(records);
        }
      }

      if (mounted) {
        setState(() {
          attendanceRecords = allAttendance;
          filteredRecords = List.from(allAttendance);
        });
      }

      print("Total attendance records: ${attendanceRecords.length}");
    } catch (e) {
      debugPrint("Attendance error: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// 🔍 FILTER BY NAME
  void filterByName(String query) {
    if (query.isEmpty) {
      filteredRecords = List.from(attendanceRecords);
    } else {
      filteredRecords = attendanceRecords.where((r) {
        final name = (r['name'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    }
    setState(() {});
  }

  /// ⏱ FORMAT TIME
  String formatTime(String? time) {
    if (time == null || time.isEmpty) return "-";
    return time;
  }

  /// 🖼 IMAGE VIEWER
  void showImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
  String formatTime12(String? time) {
    if (time == null || time.isEmpty || time == "-") return "-";

    try {
      final dt = DateTime.parse(time);
      int hour = dt.hour;
      String period = hour >= 12 ? "PM" : "AM";

      hour = hour % 12;
      if (hour == 0) hour = 12;

      return "${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period";
    } catch (e) {
      return "-";
    }
  }
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
  /// 📊 ATTENDANCE TABLE
  Widget buildAttendanceTable() {
    return Scrollbar(
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          thumbVisibility: true,
          trackVisibility: true,
          notificationPredicate: (notif) => notif.depth == 1,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 18,
              headingRowColor:
              MaterialStateProperty.all(Colors.blue.shade50),
              border: TableBorder.all(
                color: Colors.grey,
                width: 1,
              ),
              columns: const [
                DataColumn(label: Text("Action")),
                DataColumn(label: Text("Name")),
                DataColumn(label: Text("Status")),
                DataColumn(label: Text("Punch In")),
                DataColumn(label: Text("Punch Out")),
                // DataColumn(label: Text("Punch In Remark")),
                // DataColumn(label: Text("Punch Out Remark")),
                DataColumn(label: Text("In Img")),
                DataColumn(label: Text("Out Img")),
                DataColumn(label: Text("User Type")),
                DataColumn(label: Text("Shift")),
                DataColumn(label: Text("WO Date")),

              ],
              rows: filteredRecords.map((r) {
                return DataRow(
                  cells: [

                    /// ID

                    DataCell(
                      r['status'].toString().toUpperCase() == 'HOLYDAY'
                          ? IconButton(
                        onPressed: () {
                          print(r['id'].toString());
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
                                        id: r['id'].toString(),
                                        date: selectedDate!,
                                      );

                                      if (success) {
                                        Navigator.pop(context);
                                        await fetchAttendance(selectedRange!);
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
                        icon: const Icon(Icons.edit),
                      )
                          : const SizedBox(),
                    ),

                    /// Name
                    DataCell(Text(r['name']?.toString() ?? "-")),

                    /// Status
                    DataCell(
                      Text(
                        r['status']?.toString() ?? "-",
                        style: TextStyle(
                          color: r['status'] == "Present"
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    /// Punch In
                    DataCell(
                      Text(
                        formatTime(
                          r['punch_in_time']?.toString(),
                        ),
                      ),
                    ),

                    /// Punch Out
                    DataCell(
                      Text(
                        formatTime(
                          r['punch_out_time']?.toString(),
                        ),
                      ),
                    ),

                    /// Punch In Image
                    DataCell(
                      r['punch_in_image'] != null &&
                          r['punch_in_image'].toString().isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.image),
                        onPressed: () => showImage(
                          r['punch_in_image'].toString(),
                        ),
                      )
                          : const Text("-"),
                    ),

                    /// Punch Out Image
                    DataCell(
                      r['punch_out_image'] != null &&
                          r['punch_out_image'].toString().isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.image),
                        onPressed: () => showImage(
                          r['punch_out_image'].toString(),
                        ),
                      )
                          : const Text("-"),
                    ),

                    /// Department
                    DataCell(
                      Text(r['department']?.toString() ?? "-"),
                    ),

                    /// Shift
                    DataCell(
                      Text(
                        "${r['shift_start'] ?? "-"} - ${r['shift_end'] ?? "-"}",
                      ),
                    ),
                    DataCell(
                      Text(r['roster_date']?.toString() ?? "-"),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(
          color: Colors.white, // 🔥 icon color
        ),
        title: isSearching
            ? TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Search employee...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: filterByName,
        )
            : Text("Attendance - ${widget.officeName}",style: TextStyle(color: Colors.white,fontSize: 18),),
        actions: [
          IconButton(
            icon: Icon(
              isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (isSearching) {
                  searchController.clear();
                  filteredRecords =
                      List.from(attendanceRecords);
                }
                isSearching = !isSearching;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// 📅 DATE RANGE PICKER
            ElevatedButton.icon(
              onPressed: pickDateRange,
              icon: const Icon(Icons.date_range),
              label: Text(
                selectedRange == null
                    ? "Select Date Range"
                    : "${DateFormat('dd MMM').format(selectedRange!.start)}"
                    " - "
                    "${DateFormat('dd MMM').format(selectedRange!.end)}",
              ),
            ),

            const SizedBox(height: 12),

            /// ⏳ LOADING
            if (isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )

            /// 📭 EMPTY
            else if (filteredRecords.isEmpty)
              const Expanded(
                child: Center(child: Text("No attendance found")),
              )

            /// 📊 TABLE
            else
              Expanded(
                child: buildAttendanceTable(),
              ),
          ],
        ),
      ),
    );
  }
}
