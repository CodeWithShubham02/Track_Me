class BranchModel {
  final String id;
  final String branchName;
  final String distance;
  final String lat;
  final String long;

  BranchModel({
    required this.id,
    required this.branchName,
    required this.distance,
    required this.lat,
    required this.long,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'].toString(),
      branchName: json['branch_name'],
      distance: json['distance'],
      lat: json['branch_lat'] ?? '',
      long: json['branch_long'] ?? '',
    );
  }
}
