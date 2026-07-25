class ChatModel {
  final String id;
  final String cid;
  final String uid;
  final String username;
  final String branchname;
  final String message;
  final String createdAt;

  ChatModel({
    required this.id,
    required this.cid,
    required this.uid,
    required this.username,
    required this.branchname,
    required this.message,
    required this.createdAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'],
      cid: json['cid'],
      uid: json['uid'],
      username: json['username'],
      branchname: json['branchname'],
      message: json['message'],
      createdAt: json['created_at'],
    );
  }
}