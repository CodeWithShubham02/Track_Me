class UserModel {
  final String uid;
  final String cid;
  final String userid;
  final String password;
  final String userToken;
  final String userImg;
  final String imeiNo;
  final String fullName;
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

  final String lastName;
  final String middleName;

  final String cityName;
  final String pinCode;
  final String districtName;
  final String reportingPosition;

  final List<Map<String, dynamic>> branchMap;

  UserModel({
    required this.uid,
    required this.cid,
    required this.userid,
    required this.password,
    required this.userToken,
    required this.userImg,
    required this.imeiNo,
    required this.fullName,
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

    required this.lastName,
    required this.middleName,

    required this.cityName,
    required this.pinCode,
    required this.districtName,
    required this.reportingPosition,

    required this.branchMap,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {

    final List<Map<String, dynamic>> branches =
    ((json['branch_map'] as List?) ?? [])
        .map<Map<String, dynamic>>(
          (e) => Map<String, dynamic>.from(e),
    )
        .toList();

    return UserModel(

      uid: json['uid']?.toString() ?? '',

      cid: json['cid']?.toString() ?? '',

      userid: json['userid']?.toString() ?? '',

      password: json['password']?.toString() ?? '',

      userToken: json['user_token']?.toString() ?? '',

      userImg: json['user_img']?.toString() ?? '',

      imeiNo: json['imei_no']?.toString() ?? '',

      // ⭐ FIXED
      fullName: json['full_name']?.toString() ?? '',

      // ⭐ FIXED
      userEmail: json['user_email']?.toString() ?? '',

      // ⭐ FIXED
      userPhone: json['user_phone']?.toString() ?? '',

      gender: json['gender']?.toString() ?? '',

      fullAddress: json['full_address']?.toString() ?? '',

      // Default branch
      branchId: json['branch_id']?.toString() ??
          json['storeId']?.toString() ??
          '',

      branchName: json['branch_name']?.toString() ??
          json['storeName']?.toString() ??
          '',

      branchDistance: json['branch_distance']?.toString() ??
          json['storeDistance']?.toString() ??
          '',

      branchLat: json['branch_lat']?.toString() ??
          json['storeLat']?.toString() ??
          '',

      branchLong: json['branch_long']?.toString() ??
          json['storeLong']?.toString() ??
          '',

      departmentId:
      json['department_id']?.toString() ?? '',

      departmentName:
      json['department_name']?.toString() ?? '',

      shiftId:
      json['shift_id']?.toString() ?? '',

      shiftStart:
      json['shift_start']?.toString() ?? '',

      shiftEnd:
      json['shift_end']?.toString() ?? '',

      dateOfJoining:
      json['date_of_joining']?.toString() ?? '',

      lastworkingdate:
      json['last_working_date']?.toString() ?? '',

      status:
      json['status']?.toString() ?? '',

      role:
      json['role']?.toString() ?? '',

      createdAt:
      json['createdAt']?.toString() ?? '',

      updatedAt:
      json['updatedAt']?.toString() ?? '',

      // ⭐ FIXED
      lastName:
      json['last_name']?.toString() ?? '',

      // ⭐ FIXED
      middleName:
      json['middle_name']?.toString() ?? '',

      // ⭐ FIXED
      cityName:
      json['city_name']?.toString() ?? '',

      // ⭐ FIXED
      pinCode:
      json['pin_code']?.toString() ?? '',

      // ⭐ FIXED
      districtName:
      json['district_name']?.toString() ?? '',

      reportingPosition:
      json['reporting_position']?.toString() ?? '',

      // ⭐ FIXED
      branchMap: branches,
    );
  }

  Map<String, dynamic> toJson() {

    return {

      'uid': uid,
      'cid': cid,
      'userid': userid,
      'password': password,
      'userToken': userToken,
      'userImg': userImg,
      'imeiNo': imeiNo,

      'fullName': fullName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'gender': gender,
      'fullAddress': fullAddress,

      'branchId': branchId,
      'branchName': branchName,
      'branchDistance': branchDistance,
      'branchLat': branchLat,
      'branchLong': branchLong,

      'departmentId': departmentId,
      'departmentName': departmentName,

      'shiftId': shiftId,
      'shiftStart': shiftStart,
      'shiftEnd': shiftEnd,

      'dateOfJoining': dateOfJoining,
      'lastworkingdate': lastworkingdate,

      'status': status,
      'role': role,

      'createdAt': createdAt,
      'updatedAt': updatedAt,

      'lastName': lastName,
      'middleName': middleName,

      'cityName': cityName,
      'pinCode': pinCode,
      'districtName': districtName,
      'reportingPosition': reportingPosition,

      'branchMap': branchMap,
    };
  }
}