import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'services/update_service.dart';

void main() {
  runApp(const ChengxiangApp());
}

class ChengxiangApp extends StatelessWidget {
  const ChengxiangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '丞相',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // 后端API地址
  static const String _baseUrl = 'http://100.69.100.122:8765';

  @override
  void initState() {
    super.initState();
    // App启动时检查更新
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    final updateInfo = await UpdateService.checkForUpdate();
    if (updateInfo != null) {
      final hasNewVersion = await UpdateService.isNewVersionAvailable(updateInfo);
      if (hasNewVersion) {
        // 显示更新对话框
        if (mounted) {
          await UpdateService.showUpdateDialog(context, updateInfo);
        }
      }
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    _controller.clear();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add(ChatMessage(
            text: data['response'] ?? '无回复',
            isUser: false,
            persona: data['persona'],
          ));
        });
      } else {
        setState(() {
          _messages.add(const ChatMessage(
            text: '后端错误，请检查服务是否启动',
            isUser: false,
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: '网络错误: $e',
          isUser: false,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('丞相 - AI成长伙伴'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ChatBubble(
                  text: msg.text,
                  isUser: msg.isUser,
                  persona: msg.persona,
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '输入消息...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final Map<String, dynamic>? persona;

  ChatMessage({required this.text, required this.isUser, this.persona});
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final Map<String, dynamic>? persona;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.persona,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && persona != null)
              Text(
                '${persona!['name'] ?? 'AI'}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
