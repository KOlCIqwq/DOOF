import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';

import '../secrets.dart';

class AIChatOverlay extends StatefulWidget {
  const AIChatOverlay({super.key});

  @override
  State<AIChatOverlay> createState() => _AIChatOverlayState();
}

class _AIChatOverlayState extends State<AIChatOverlay> {
  final TextEditingController _controller = TextEditingController();

  // We store messages in the exact format Groq expects!
  final List<Map<String, String>> _messages = [
    {
      "role": "system",
      "content": "You are a helpful nutrition and recipe assistant.",
    },
  ];

  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isLoading = true;
      _controller.clear();
    });

    try {
      // OpenAI compatible
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $groqApiKey',
        },
        body: jsonEncode({
          "model": "qwen/qwen3-32b",
          "messages": _messages,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['choices'][0]['message']['content'];
        setState(() {
          _messages.add({"role": "assistant", "content": aiText});
        });
      } else {
        setState(() {
          _messages.add({
            "role": "assistant",
            "content": "Error: ${response.statusCode} - ${response.body}",
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "assistant",
          "content": "Failed to connect to AI.",
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold with a semi-transparent black background!
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: .6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI Assistant',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  // Hide the hidden system prompt from the UI
                  if (msg["role"] == "system") return const SizedBox.shrink();

                  final isUser = msg["role"] == "user";
                  final rawText = msg["content"] ?? "";

                  String thinking = '';
                  String mainText = rawText;

                  if (!isUser) {
                    final thinkRegex = RegExp(r'<think>([\s\S]*?)</think>');
                    final match = thinkRegex.firstMatch(rawText);

                    if (match != null) {
                      thinking = match.group(1)?.trim() ?? '';
                      // Remove the think block from the main text
                      mainText = rawText.replaceAll(thinkRegex, '').trim();
                    }
                  }

                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(
                        // Prevent bubbles from stretching across the entire screen
                        maxWidth: MediaQuery.of(context).size.width * 0.85,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.blueAccent
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20).copyWith(
                          bottomRight: isUser ? const Radius.circular(0) : null,
                          bottomLeft: !isUser ? const Radius.circular(0) : null,
                        ),
                      ),
                      child: isUser
                          ? Text(
                              mainText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // The Thinking Toggle
                                if (thinking.isNotEmpty)
                                  Theme(
                                    // Removes the default borders of ExpansionTile
                                    data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent,
                                    ),
                                    child: ExpansionTile(
                                      tilePadding: EdgeInsets.zero,
                                      title: const Text(
                                        '🤔 Thought Process',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            thinking,
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                                // The Markdown Renderer
                                MarkdownBody(
                                  data: mainText,
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    h3: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    // Customizing the lists so they look nice in the bubble
                                    listBullet: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),

            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask about nutrition, recipes...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
