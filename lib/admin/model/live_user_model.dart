class LiveUser {
  final String uid;
  final String name;
  final String status;
  final double? latitude;
  final double? longitude;
  final String created_at;

  LiveUser({
    required this.uid,
    required this.name,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.created_at,
  });

  factory LiveUser.fromJson(Map<String, dynamic> json) {
    return LiveUser(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      created_at: json['created_at'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }
}