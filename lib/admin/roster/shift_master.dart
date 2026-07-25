class ShiftModel {
  final String shiftName;
  final String shiftStart;
  final String shiftEnd;

  ShiftModel({
    required this.shiftName,
    required this.shiftStart,
    required this.shiftEnd,
  });
}

final List<ShiftModel> shiftMaster = [
  ShiftModel(
    shiftName: "Morning",
    shiftStart: "07:00 AM",
    shiftEnd: "03:00 PM",
  ),
  ShiftModel(
    shiftName: "Evening",
    shiftStart: "03:00 PM",
    shiftEnd: "11:00 PM",
  ),
  ShiftModel(
    shiftName: "Night",
    shiftStart: "11:00 PM",
    shiftEnd: "07:00 AM",
  ),
];