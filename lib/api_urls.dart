class ApiUrls {
  static const String baseUrl = "https://trackme.joizone.com/attendance/";

  //version
  static const appVersionAdmin="1.7.4";
  //appVersionAdmin="1.6.4" // In this version edit rosters of user
  //appVersionAdmin="1.7.4" // In this version minor changes in approved report like manager remark remove and add site name column
  static const appVersionUser="1.2.3";
  //Auth
  static const loginUser = "${baseUrl}loginUser.php";


  //admin
  static const String fetchUsersAttendanceRange ="${baseUrl}fetchUserAttendanceRange.php";
  static const String getFormReports ="${baseUrl}getFormReports.php";
  static const String mtdStatusReport ="${baseUrl}mtd_status_report.php";
  static const String updateManualPunchOut = "${baseUrl}update_manual_punchout.php";
  static const String updateUserRosterShift ="${baseUrl}update_user_roster_shift.php";


  //Database manage url
  static const String userDBFetch ="${baseUrl}users_listdb.php";









  // Users
  static const String bulk_create_users = "${baseUrl}bulk_create_users.php";
  static const String add_report = "${baseUrl}add_report.php";
  static const String fetchAttendanceByKiosk = "${baseUrl}fetch_attendance_by_kiosk.php";
  static const punchIn = "${baseUrl}attendance_punch_in.php";
  static const punchOut = "${baseUrl}attendance_punch_out.php";
  static const breakStart = "${baseUrl}break_start.php";
  static const breakEnd = "${baseUrl}break_end.php";
  static const trackLocation = "${baseUrl}track_location.php";
  static const getReportsByDate = "${baseUrl}get_reports_by_date.php";
  static const getReportsByKiosk = "${baseUrl}get_reports_by_kiosk.php";
  static const attendanceBreakStart = "${baseUrl}attendance_break_start.php";
  static const attendanceBreakEnd = "${baseUrl}attendance_break_end.php";
  static const updateUserShift = "${baseUrl}update_user_shift.php";
  static const fetchAttendanceByid = "${baseUrl}fetch_attendance_by_id.php";
  static const getCompanyForms = "${baseUrl}get_company_forms.php";
  static const attendancePunchOut = "${baseUrl}attendance_punch_out.php";
  static const saveNotification = "${baseUrl}save_notification.php";
  static const checkFeatureAccess = "${baseUrl}check_feature_access.php";
  static const getBranchTodayForm = "${baseUrl}get_branch_today_forms.php";
  static const getNotification = "${baseUrl}get_notification.php";
  static const updateNotification = "${baseUrl}update_notification_status.php";
  static const getUsers = "${baseUrl}get_users.php";
  static const updateHoliday = "${baseUrl}updateHoliday.php";
  static const locationHistory = "${baseUrl}location_history.php";
  static const updateUserImg = "${baseUrl}update_user_img.php";
  static const weeklyTeamPerformance = "${baseUrl}weekly_team_performance.php";
  static const getDynamicForm = "${baseUrl}get_dynamic_form_details.php";
  static const appRemovedLog  = "${baseUrl}app_removed_log.php";

}