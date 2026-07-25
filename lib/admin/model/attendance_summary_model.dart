class AttendanceSummary {
  final int uid;
  final String name;
  final String userid;
  final String city_name;
  final String department;
  final String officeName;
  final String totalTimeFormate;
  final int totalDays;
  final int totalPresent;
  final int totalAbsent;
  final int totalLate;
  final int totalHalfDay;
  final int totalHoliday;
  final int missedPunchOut;
  final double totalHour;
  final String total_break_minutes;
  final int total_minutes;
  final int totalGps;
  final int totalInternet;
  final int totalOutside;
  final String fromDate;
  final String toDate;

  AttendanceSummary({
    required this.uid,
    required this.name,
    required this.userid,
    required this.city_name,
    required this.department,
    required this.totalTimeFormate,
    required this.officeName,
    required this.totalDays,
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalLate,
    required this.totalHalfDay,
    required this.totalHoliday,
    required this.missedPunchOut,
    required this.totalHour,
    required this.total_break_minutes,
    required this.total_minutes,
    required this.totalGps,
    required this.totalInternet,
    required this.totalOutside,
    required this.fromDate,
    required this.toDate,
  });

  /// 🔥 SAFE NUM → INT CONVERTER
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      uid: _toInt(json['uid']),
      userid: json['userid']?.toString() ?? '',
      city_name: json['city_name']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      totalTimeFormate: json['total_time_format']?.toString() ?? '',
      officeName: json['office_name']?.toString() ?? '',
      totalDays: _toInt(json['total_days']),
      totalPresent: _toInt(json['total_present']),
      totalAbsent: _toInt(json['total_absent']),
      totalLate: _toInt(json['total_late']),
      totalHalfDay: _toInt(json['total_halfday']),
      totalHoliday: _toInt(json['total_holiday']),
      missedPunchOut: _toInt(json['missed_punchOut']),
      totalHour: _toDouble(json['total_hour']),
      total_break_minutes: json['break_time_format']?.toString() ?? '',
      total_minutes: _toInt(json['total_minutes']),
      totalGps: _toInt(json['gps_auto_count']),
      totalInternet: _toInt(json['internet_auto_count']),
      totalOutside: _toInt(json['outside_radius_count']),
      fromDate: json['from_date']?.toString() ?? '',
      toDate: json['to_date']?.toString() ?? '',
    );
  }
}
