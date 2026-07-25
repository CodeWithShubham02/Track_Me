import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Google Maps API Key
    GMSServices.provideAPIKey("AIzaSyBF7OlUqnsWTXRMiwtwEk9ieQ4Ihq18")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 🔥 App Close Detection
//   override func applicationWillTerminate(_ application: UIApplication) {
//
//     print("AUTO_PUNCH: App terminated")
//
//     let defaults = UserDefaults.standard
//
//     let attendanceId = defaults.string(forKey: "flutter.attendance_id")
//     let uid = defaults.string(forKey: "flutter.uid")
//     let cid = defaults.string(forKey: "flutter.cid")
//
//     if attendanceId != nil && uid != nil && cid != nil {
//
//         let urlString = "https://fms.bizipac.com/apinew/attendance/attendance_punch_out.php?attendance_id=\(attendanceId!)"
//         guard let url = URL(string: urlString) else { return }
//
//         var request = URLRequest(url: url)
//         request.httpMethod = "POST"
//
//         let params = [
//             "action":"punch_out",
//             "status":"Present",
//             "uid":uid!,
//             "cid":cid!,
//             "lat":"0",
//             "lng":"0",
//             "remark":"Auto punch Out - App closed",
//             "image":"NA"
//         ]
//
//         let bodyString = params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
//         request.httpBody = bodyString.data(using: .utf8)
//
//         let task = URLSession.shared.dataTask(with: request) { data, response, error in
//
//             if let error = error {
//                 print("AUTO_PUNCH API FAILED: \(error)")
//                 return
//             }
//
//             print("AUTO_PUNCH API SUCCESS")
//
//             // Remove attendance
//             defaults.removeObject(forKey: "flutter.attendance_id")
//             defaults.removeObject(forKey: "flutter.uid")
//
//             defaults.synchronize()
//
//             print("AUTO_PUNCH Attendance Removed")
//         }
//
//         task.resume()
//     }
//   }
}