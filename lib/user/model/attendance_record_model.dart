class AttendanceRecord {
  final String name;
  final String department;
  final String officeName;
  final String status;
  final String shiftStart;
  final String shiftEnd;
  final int workingMinutes;
  final int totalBreakMinutes;
  final PunchData punchIn;
  final PunchData punchOut;
  final double? currentLat;
  final double? currentLng;

  AttendanceRecord({
    required this.name,
    required this.department,
    required this.officeName,
    required this.status,
    required this.shiftStart,
    required this.shiftEnd,
    required this.workingMinutes,
    required this.totalBreakMinutes,
    required this.punchIn,
    required this.punchOut,
    this.currentLat,
    this.currentLng,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      name: json['name'] ?? "-",
      department: json['department'] ?? "-",
      officeName: json['office_name'] ?? "-",
      status: json['status'] ?? "-",
      shiftStart: json['shift_start'] ?? "-",
      shiftEnd: json['shift_end'] ?? "-",
      workingMinutes: int.tryParse(
          json['working_minutes']?.toString() ?? "0") ??
          0,
      totalBreakMinutes: int.tryParse(
          json['total_break_minutes']?.toString() ?? "0") ??
          0,
      punchIn: PunchData.fromJson(
        json['punch_in_time'],
        json['punch_in_remark'],
        json['punch_in_image'],
      ),
      punchOut: PunchData.fromJson(
        json['punch_out_time'],
        json['punch_out_remark'],
        json['punch_out_image'],
      ),
      currentLat:
      double.tryParse(json['punch_in_lat']?.toString() ?? ""),
      currentLng:
      double.tryParse(json['punch_in_lng']?.toString() ?? ""),
    );
  }

  /// 🔑 UI expects Map<String, dynamic>
  Map<String, dynamic> toUiMap() {
    return {
      "name": name,
      "department": department,
      "officeName": officeName,
      "status": status,
      "shiftStart": shiftStart,
      "shiftEnd": shiftEnd,
      "workingMinutes": workingMinutes,
      "totalBreakMinutes": totalBreakMinutes,
      "punchIn": punchIn.toMap(),
      "punchOut": punchOut.toMap(),
      "currentLat": currentLat,
      "currentLng": currentLng,
    };
  }
}

class PunchData {
  final String? time;
  final String? remark;
  final String? image;

  PunchData({this.time, this.remark, this.image});

  factory PunchData.fromJson(
      dynamic time,
      dynamic remark,
      dynamic image,
      ) {
    return PunchData(
      time: time,
      remark: remark,
      image: image,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "time": time,
      "remark": remark,
      "image": image,
    };
  }
}
