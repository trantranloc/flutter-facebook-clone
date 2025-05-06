import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
void backgroundTask() async {
  print("Tác vụ nền chạy lúc: ${DateTime.now()}");
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized in background task");
    // Thêm logic (ví dụ: gửi thông báo qua Firestore)
  } catch (e) {
    print("Error in background task: $e");
  }
}