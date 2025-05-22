import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GameWordChainScreen extends StatefulWidget {
  const GameWordChainScreen({super.key});

  @override
  _GameWordChainScreenState createState() => _GameWordChainScreenState();
}

class _GameWordChainScreenState extends State<GameWordChainScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _words = ['bắt đầu']; // Từ bắt đầu
  String? _errorMessage;
  final Set<String> _usedWords = {'bắt đầu'}; // Lưu trữ từ đã dùng

  void _submitWord() {
    final newWord = _controller.text.trim().toLowerCase();
    final lastWord = _words.last;

    // Kiểm tra từ hợp lệ
    if (newWord.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập một từ!';
      });
    } else if (_usedWords.contains(newWord)) {
      setState(() {
        _errorMessage = 'Từ "$newWord" đã được sử dụng!';
      });
    } else if (newWord[0] != lastWord[lastWord.length - 1]) {
      setState(() {
        _errorMessage =
            'Từ phải bắt đầu bằng "${lastWord[lastWord.length - 1]}"!';
      });
    } else {
      setState(() {
        _words.add(newWord);
        _usedWords.add(newWord);
        _errorMessage = null;
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trò Chơi Nối Từ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColorDark,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/game-selection'),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.cyanAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Danh sách từ đã chơi
              Expanded(
                child: ListView.builder(
                  itemCount: _words.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          _words[index],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        leading: Icon(
                          Icons.arrow_right_alt,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Thông báo lỗi
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              // Ô nhập từ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Nhập từ mới',
                    hintText:
                        'Bắt đầu bằng "${_words.last[_words.last.length - 1]}"',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: _submitWord,
                    ),
                  ),
                  onSubmitted: (_) => _submitWord(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
