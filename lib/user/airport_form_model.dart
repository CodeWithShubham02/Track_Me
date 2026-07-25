class AirportFormModel {
  String uid;
  String cid;
  String userId;
  String userName;
  String cityName;
  String applicationNo;
  String relation;
  String variant;
  String status;
  String remarks;
  String contactNo;
  String gpsLocation;
  String kioskName;

  List<String> imageUrls; // ✅ change here

  AirportFormModel({
    required this.uid,
    required this.cid,
    required this.userId,
    required this.userName,
    required this.cityName,
    required this.applicationNo,
    required this.relation,
    required this.variant,
    required this.status,
    required this.remarks,
    required this.contactNo,
    required this.gpsLocation,
    required this.kioskName,
    required this.imageUrls,
  });

  Map<String, dynamic> toJson() {
    return {
      "uid": uid,
      "cid": cid,
      "user_id": userId,
      "user_name": userName,
      "city_name": cityName,
      "application_no": applicationNo,
      "relation": relation,
      "variant": variant,
      "status": status,
      "remarks": remarks,
      "contact_no": contactNo,
      "gps_location": gpsLocation,
      "kiosk_name": kioskName,
      "image_urls": imageUrls, // List<String>
    };
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "cid": cid,
      "user_id": userId,
      "user_name": userName,
      "city_name": cityName,
      "application_no": applicationNo,
      "relation": relation,
      "variant": variant,
      "status": status,
      "remarks": remarks,
      "contact_no": contactNo,
      "gps_location": gpsLocation,
      "kiosk_name": kioskName,
      "image_urls": imageUrls,
    };
  }

}
