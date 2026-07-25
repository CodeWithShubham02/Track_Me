class HolidayAssignModel {
  final bool status;
  final String message;

  HolidayAssignModel({
    required this.status,
    required this.message,
  });

  factory HolidayAssignModel.fromJson(Map<String, dynamic> json) {
    return HolidayAssignModel(
      status: json['status'],
      message: json['message'],
    );
  }
}
