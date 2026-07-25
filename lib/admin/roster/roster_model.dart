class RosterModel {

  String cid;
  String uid;
  String userType;
  String officeName;
  String status;
  String rosterDate;
  String shiftStart;
  String shiftEnd;

  RosterModel({
    required this.cid,
    required this.uid,
    required this.userType,
    required this.officeName,
    required this.status,
    required this.rosterDate,
    required this.shiftStart,
    required this.shiftEnd,
  });

  Map<String,dynamic> toJson(){

    return{

      "cid":cid,
      "uid":uid,
      "user_type":userType,
      "office_name":officeName,
      "status":status,
      "roster_date":rosterDate,
      "shift_start":shiftStart,
      "shift_end":shiftEnd

    };

  }

}