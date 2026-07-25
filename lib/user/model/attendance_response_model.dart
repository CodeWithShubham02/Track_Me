import 'attendance_record_model.dart';

class AttendanceResponse {
  final bool status;
  final AttendanceSummary summary;
  final List<AttendanceRecord> data;

  AttendanceResponse({
    required this.status,
    required this.summary,
    required this.data,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      status: json['status'] ?? false,
      summary: AttendanceSummary.fromJson(json['summary'] ?? {}),
      data: (json['data'] as List? ?? [])
          .map((e) => AttendanceRecord.fromJson(e))
          .toList(),
    );
  }
}

class AttendanceSummary {
  final int total;
  final int present;
  final int absent;

  AttendanceSummary({
    required this.total,
    required this.present,
    required this.absent,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      total: json['total'] ?? 0,
      present: json['present'] ?? 0,
      absent: json['absent'] ?? 0,
    );
  }
}
