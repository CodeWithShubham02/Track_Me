import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../api_urls.dart';
import '../controller/shift_controller.dart';
import '../model/shift_model.dart';

class RosterEditScreen extends StatefulWidget {
  final String cid;

  const RosterEditScreen({super.key, required this.cid});

  @override
  State<RosterEditScreen> createState() => _RosterEditScreenState();
}

class _RosterEditScreenState extends State<RosterEditScreen> {
  static const String baseUrl =
      'https://trackme.joizone.com/attendance/get_roster.php';

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> rosterList = [];

  late DateTime weekStart;
  late DateTime weekEnd;

  @override
  void initState() {
    super.initState();
    loadShifts();
    // Current week: Monday to Sunday
    final now = DateTime.now();
    weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    weekEnd = weekStart.add(const Duration(days: 6));

    // Screen open hote hi API call
    fetchRoster();
  }

  String formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> fetchRoster() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'cid': widget.cid,
          'weekstart': formatDate(weekStart),
          'week': formatDate(weekEnd),
        },
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid API response');
      }

      if (decoded['status'] != true) {
        throw Exception(
          decoded['message']?.toString() ?? 'Roster fetch failed',
        );
      }

      final List<dynamic> data = decoded['data'] ?? [];

      final parsedList = data.map((item) {
        return Map<String, dynamic>.from(item as Map);
      }).toList();

      if (!mounted) return;

      setState(() {
        rosterList = parsedList;
        filteredRosterList = List.from(parsedList);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String formatDisplayDate(String? value) {
    if (value == null || value.isEmpty) return '-';

    try {
      final date = DateTime.parse(value);
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value;
    }
  }

  String formatTime(String? value) {
    if (value == null || value.isEmpty) return '-';

    try {
      final parts = value.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;

      return '${displayHour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return value;
    }
  }
  String? selectedEmployee;
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
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text("Roster Screen",style: TextStyle(color: Colors.white,fontSize: 18),),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: fetchRoster,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh roster',
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 12),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownSearch<String>(
                    items: rosterList
                        .map((roster) => roster['user_name']?.toString() ?? '')
                        .where((name) => name.trim().isNotEmpty)
                        .toSet()
                        .toList(),

                    selectedItem: selectedEmployee,

                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Search employee name...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        hintText: 'Select employee',
                        prefixIcon: const Icon(Icons.person_search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        selectedEmployee = value;
                        searchController.text = value;
                      });

                      searchRoster();
                    },
                  ),
                ),
                const SizedBox(width: 8),

              ],
            ),
          ),
          // Week details
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Week',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  '${formatDisplayDate(formatDate(weekStart))}'
                  ' - '
                  '${formatDisplayDate(formatDate(weekEnd))}',
                ),
                const SizedBox(height: 4),
                Text(
                  'Total roster: ${rosterList.length}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Expanded(child: _buildRosterBody()),
        ],
      ),
    );
  }
  final TextEditingController searchController =
  TextEditingController();

  List<Map<String, dynamic>> filteredRosterList = [];
  void searchRoster() {
    final query = searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredRosterList = List.from(rosterList);
      } else {
        filteredRosterList = rosterList.where((roster) {
          final name =
          (roster['user_name'] ?? '').toString().toLowerCase();

          return name == query;
        }).toList();
      }
    });
  }

  TimeOfDay parseTime(String time) {
    final parts = time.split(':');

    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
  String formatTime24(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:00';
  }
  Future<bool> updateUserRosterShift({
    required String uid,
    required String cid,
    required DateTime date,
    required String shiftStart,
    required String shiftEnd,
  }) async {
    try {
      final rosterDate =
          "${date.year.toString().padLeft(4, '0')}-"
          "${date.month.toString().padLeft(2, '0')}-"
          "${date.day.toString().padLeft(2, '0')}";

      final response = await http.post(
        Uri.parse(ApiUrls.updateUserRosterShift),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "uid": uid,
          "cid": cid,
          "roster_date": rosterDate,
          "shift_start": shiftStart,
          "shift_end": shiftEnd,
        }),
      );

      print("=================================");
      print("UPDATE USER SHIFT API");
      print("=================================");
      print("UID: $uid");
      print("CID: $cid");
      print("Date: $rosterDate");
      print("Start: $shiftStart");
      print("End: $shiftEnd");
      print("Status: ${response.statusCode}");
      print("Response: ${response.body}");
      print("=================================");

      if (response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        return true;
      }

      Get.snackbar(
        "Update Failed",
        data['message'] ?? "Unable to update shift",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      return false;
    } catch (e) {
      print("Update shift error: $e");

      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      return false;
    }
  }

  List<ShiftModel> shifts = [];
  ShiftModel? selectedShift;
  bool isLoadingShifts = false;
  final ShiftController controller = ShiftController();
  Future<void> loadShifts() async {
    setState(() {
      isLoadingShifts = true;
    });

    try {
      final data = await controller.fetchShifts(widget.cid);

      if (!mounted) return;

      setState(() {
        shifts = data;
        isLoadingShifts = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingShifts = false;
      });

      Get.snackbar(
        'Error',
        'Failed to load shifts: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  //-------------------------------
//------------update weekly off----------
  Future<bool> updateHoliday({
    required String id,
    required DateTime date,
  }) async {
    final response = await http.post(
      Uri.parse("https://trackme.joizone.com/attendance/updateHoliday.php"),
      body: {
        "id": id,
        "date": DateFormat('yyyy-MM-dd').format(date),
      },
    );

    print(response.body);

    final json = jsonDecode(response.body);
    return json["status"] == true;
  }


  Future<void> showEditShiftDialog(
      Map<String, dynamic> roster,
      ) async {
    // Dialog kholne se pehle shifts fetch karein.
    await loadShifts();

    if (!mounted) return;

    if (shifts.isEmpty) {
      Get.snackbar(
        'No Shifts',
        'Please add shifts before editing the roster.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    String currentStart =
        roster['shift_start']?.toString() ?? '09:00:00';

    String currentEnd =
        roster['shift_end']?.toString() ?? '18:00:00';

    // Roster ke current timing se matching shift find karein.
    ShiftModel? selectedShift;

    for (final shift in shifts) {
      final apiStart = shift.shiftStart.length >= 5
          ? shift.shiftStart.substring(0, 5)
          : shift.shiftStart;

      final apiEnd = shift.shiftEnd.length >= 5
          ? shift.shiftEnd.substring(0, 5)
          : shift.shiftEnd;

      final rosterStart = currentStart.length >= 5
          ? currentStart.substring(0, 5)
          : currentStart;

      final rosterEnd = currentEnd.length >= 5
          ? currentEnd.substring(0, 5)
          : currentEnd;

      if (apiStart == rosterStart && apiEnd == rosterEnd) {
        selectedShift = shift;
        break;
      }
    }

    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Shift'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoadingShifts)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else
                    DropdownButtonFormField<ShiftModel>(
                      value: selectedShift,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Shift',
                        prefixIcon: Icon(Icons.schedule),
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Choose a shift'),
                      items: shifts.map((shift) {
                        return DropdownMenuItem<ShiftModel>(
                          value: shift,
                          child: Text(
                            'SHIFT - '
                                '(${shift.shiftStart} - ${shift.shiftEnd})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: saving
                          ? null
                          : (shift) {
                        setDialogState(() {
                          selectedShift = shift;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a shift';
                        }
                        return null;
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving || selectedShift == null
                      ? null
                      : () async {
                    setDialogState(() {
                      saving = true;
                    });

                    final success =
                    await updateUserRosterShift(
                      uid: roster['uid'].toString(),
                      cid: widget.cid,
                      date: DateTime.parse(
                        roster['roster_date'].toString(),
                      ),
                      shiftStart: selectedShift!.shiftStart,
                      shiftEnd: selectedShift!.shiftEnd,
                    );

                    if (!mounted) return;

                    if (success) {
                      Navigator.pop(dialogContext);

                      Get.snackbar(
                        'Success',
                        'Shift updated successfully',
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );

                      await fetchRoster();
                    } else {
                      setDialogState(() {
                        saving = false;
                      });
                    }
                  },
                  child: saving
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRosterBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 45,
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: fetchRoster,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (rosterList.isEmpty) {
      return RefreshIndicator(
        onRefresh: fetchRoster,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 130),
            Icon(
              Icons.event_busy,
              size: 55,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Center(
              child: Text('No roster found for this week'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchRoster,
      child: filteredRosterList.isEmpty
          ? ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 130),
          Center(
            child: Text('No matching roster records found'),
          ),
        ],
      )
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(
              Colors.blue.shade700,
            ),
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            dataRowMinHeight: 55,
            dataRowMaxHeight: 65,
            columnSpacing: 22,
            horizontalMargin: 16,
            columns: const [
              DataColumn(label: Text('S.No.')),
              DataColumn(label: Text('Employee Name')),
              DataColumn(label: Text('User ID')),
              DataColumn(label: Text('UID')),
              DataColumn(label: Text('Roster Date')),
              DataColumn(label: Text('Shift Start')),
              DataColumn(label: Text('Shift End')),
              DataColumn(label: Text('WO Status')),
              // DataColumn(label: Text('A ID')),
              DataColumn(label: Text('Action')),
            ],
            rows: List.generate(
              filteredRosterList.length,
                  (index) {
                final roster = filteredRosterList[index];

                final userName =
                    roster['user_name']?.toString() ??
                        'Unknown User';

                final userId =
                    roster['userid']?.toString() ?? '-';

                final uid =
                    roster['uid']?.toString() ?? '-';

                final rosterDate =
                roster['roster_date']?.toString();

                final shiftStart =
                roster['shift_start']?.toString();

                final shiftEnd =
                roster['shift_end']?.toString();
                final woStatus =
                roster['holyday_status']?.toString()?? '-';

                final weeklyOff=woStatus=='HOLYDAY'?'WO':'-';
                final attendanceid =
                roster['attendance_id']?.toString()?? '-';

                return DataRow(
                  cells: [
                    DataCell(
                      Text('${index + 1}'),
                    ),

                    DataCell(
                      SizedBox(
                        width: 160,
                        child: Text(
                          userName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    DataCell(Text(userId)),
                    DataCell(Text(uid)),

                    DataCell(
                      Text(formatDisplayDate(rosterDate)),
                    ),

                    DataCell(
                      Text(formatTime(shiftStart)),
                    ),

                    DataCell(
                      Text(formatTime(shiftEnd)),
                    ),
                    DataCell(
                      Text(weeklyOff),
                    ),
                    // DataCell(
                    //   Text(attendanceid),
                    // ),
                    DataCell(
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              showEditShiftDialog(roster);
                            },
                            icon: const Icon(
                              Icons.watch_later_outlined,
                              size: 16,
                            ),
                            label: const Text('Edit Shift'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          SizedBox(width: 10,),
                          weeklyOff=='WO'?ElevatedButton.icon(
                            onPressed: () async {
                              print(
                                "Attendance id: ${attendanceid}",
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
                                                  firstDate:  DateTime.now().subtract(
                                                    Duration(days:  DateTime.now().weekday - 1),
                                                  ),
                                                  lastDate:  DateTime.now().add(
                                                    Duration(days: 7 -  DateTime.now().weekday),
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
                                            id: attendanceid.toString(),
                                            date: selectedDate!,
                                          );

                                          if (success) {
                                            Navigator.pop(context);
                                            await fetchRoster();
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
                              Icons.next_week_outlined,
                              size: 16,
                            ),
                            label: const Text('Edit WO'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                            ),
                          ):SizedBox.shrink(),
                        ],
                      ),

                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

}
