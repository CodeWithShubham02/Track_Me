class TeamLeaderModel {
  String uid;
  String cid;
  String userId;
  String fullName;
  bool featureStatus;

  TeamLeaderModel({
    required this.uid,
    required this.cid,
    required this.userId,
    required this.fullName,
    required this.featureStatus,
  });

  factory TeamLeaderModel.fromJson(Map<String, dynamic> json) {
    return TeamLeaderModel(
      uid: json["uid"].toString(),
      cid: json["cid"].toString(),
      userId: json["userid"].toString(),
      fullName: json["full_name"].toString(),
      featureStatus: json["feature_status"].toString() == "1",
    );
  }
}