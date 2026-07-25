class AttendanceLocationModel {
  final String attendanceId;
  final String name;
  final String blatitude;
  final String blongitude;
  final String latitude;
  final String longitude;
  final String createdAt;

  AttendanceLocationModel({
    required this.attendanceId,
    required this.name,
    required this.blatitude,
    required this.blongitude,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  factory AttendanceLocationModel.fromJson(Map<String, dynamic> json) {
    return AttendanceLocationModel(
      attendanceId: json['attendance_id'].toString(),
      name: json['name'],
      blatitude: json['branch_lat'].toString(),
      blongitude: json['branch_long'].toString(),
      latitude: json['latitude'].toString(),
      longitude: json['longitude'].toString(),
      createdAt: json['created_at'],
    );
  }
}
