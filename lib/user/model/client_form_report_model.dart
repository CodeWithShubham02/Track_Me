class ClientFormReportModel {
  final int id;
  final int uid;
  final String userId;
  final String userName;
  final String cityName;
  final String siteName;
  final String reportDate;
  final String reportTime;
  late final String applicationNo;
  late final String relation;
  late final String variant;
  late final String status;
  late final String remarks;
  final String managerRemarks;
  final String bankRemarks;
  final String updateStatus;
  final String contactNo;
  final List<String> imageUrls;
  final String gpsLocation;
  final String kioskName;
  final String createdAt;
  final String updatedAt;
  late final String duplicateFrom;

  ClientFormReportModel({
    required this.id,
    required this.uid,
    required this.userId,
    required this.userName,
    required this.cityName,
    required this.siteName,
    required this.reportDate,
    required this.reportTime,
    required this.applicationNo,
    required this.relation,
    required this.variant,
    required this.status,
    required this.remarks,
    required this.managerRemarks,
    required this.bankRemarks,
    required this.updateStatus,
    required this.contactNo,
    required this.imageUrls,
    required this.gpsLocation,
    required this.kioskName,
    required this.createdAt,
    required this.updatedAt,
    required this.duplicateFrom,
  });

  factory ClientFormReportModel.fromJson(Map<String, dynamic> json) {
    return ClientFormReportModel(
      id: int.parse(json['id'].toString()),
      uid: int.parse(json['uid'].toString()),
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      cityName: json['city_name'] ?? '',
      siteName: json['site_name'] ?? '',
      reportDate: json['report_date'] ?? '',
      reportTime: json['report_time'] ?? '',
      applicationNo: json['application_no'] ?? '',
      relation: json['relation'] ?? '',
      variant: json['variant'] ?? '',
      status: json['status'] ?? '',
      remarks: json['remarks'] ?? '',
      managerRemarks: json['remark_manager'] ?? '',
      bankRemarks: json['bank_remark_status'] ?? '',
      updateStatus: json['bank_update_status'] ?? '',
      contactNo: json['contact_no'] ?? '',
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : [],
      gpsLocation: json['gps_location'] ?? '',
      kioskName: json['kiosk_name'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      duplicateFrom: json['duplicate_from'] ?? 'no',
    );
  }
}
