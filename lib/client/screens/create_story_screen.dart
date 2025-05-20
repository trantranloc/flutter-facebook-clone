import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'story_view_screen.dart';
import '../../models/Story.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  File? _selectedImage;
  final TextEditingController _captionController = TextEditingController();
  String? _sticker;
  Offset _stickerOffset = const Offset(100, 100);
  bool _isLoading = false;
  bool _isUploading = false;
  String _uploadStatus = '';
  final List<String> _stickers = [
    '😊',
    '🎉',
    '❤️',
    '🌟',
    '🎈',
    '🔥',
    '✨',
    '💖',
  ];

  final cloudinary = CloudinaryPublic(
    'drtq9z4r4',
    'flutter_upload',
    cache: false,
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    if (_auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar('Vui lòng đăng nhập để tạo story');
        Navigator.pop(context);
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
      _uploadStatus = 'Đang chọn ảnh...';
    });

    try {
      final permission =
          source == ImageSource.camera ? Permission.camera : Permission.photos;
      if (!await _requestPermission(permission)) {
        _showSnackBar('Quyền truy cập bị từ chối', isError: true);
        return;
      }

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (picked != null) {
        final file = File(picked.path);
        if (await file.exists()) {
          setState(() {
            _selectedImage = file;
            _uploadStatus = 'Ảnh đã được chọn';
          });
          _showSnackBar('Ảnh đã được chọn!');
        } else {
          _showSnackBar('Không thể tải tệp ảnh', isError: true);
        }
      }
    } catch (e) {
      _showSnackBar('Lỗi chọn ảnh: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
        _uploadStatus = '';
      });
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      setState(() {
        _uploadStatus = 'Đang tải ảnh lên Cloudinary...';
      });

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'stories',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      print('Cloudinary URL: ${response.secureUrl}'); // Debug
      setState(() {
        _uploadStatus = 'Ảnh đã được tải lên';
      });
      return response.secureUrl;
    } catch (e) {
      print('Lỗi upload ảnh: $e');
      _showSnackBar('Lỗi tải ảnh: $e', isError: true);
      return null;
    }
  }

  Future<void> _submitStory() async {
    if (_selectedImage == null) {
      _showSnackBar('Vui lòng chọn một ảnh', isError: true);
      return;
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showSnackBar('Vui lòng đăng nhập', isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
      _isLoading = true;
      _uploadStatus = 'Đang xử lý...';
    });

    try {
      // Upload ảnh lên Cloudinary
      final imageUrl = await _uploadImageToCloudinary(_selectedImage!);
      if (imageUrl == null) {
        throw Exception('Không thể tải ảnh lên Cloudinary');
      }

      // Lấy thông tin người dùng
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      final userName =
          userData?['name'] ?? currentUser.displayName ?? 'Người dùng';
      final avatarUrl =
          userData?['avatarUrl'] ?? '';

      // Tạo story data, đồng bộ với model Story
      final storyData = {
        'userId': currentUser.uid,
        'user': userName, // Khớp với model Story
        'avatarUrl': avatarUrl, // Khớp với model Story
        'imageUrl': imageUrl,
        'caption': _captionController.text.trim(), // Luôn lưu caption
        'sticker': _sticker,
        'stickerOffsetX': _sticker != null ? _stickerOffset.dx : null,
        'stickerOffsetY': _sticker != null ? _stickerOffset.dy : null,
        'time': FieldValue.serverTimestamp(), // Khớp với model Story
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)),
        ),
        'isActive': true,
      };

      print('Saving story: $storyData'); // Debug

      // Lưu vào Firestore
      final docRef = await _firestore.collection('stories').add(storyData);

      // Tạo Story object
      final newStory = Story(
        id: docRef.id,
        imageUrl: imageUrl,
        user: userName,
        avatarUrl: avatarUrl,
        time: DateTime.now(),
        caption: _captionController.text.trim(),
        sticker: _sticker,
        stickerOffset: _sticker != null ? _stickerOffset : null,
      );

      _showSnackBar('Story đã được đăng!');
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pop(context, newStory);
    } catch (e) {
      print('Lỗi đăng story: $e');
      _showSnackBar('Lỗi: $e', isError: true);
    } finally {
      setState(() {
        _isUploading = false;
        _isLoading = false;
        _uploadStatus = '';
      });
    }
  }

  void _previewStory() {
    if (_selectedImage == null) {
      _showSnackBar('Vui lòng chọn ảnh để xem trước', isError: true);
      return;
    }

    final currentUser = _auth.currentUser;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => StoryViewScreen(
              stories: [
                Story(
                  imageUrl: _selectedImage!.path,
                  user: currentUser?.displayName ?? 'Bạn',
                  avatarUrl:
                      currentUser?.photoURL ??
                      'https://via.placeholder.com/150',
                  time: DateTime.now(),
                  caption: _captionController.text.trim(),
                  sticker: _sticker,
                  stickerOffset: _sticker != null ? _stickerOffset : null,
                ),
              ],
              initialIndex: 0,
            ),
      ),
    );
  }

  void _addSticker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            height: 250,
            child: Column(
              children: [
                const Text(
                  'Chọn Sticker',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children:
                        _stickers.map((sticker) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _sticker = sticker;
                                _stickerOffset = const Offset(100, 100);
                              });
                              Navigator.pop(context);
                              _showSnackBar('Sticker đã được thêm!');
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  sticker,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _resetSticker() {
    setState(() {
      _sticker = null;
      _stickerOffset = const Offset(100, 100);
    });
    _showSnackBar('Sticker đã được xóa');
  }

  void _resetAll() {
    setState(() {
      _selectedImage = null;
      _captionController.clear();
      _sticker = null;
      _stickerOffset = const Offset(100, 100);
    });
    _showSnackBar('Đã đặt lại');
  }

  void _cancelStory() {
    if (_isUploading) {
      _showSnackBar('Đang tải, vui lòng đợi', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hủy Story'),
            content: const Text('Bạn có chắc muốn hủy story này?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Không',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Có', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: !_isUploading,
      onPopInvoked: (didPop) {
        if (_isUploading && !didPop) {
          _showSnackBar('Đang tải, vui lòng đợi', isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Tạo Story'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(FontAwesomeIcons.times),
            onPressed: _cancelStory,
          ),
          actions: [
            ElevatedButton(
              onPressed: _isLoading ? null : _submitStory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.blue,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text(
                        'Đăng',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_uploadStatus.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            if (_isUploading)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blue,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_uploadStatus)),
                          ],
                        ),
                      ),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: GestureDetector(
                        onTap:
                            _isLoading ? null : () => _showImageSourceDialog(),
                        child: Container(
                          height: 400,
                          decoration: BoxDecoration(
                            color:
                                _selectedImage == null
                                    ? Colors.grey.shade200
                                    : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              _selectedImage == null
                                  ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          FontAwesomeIcons.camera,
                                          size: 60,
                                          color: Colors.grey,
                                        ),
                                        Text(
                                          'Chọn ảnh',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  )
                                  : Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 400,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Center(
                                                    child: Icon(
                                                      Icons.error,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                      if (_sticker != null)
                                        Positioned(
                                          left: _stickerOffset.dx,
                                          top: _stickerOffset.dy,
                                          child: GestureDetector(
                                            onPanUpdate: (details) {
                                              setState(() {
                                                final newOffset =
                                                    _stickerOffset +
                                                    details.delta;
                                                _stickerOffset = Offset(
                                                  newOffset.dx.clamp(
                                                    0,
                                                    screenWidth - 76,
                                                  ),
                                                  newOffset.dy.clamp(
                                                    0,
                                                    400 - 76,
                                                  ),
                                                );
                                              });
                                            },
                                            child: Stack(
                                              children: [
                                                Text(
                                                  _sticker!,
                                                  style: const TextStyle(
                                                    fontSize: 60,
                                                  ),
                                                ),
                                                Positioned(
                                                  top: -10,
                                                  right: -10,
                                                  child: GestureDetector(
                                                    onTap: _resetSticker,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            2,
                                                          ),
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Colors.red,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                      child: const Icon(
                                                        FontAwesomeIcons.times,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _captionController,
                        maxLines: 3,
                        maxLength: 150,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Chú thích (tùy chọn)',
                          hintText: 'Chia sẻ cảm xúc...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildActionButton(
                          onPressed: _isLoading ? null : _addSticker,
                          icon: FontAwesomeIcons.stickyNote,
                          label: 'Sticker',
                          isPrimary: true,
                        ),
                        _buildActionButton(
                          onPressed: _isLoading ? null : _previewStory,
                          icon: FontAwesomeIcons.eye,
                          label: 'Xem trước',
                          isPrimary: true,
                        ),
                        _buildActionButton(
                          onPressed: _isLoading ? null : _resetAll,
                          icon: FontAwesomeIcons.redo,
                          label: 'Đặt lại',
                          isPrimary: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.blue),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? Colors.blue.shade700 : Colors.white,
        foregroundColor: isPrimary ? Colors.white : Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: isPrimary ? null : const BorderSide(color: Colors.red),
      ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Chọn nguồn ảnh'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    FontAwesomeIcons.images,
                    color: Colors.blue,
                  ),
                  title: const Text('Thư viện'),
                  subtitle: const Text('Chọn từ thư viện có sẵn'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    FontAwesomeIcons.camera,
                    color: Colors.blue,
                  ),
                  title: const Text('Máy ảnh'),
                  subtitle: const Text('Chụp ảnh mới'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
    );
  }
}
