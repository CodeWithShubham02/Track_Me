class AttendanceHistoryModel {
  final String attendanceId;
  final String date;
  final String fullname;
  final String? punchInTime;
  final String? punchOutTime;
  final String? branchLat;
  final String? branchLong;

  AttendanceHistoryModel({
    required this.attendanceId,
    required this.date,
    required this.fullname,
    this.punchInTime,
    this.punchOutTime,
    this.branchLat,
    this.branchLong,
  });

  factory AttendanceHistoryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryModel(
      attendanceId: json['attendance_id']?.toString() ?? '',
      date: json['date'] ?? '',
      fullname: json['fullname'] ?? '',
      punchInTime: json['punch_in_time'],
      punchOutTime: json['punch_out_time'],
      branchLat: json['branch_lat']?.toString(),
      branchLong: json['branch_long']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "attendance_id": attendanceId,
      "date": date,
      "fullname": fullname,
      "punch_in_time": punchInTime,
      "punch_out_time": punchOutTime,
      "branch_lat": branchLat,
      "branch_long": branchLong,
    };
  }
}