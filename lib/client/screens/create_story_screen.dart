import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
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
  final List<String> _stickers = ['😊', '🎉', '❤️', '🌟', '🎈', '🔥', '✨'];

  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final permission =
          source == ImageSource.camera ? Permission.camera : Permission.photos;
      final hasPermission = await _requestPermission(permission);

      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Quyền truy cập bị từ chối. Vui lòng cấp quyền trong cài đặt.',
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);

      if (picked != null) {
        final file = File(picked.path);
        if (await file.exists()) {
          setState(() {
            _selectedImage = file;
            _isLoading = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tải tệp ảnh. Vui lòng thử lại.'),
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi chọn ảnh: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitStory() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn một ảnh để đăng story')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      final newStory = Story(
        imageUrl: _selectedImage!.path,
        user: 'Your Name', // Replace with actual user data
        avatarUrl: 'https://i.pravatar.cc/150?img=1',
        time: DateTime.now(),
        caption:
            _captionController.text.isEmpty ? null : _captionController.text,
        sticker: _sticker,
        stickerOffset: _sticker != null ? _stickerOffset : null,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Story đã được đăng!')));

      Navigator.pop(context, newStory);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi đăng story: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _previewStory() {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn một ảnh để xem trước')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => StoryViewScreen(
              stories: [
                Story(
                  imageUrl: _selectedImage!.path,
                  user: 'Your Name', // Replace with actual user data
                  avatarUrl: 'https://i.pravatar.cc/150?img=1',
                  time: DateTime.now(),
                  caption:
                      _captionController.text.isEmpty
                          ? null
                          : _captionController.text,
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
            padding: const EdgeInsets.all(16.0),
            height: 200,
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children:
                  _stickers.map((sticker) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _sticker = sticker;
                          _stickerOffset = const Offset(
                            100,
                            100,
                          ); // Reset position
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[50]!, Colors.blue[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            sticker,
                            style: const TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
    );
  }

  void _resetSticker() {
    setState(() {
      _sticker = null;
      _stickerOffset = const Offset(100, 100);
    });
  }

  void _resetAll() {
    setState(() {
      _selectedImage = null;
      _captionController.clear();
      _sticker = null;
      _stickerOffset = const Offset(100, 100);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã đặt lại tất cả')));
  }

  void _cancelStory() {
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
                  style: TextStyle(color: Color(0xFF1877F2)),
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tạo Story'),
        backgroundColor: const Color(0xFF1877F2),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.times, color: Colors.white),
          onPressed: _cancelStory,
        ),
        actions: [
          AnimatedOpacity(
            opacity: _isLoading ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitStory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1877F2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Color(0xFF1877F2),
                          strokeWidth: 2,
                        ),
                      )
                      : const Text(
                        'Đăng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: GestureDetector(
                      onTap: () => _showImageSourceDialog(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 400,
                        decoration: BoxDecoration(
                          gradient:
                              _selectedImage == null
                                  ? LinearGradient(
                                    colors: [
                                      Colors.grey[200]!,
                                      Colors.grey[300]!,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                  : null,
                          border:
                              _selectedImage != null
                                  ? Border.all(
                                    color: const Color(0xFF1877F2),
                                    width: 2,
                                  )
                                  : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_selectedImage == null)
                              const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.camera,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Chọn ảnh từ thư viện hoặc máy ảnh',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            else
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _selectedImage!,
                                  height: 400,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        color: Colors.grey[300],
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              FontAwesomeIcons
                                                  .exclamationTriangle,
                                              color: Colors.red,
                                              size: 60,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Không thể tải ảnh',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                ),
                              ),
                            if (_sticker != null)
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 100),
                                left: _stickerOffset.dx,
                                top: _stickerOffset.dy,
                                child: GestureDetector(
                                  onPanUpdate: (details) {
                                    setState(() {
                                      final newOffset =
                                          _stickerOffset + details.delta;
                                      _stickerOffset = Offset(
                                        newOffset.dx.clamp(0, screenWidth - 76),
                                        newOffset.dy.clamp(0, 400 - 76),
                                      );
                                    });
                                  },
                                  child: Stack(
                                    children: [
                                      Text(
                                        _sticker!,
                                        style: const TextStyle(
                                          fontSize: 60,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 4,
                                              color: Colors.black54,
                                              offset: Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: -10,
                                        right: -10,
                                        child: GestureDetector(
                                          onTap: _resetSticker,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
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
                  const SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _captionController,
                      maxLines: 2,
                      maxLength: 100,
                      decoration: InputDecoration(
                        labelText: 'Chú thích (tùy chọn)',
                        hintText: 'Thêm chú thích cho story...',
                        labelStyle: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF1877F2),
                            width: 2,
                          ),
                        ),
                        counterStyle: const TextStyle(color: Color(0xFF1877F2)),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      AnimatedOpacity(
                        opacity: _isLoading ? 0.5 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _addSticker,
                          icon: const Icon(
                            FontAwesomeIcons.stickyNote,
                            size: 20,
                          ),
                          label: const Text(
                            'Thêm Sticker',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1877F2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: _isLoading ? 0.5 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _previewStory,
                          icon: const Icon(FontAwesomeIcons.eye, size: 20),
                          label: const Text(
                            'Xem trước',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1877F2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: _isLoading ? 0.5 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _resetAll,
                          icon: const Icon(
                            FontAwesomeIcons.redo,
                            color: Colors.red,
                            size: 20,
                          ),
                          label: const Text(
                            'Đặt lại',
                            style: TextStyle(color: Colors.red, fontSize: 16),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF1877F2)),
              ),
            ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Chọn nguồn ảnh',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    FontAwesomeIcons.images,
                    color: Color(0xFF1877F2),
                  ),
                  title: const Text('Thư viện', style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    FontAwesomeIcons.camera,
                    color: Color(0xFF1877F2),
                  ),
                  title: const Text('Máy ảnh', style: TextStyle(fontSize: 16)),
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
                child: const Text(
                  'Hủy',
                  style: TextStyle(color: Color(0xFF1877F2), fontSize: 16),
                ),
              ),
            ],
          ),
    );
  }
}
