import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AuthService {
  // Khởi tạo FirebaseAuth và FirebaseFirestore instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isAdmin() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) return false;

      final data = userDoc.data() as Map<String, dynamic>;
      final isAdmin = data['isAdmin'];

      print("Giá trị isAdmin trong Firestore: $isAdmin");

      return isAdmin == true;
    } catch (e) {
      print('Lỗi kiểm tra admin: $e');
      return false;
    }
  }

  Future<bool> isUserBlocked(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      if (!userDoc.exists) return false;
      final data = userDoc.data() as Map<String, dynamic>;
      return data['isBlocked'] == true;
    } catch (e) {
      print('Lỗi kiểm tra tài khoản bị khóa: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getUserBanStatus(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server));

      if (!userDoc.exists) {
        return {'isBanned': false, 'isBlocked': false};
      }

      final data = userDoc.data() as Map<String, dynamic>;
      bool isBanned = data['isBanned'] == true;
      bool isBlocked = data['isBlocked'] == true;

      if (isBanned) {
        DateTime? bannedUntil;
        String? bannedReason = data['bannedReason'];

        if (data['bannedUntil'] != null) {
          if (data['bannedUntil'] is Timestamp) {
            bannedUntil = (data['bannedUntil'] as Timestamp).toDate();
          } else if (data['bannedUntil'] is String) {
            bannedUntil = DateTime.parse(data['bannedUntil']);
          }
        }

        // Kiểm tra xem thời gian ban đã hết chưa
        if (bannedUntil != null && DateTime.now().isAfter(bannedUntil)) {
          // Hết thời gian ban, cập nhật trạng thái
          await _firestore.collection('users').doc(uid).update({
            'isBanned': false,
            'bannedAt': null,
            'bannedUntil': null,
            'bannedReason': null,
          });

          return {'isBanned': false, 'isBlocked': isBlocked};
        }

        return {
          'isBanned': true,
          'isBlocked': isBlocked,
          'bannedReason': bannedReason ?? 'Không có lý do cụ thể',
          'bannedUntil': bannedUntil,
        };
      }

      return {'isBanned': false, 'isBlocked': isBlocked};
    } catch (e) {
      print('Lỗi kiểm tra trạng thái ban: $e');
      return {'isBanned': false, 'isBlocked': false};
    }
  }

  String formatBanMessage(String reason, DateTime? bannedUntil) {
    String message = 'Tài khoản của bạn đã bị tạm khóa.\n\nLý do: $reason';

    if (bannedUntil != null) {
      final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
      String formattedDate = formatter.format(bannedUntil);
      message += '\n\nTài khoản sẽ được mở khóa vào: $formattedDate';

      // Tính số ngày còn lại
      Duration difference = bannedUntil.difference(DateTime.now());
      if (difference.inDays > 0) {
        message += '\n(Còn ${difference.inDays} ngày)';
      } else if (difference.inHours > 0) {
        message += '\n(Còn ${difference.inHours} giờ)';
      } else if (difference.inMinutes > 0) {
        message += '\n(Còn ${difference.inMinutes} phút)';
      }
    } else {
      message += '\n\nTài khoản bị khóa vĩnh viễn.';
    }

    message +=
        '\n\nVui lòng liên hệ quản trị viên nếu bạn cho rằng đây là nhầm lẫn.';

    return message;
  }

  /// Đăng nhập bằng email và mật khẩu
  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Lỗi đăng nhập: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      print('Lỗi đăng nhập: $e');
      rethrow;
    }
  }

  /// Đăng ký tài khoản mới
  Future<User?> signUp(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      // Lưu thông tin người dùng vào Firestore với vai trò mặc định (không phải admin)
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email.trim(),
          'isAdmin': false,
          'isBlocked': false,
          'isBanned': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Lỗi đăng ký: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      print('Lỗi đăng ký: $e');
      rethrow;
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Lỗi đăng xuất: $e');
      rethrow;
    }
  }

  /// Gửi email đặt lại mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      print('Lỗi gửi email đặt lại mật khẩu: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      print('Lỗi gửi email đặt lại mật khẩu: $e');
      rethrow;
    }
  }

  /// Cập nhật mật khẩu mới
  Future<void> updatePassword(
    String email,
    String verificationCode,
    String newPassword,
  ) async {
    try {
      // Đăng nhập tạm thời với mã xác thực
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: verificationCode,
      );

      if (userCredential.user == null) {
        throw Exception('Không thể xác thực tài khoản');
      }

      // Cập nhật mật khẩu mới
      await userCredential.user!.updatePassword(newPassword);

      // Đăng xuất để người dùng đăng nhập lại với mật khẩu mới
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      print('Lỗi cập nhật mật khẩu: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      print('Lỗi cập nhật mật khẩu: $e');
      rethrow;
    }
  }

  /// Theo dõi trạng thái đăng nhập của người dùng
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Ánh xạ lỗi FirebaseAuthException thành thông báo thân thiện
  Exception _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception(
          'Không tìm thấy tài khoản với email này. Vui lòng kiểm tra lại email hoặc tạo tài khoản mới.',
        );
      case 'wrong-password':
        return Exception(
          'Mật khẩu không chính xác. Vui lòng thử lại hoặc sử dụng chức năng quên mật khẩu.',
        );
      case 'invalid-email':
        return Exception(
          'Định dạng email không hợp lệ. Vui lòng nhập email đúng định dạng (ví dụ: example@gmail.com).',
        );
      case 'user-disabled':
        return Exception(
          'Tài khoản này đã bị vô hiệu hóa bởi quản trị viên. Vui lòng liên hệ hỗ trợ.',
        );
      case 'email-already-in-use':
        return Exception(
          'Email này đã được sử dụng cho tài khoản khác. Vui lòng sử dụng email khác hoặc đăng nhập.',
        );
      case 'weak-password':
        return Exception(
          'Mật khẩu quá yếu. Vui lòng sử dụng mật khẩu có ít nhất 6 ký tự.',
        );
      case 'operation-not-allowed':
        return Exception(
          'Thao tác đăng nhập bằng email/mật khẩu không được phép. Vui lòng liên hệ quản trị viên.',
        );
      case 'too-many-requests':
        return Exception(
          'Quá nhiều lần thử đăng nhập. Vui lòng đợi một lúc trước khi thử lại.',
        );
      case 'network-request-failed':
        return Exception(
          'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.',
        );
      case 'invalid-credential':
        return Exception(
          'Thông tin đăng nhập không hợp lệ. Vui lòng kiểm tra lại email và mật khẩu.',
        );
      default:
        return Exception(
          'Đăng nhập thất bại: ${e.message ?? "Lỗi không xác định"}',
        );
    }
  }
}
