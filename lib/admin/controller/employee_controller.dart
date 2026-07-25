import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/employee_model.dart';

class EmployeeController {

  /// 🔐 Create Employee
  static Future<void> createEmployee({
    required String cid,
    required String email,
    required String password,
    required EmployeeModel employee,
  }) async {

    // 1️⃣ Firebase Auth create
    UserCredential cred =
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    String uid = cred.user!.uid;

    // 2️⃣ Save Firestore
    await FirebaseFirestore.instance
        .collection('bizipac')
        .doc(cid)
        .collection('employees')
        .doc(uid)
        .set(employee.toMap());
  }

  /// 🔁 Fetch all employees (Stream)
  static Stream<List<EmployeeModel>> getEmployees(String cid) {
    return FirebaseFirestore.instance
        .collection('bizipzc')
        .doc(cid)
        .collection('employees')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((e) => EmployeeModel.fromDoc(e)).toList());
  }

  /// 🔁 Update Android ID (First Login)
  static Future<void> updateAndroidId({
    required String cid,
    required String eid,
    required String androidId,
  }) async {
    final ref = FirebaseFirestore.instance
        .collection('bizipzc')
        .doc(cid)
        .collection('employees')
        .doc(eid);

    final doc = await ref.get();

    if (doc.exists && (doc['android_id'] == null || doc['android_id'] == '')) {
      await ref.update({'android_id': androidId});
    }
  }
}
