class LocationHistoryModel {
  final int id;
  final int attendanceId;
  final double latitude;     // 🔥 double
  final double longitude;    // 🔥 double
  final String createdAt;

  LocationHistoryModel({
    required this.id,
    required this.attendanceId,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  factory LocationHistoryModel.fromJson(Map<String, dynamic> json) {
    return LocationHistoryModel(
      id: json['id'],
      attendanceId: json['attendance_id'],
      latitude: (json['latitude'] as num).toDouble(),   // 🔥 FIX
      longitude: (json['longitude'] as num).toDouble(), // 🔥 FIX
      createdAt: json['created_at'],
    );
  }
}