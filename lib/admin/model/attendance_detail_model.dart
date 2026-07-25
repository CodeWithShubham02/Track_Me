class AttendanceMultiModel {
  final int totalPunches;
  final String netWorkingHours;
  final List<PunchData> punches;

  AttendanceMultiModel({
    required this.totalPunches,
    required this.netWorkingHours,
    required this.punches,
  });

  factory AttendanceMultiModel.fromJson(Map<String, dynamic> json) {
    return AttendanceMultiModel(
      totalPunches: json['summary']['total_punches'],
      netWorkingHours: json['summary']['net_working_hours'],
      punches: (json['data'] as List)
          .map((e) => PunchData.fromJson(e))
          .toList(),
    );
  }
}

class PunchData {
  final String punchIn;
  final String punchOut;
  final String punchInRemark;
  final String punchOutRemark;
  final String punchInImage;
  final String punchOutImage;
  final int total_break_minutes;

  PunchData({
    required this.punchIn,
    required this.punchOut,
    required this.punchInRemark,
    required this.punchOutRemark,
    required this.punchInImage,
    required this.punchOutImage,
    required this.total_break_minutes,
  });

  factory PunchData.fromJson(Map<String, dynamic> json) {
    return PunchData(
      punchIn: json['punch_in_time'] ?? '',
      punchOut: json['punch_out_time'] ?? '',
      punchInRemark: json['punch_in_remark'] ?? '',
      punchOutRemark: json['punch_out_remark'] ?? '',
      punchInImage: json['punch_in_image'] ?? '',
      punchOutImage: json['punch_out_image'] ?? '',
      total_break_minutes: json['total_break_minutes'] ?? '',
    );
  }
}
