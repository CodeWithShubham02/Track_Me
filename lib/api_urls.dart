class ApiUrls {
  static const String baseUrl = "https://yourdomain.com/api/";

  // Auth
  static const String login = "${baseUrl}login.php";
  static const String logout = "${baseUrl}logout.php";

  // Attendance
  static const String punchIn = "${baseUrl}punch_in.php";
  static const String punchOut = "${baseUrl}punch_out.php";
  static const String attendance = "${baseUrl}attendance.php";

  // Location
  static const String updateLocation = "${baseUrl}update_location.php";
  static const String getLocation = "${baseUrl}get_location.php";

  // Employee
  static const String employeeDetails = "${baseUrl}employee_details.php";
}