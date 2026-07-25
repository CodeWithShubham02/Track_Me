import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceScreen extends StatefulWidget {
  final String cid;
  final String uid;


  const AttendanceScreen({
    super.key,
    required this.cid,
    required this.uid,

  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Map<String, dynamic>? attendanceData;
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchAttendanceByDate(selectedDate);
  }

  // 🔹 Date Key (YYYY-MM-DD)
  String dateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }


  // 🔹 Fetch Attendance
  Future<void> fetchAttendanceByDate(DateTime date) async {
    setState(() => isLoading = true);
    print("Selected Date: $selectedDate");
    print("cid : ${widget.cid}");
    print("uid : ${widget.uid}");
    final response = await http.post(
      Uri.parse("http://15.206.209.30/attendance/fetch_attendance_by_id.php"),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "cid": widget.cid,
        "uid": widget.uid,
        "punch_in_time": dateKey(date),
      },
    );
    print("-------------------");
    print("Api res : $response");
    print(response.body);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData['status'] == true) {
        attendanceData = jsonData['data'];
      } else {
        attendanceData = {};
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonData['message'] ?? 'No data')),
        );
      }


      setState(() {
        attendanceData = jsonData['status'] == true
            ? jsonData['data']
            : {};
        isLoading = false;
      });
    } else {
      setState(() {
        attendanceData = {};
        isLoading = false;
      });
    }
  }


  // 🔹 Time Formatter
  String formatTime(String? time) {
    if (time == null || time.isEmpty) return "-";
    final dt = DateTime.parse(time);
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }


  // 🔹 Working Hours
  String workingHours() {
    if (attendanceData?['punchIn']?['time'] == null ||
        attendanceData?['punchOut']?['time'] == null) return "-";

    final inTime =
    DateTime.parse(attendanceData!['punchIn']['time']);
    final outTime =
    DateTime.parse(attendanceData!['punchOut']['time']);

    final diff = outTime.difference(inTime);
    return "${diff.inHours}h ${diff.inMinutes % 60}m";
  }


  // 🔹 URL Link
  Widget linkText(String? url) {
    if (url == null || url.trim().isEmpty) {
      return const Text("-");
    }

    return InkWell(
      onTap: () async {
        try {
          final uri = Uri.parse(url);

          // 👇 direct launch (canLaunchUrl unreliable hota hai)
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );

          if (!launched) {
            debugPrint("❌ Could not launch URL: $url");
          }
        } catch (e) {
          debugPrint("❌ Invalid URL: $url | Error: $e");
        }
      },
      child: const Text(
        "View",
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }


  // 🔹 Table Row
  DataRow row(String label, Widget value) {
    return DataRow(cells: [
      DataCell(Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600))),
      DataCell(value),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          "Attendance (${dateKey(selectedDate)})",
          style: const TextStyle(fontSize: 16,color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // 🔥 icon color
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month,color: Colors.white,),
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2023),
                lastDate:DateTime.now().add(const Duration(days: 7)),
              );

              if (pickedDate != null) {
                selectedDate = pickedDate;
                fetchAttendanceByDate(pickedDate);
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : attendanceData == null || attendanceData!.isEmpty
          ? const Center(child: Text("No attendance found"))
          : SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 1,horizontal: 10),
            child: SingleChildScrollView(
              child: Container(
                height: 550,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DataTableTheme(
                  data: DataTableThemeData(
                    headingRowColor: MaterialStateProperty.all(
                        Colors.grey.shade200),
                    dividerThickness: 2,
                  ),
                  child: DataTable(
                    columnSpacing: 40,
                    columns: const [
                      DataColumn(label: Text("Field")),
                      DataColumn(label: Text("Value")),
                    ],
                    rows: [
                      row("Punch In",
                          Text(formatTime(attendanceData?['punchIn']?['time']))),

                      row("Punch Out",
                          Text(formatTime(attendanceData?['punchOut']?['time']))),

                      row("Punch In Remark",
                          Text(attendanceData?['punchIn']?['remark']?.toString() ?? "-")),

                      row("Punch Out Remark",
                          Text(attendanceData?['punchOut']?['remark']?.toString() ?? "-")),

                      row("Punch In Image",
                          linkText(attendanceData?['punchIn']?['image'])),

                      row("Punch Out Image",
                          linkText(attendanceData?['punchOut']?['image'])),

                      // row("currentLat",
                      //     Text(attendanceData?['currentLat']?.toString() ?? "-")),
                      //
                      // row("currentLng",
                      //     Text(attendanceData?['currentLng']?.toString() ?? "-")),

                      row("Shift Start",
                          Text(attendanceData?['shiftStart']?.toString() ?? "-")),

                      row("Shift End",
                          Text(attendanceData?['shiftEnd']?.toString() ?? "-")),
                      row("Late Status",
                          Text(attendanceData?['late'] ?? '-')),

                      row(
                        "Status",
                        Text(
                          attendanceData?['status']?.toString() ?? "-",
                          style: TextStyle(
                            color: attendanceData?['status'] == 'Present'
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // row("Working Hours", Text(workingHours())),
                      // row("Total break Time", Text(attendanceData?['totalBreakMinutes']?.toString() ?? "-")),
                    ],
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
