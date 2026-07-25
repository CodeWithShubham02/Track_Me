class ShiftModel {
  final String shiftId;
  final String shiftStart;
  final String shiftEnd;

  ShiftModel({
    required this.shiftId,
    required this.shiftStart,
    required this.shiftEnd,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      shiftId: json['shift_id'].toString(),
      shiftStart: json['shift_start'],
      shiftEnd: json['shift_end'],
    );
  }
}
