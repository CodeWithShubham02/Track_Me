class UserModel {
  final String uid;
  final String cid;
  final String userid;
  final String password;
  final String userToken;
  final String userImg;
  final String imeiNo;
  final String fullName;
  final String lastName;
  final String middleName;
  final String cityName;
  final String pinCode;
  final String districtName;
  final String reportingPosition;
  final String userEmail;
  final String userPhone;
  final String gender;
  final String fullAddress;
  final String branchId;
  final String branchName;
  final String branchDistance;
  final String branchLat;
  final String branchLong;
  final String departmentId;
  final String departmentName;
  final String shiftId;
  final String shiftStart;
  final String shiftEnd;
  final String dateOfJoining;
  final String lastworkingdate;
  final String status;
  final String role;
  final String createdAt;
  final String updatedAt;

  UserModel({
    required this.uid,
    required this.cid,
    required this.userid,
    required this.password,
    required this.userToken,
    required this.userImg,
    required this.imeiNo,
    required this.fullName,
    required this.lastName,
    required this.middleName,
    required this.cityName,
    required this.pinCode,
    required this.districtName,
    required this.reportingPosition,
    required this.userEmail,
    required this.userPhone,
    required this.gender,
    required this.fullAddress,
    required this.branchId,
    required this.branchName,
    required this.branchDistance,
    required this.branchLat,
    required this.branchLong,
    required this.departmentId,
    required this.departmentName,
    required this.shiftId,
    required this.shiftStart,
    required this.shiftEnd,
    required this.dateOfJoining,
    required this.lastworkingdate,
    required this.status,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });
  Map<String, dynamic> toJson() {
    return {
      "uid": uid,
      "cid": cid,
      "userid": userid,
      "password": password,
      "userToken": userToken,
      "userImg": userImg,
      "imeiNo": imeiNo,
      "fullName": fullName,
      "lastName": lastName,
      "middleName": middleName,
      "cityName": cityName,
      "pinCode": pinCode,
      "districtName": districtName,
      "reportingPosition": reportingPosition,
      "userEmail": userEmail,
      "userPhone": userPhone,
      "gender": gender,
      "fullAddress": fullAddress,
      "branchId": branchId,
      "branchName": branchName,
      "branchDistance": branchDistance,
      "branchLat": branchLat,
      "branchLong": branchLong,
      "departmentId": departmentId,
      "departmentName": departmentName,
      "shiftId": shiftId,
      "shiftStart": shiftStart,
      "shiftEnd": shiftEnd,
      "dateOfJoining": dateOfJoining,
      "lastworkingdate": lastworkingdate,
      "status": status,
      "role": role,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      cid: json['cid'] ?? '',
      userid: json['userid'] ?? '',
      password: json['password'] ?? '',

      userToken: json['userToken'] ?? json['user_token'] ?? '',
      userImg: json['userImg'] ?? json['user_img'] ?? '',
      imeiNo: json['imeiNo'] ?? json['imei_no'] ?? '',

      fullName: json['fullName'] ?? json['full_name'] ?? '', // ✅ BOTH
      lastName: json['lastName'] ?? json['last_name'] ?? '',
      middleName: json['middleName'] ?? json['middle_name'] ?? '',
      cityName: json['cityName'] ?? json['city_name'] ?? '',
      pinCode: json['pinCode'] ?? json['pin_code'] ?? '',
      districtName: json['districtName'] ?? json['district_name'] ?? '',
      reportingPosition: json['reportingPosition'] ?? json['reporting_position'] ?? '',

      userEmail: json['userEmail'] ?? json['user_email'] ?? '',
      userPhone: json['userPhone'] ?? json['user_phone'] ?? '',
      gender: json['gender'] ?? '',
      fullAddress: json['fullAddress'] ?? json['full_address'] ?? '',

      branchId: json['branchId'] ?? json['branch_id'] ?? '',
      branchName: json['branchName'] ?? json['branch_name'] ?? '', // ✅ BOTH
      branchDistance: json['branchDistance'] ?? json['branch_distance'] ?? '',
      branchLat: json['branchLat'] ?? json['branch_lat'] ?? '',
      branchLong: json['branchLong'] ?? json['branch_long'] ?? '',

      departmentId: json['departmentId'] ?? json['department_id'] ?? '',
      departmentName: json['departmentName'] ?? json['department_name'] ?? '',

      shiftId: json['shiftId'] ?? json['shift_id'] ?? '',
      shiftStart: json['shiftStart'] ?? json['shift_start'] ?? '', // ✅ BOTH
      shiftEnd: json['shiftEnd'] ?? json['shift_end'] ?? '',

      dateOfJoining: json['dateOfJoining'] ?? json['date_of_joining'] ?? '',
      lastworkingdate: json['last_working_date'] ?? json['last_working_date'] ?? '',
      status: json['status'] ?? '',
      role: json['role'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
  /// 🔥 Convert Map → object

}
