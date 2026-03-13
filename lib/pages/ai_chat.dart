import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../pages/custom_product_page.dart';
import '../models/food_item.dart';
import '../utils/global_state.dart';

import '../secrets.dart';

class AIChatOverlay extends StatefulWidget {
  const AIChatOverlay({super.key});

  @override
  State<AIChatOverlay> createState() => _AIChatOverlayState();
}

class _AIChatOverlayState extends State<AIChatOverlay> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  final String _systemPrompt = """
You are a helpful nutrition and recipe assistant.

CRITICAL INSTRUCTION: EVERY TIME the user mentions eating ANY food, or asks about the nutritional value of ANY food, you MUST help them add it to their app's inventory.
To do this, you MUST output a valid JSON block enclosed STRICTLY in <addCustomFood> and </addCustomFood> tags for EACH food item mentioned.

If the user mentions multiple foods (e.g., "200g of rice and 100g of chicken"), you MUST output multiple separate <addCustomFood> blocks, one for each item.

The JSON must contain exactly these keys: "name", "brand" (use "Generic" if unknown), "packageSize" (e.g., "100 g"), "calories", "protein", "carbs", and "fat" (use numbers for macros).

Example of a user asking about multiple foods:
<addCustomFood>
{
  "name": "Cooked White Rice",
  "brand": "Generic",
  "packageSize": "200 g",
  "calories": 260,
  "protein": 5.4,
  "carbs": 56,
  "fat": 0.6
}
</addCustomFood>
<addCustomFood>
{
  "name": "Chicken Breast",
  "brand": "Generic",
  "packageSize": "100 g",
  "calories": 165,
  "protein": 31,
  "carbs": 0,
  "fat": 3.6
}
</addCustomFood>

Respond naturally to the user, but ALWAYS include your <addCustomFood> tag(s) at the very end of your response.
CRITICAL FORMATTING RULE: Do NOT use markdown tables in your responses. Always use bulleted lists instead.
""";

  @override
  void initState() {
    super.initState();
    _loadChatHistory(); // Load history when the overlay opens
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedMessages = prefs.getString('ai_chat_history');

    if (savedMessages != null) {
      // Decode the JSON string back into a List of Maps
      final List<dynamic> decoded = jsonDecode(savedMessages);
      setState(() {
        _messages = decoded.map((e) => Map<String, String>.from(e)).toList();
      });

      if (_messages.length > 1) {
        // if text exists, scroll to bottom
        _scrollToBottom();
      }
    } else {
      // If no history exists, start fresh with the system prompt
      setState(() {
        _messages = [
          {"role": "system", "content": _systemPrompt},
        ];
      });
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    // Convert the list of maps to a JSON string and save it
    await prefs.setString('ai_chat_history', jsonEncode(_messages));
  }

  Future<void> _startNewChat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ai_chat_history'); // Clear from storage

    setState(() {
      _messages = [
        {"role": "system", "content": _systemPrompt},
      ];
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();
    _saveChatHistory();

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

      _saveChatHistory(); //Save again after ai responds
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: (_messages.length <= 1 && !_isLoading)
                  ? _buildEmptyState()
                  : _buildChatList(),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep, color: Colors.white70),
          tooltip: 'Start New Chat',
          onPressed: _startNewChat,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) return _buildLoadingBubble();

        final msg = _messages[index];
        if (msg["role"] == "system") return const SizedBox.shrink();

        return _buildChatBubble(msg);
      },
    );
  }

  Widget _buildChatBubble(Map<String, String> msg) {
    final isUser = msg["role"] == "user";
    final rawText = msg["content"] ?? "";

    String thinking = '';
    String mainText = rawText;
    List<Map<String, dynamic>> customFoodList = [];

    if (!isUser) {
      // Parse <think>
      final thinkRegex = RegExp(r'<think>([\s\S]*?)</think>');
      final thinkMatch = thinkRegex.firstMatch(mainText);
      if (thinkMatch != null) {
        thinking = thinkMatch.group(1)?.trim() ?? '';
        mainText = mainText.replaceAll(thinkRegex, '').trim();
      }

      // Parse <addCustomFood>
      final foodRegex = RegExp(r'<addCustomFood>([\s\S]*?)</addCustomFood>');
      final foodMatches = foodRegex.allMatches(mainText);
      for (final match in foodMatches) {
        try {
          final jsonString = match.group(1)?.trim() ?? '{}';
          customFoodList.add(jsonDecode(jsonString));
        } catch (e) {
          debugPrint("AI generated invalid JSON: $e");
        }

        mainText = mainText.replaceAll(foodRegex, '').trim();
      }
    }
    // clear any HTML tags
    mainText = mainText.replaceAll(
      RegExp(r'<br\s*/?>', caseSensitive: false),
      '\n',
    );
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isUser ? const Radius.circular(0) : null,
            bottomLeft: !isUser ? const Radius.circular(0) : null,
          ),
        ),
        child: isUser
            ? Text(
                mainText,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (thinking.isNotEmpty) _buildThoughtProcess(thinking),
                  MarkdownBody(
                    data: mainText,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 16, color: Colors.black87),
                      h3: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      listBullet: const TextStyle(color: Colors.black87),
                      // Prevent tables from squishing
                      tableColumnWidth: const IntrinsicColumnWidth(),
                      tableCellsPadding: const EdgeInsets.all(8),
                    ),
                  ),
                  ...customFoodList.map((data) => _buildCustomFoodCard(data)),
                ],
              ),
      ),
    );
  }

  Widget _buildThoughtProcess(String thinking) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
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
              borderRadius: BorderRadius.circular(8),
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
    );
  }

  Widget _buildCustomFoodCard(Map<String, dynamic> data) {
    final cals = (data['calories'] as num?)?.toDouble() ?? 0.0;
    final protein = (data['protein'] as num?)?.toDouble() ?? 0.0;
    final carbs = (data['carbs'] as num?)?.toDouble() ?? 0.0;
    final fat = (data['fat'] as num?)?.toDouble() ?? 0.0;

    final aiFoodItem = FoodItem(
      barcode: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: data['name']?.toString() ?? 'Custom',
      brand: data['brand']?.toString() ?? 'Custom',
      imageUrl: '',
      insertDate: DateTime.now(),
      categories: 'Custom',
      nutriments: {
        'energy-kcal_100g': cals,
        'proteins_100g': protein,
        'carbohydrates_100g': carbs,
        'fat_100g': fat,
      },
      fat: fat,
      carbs: carbs,
      protein: protein,
      packageSize: data['packageSize']?.toString() ?? '100 g',
      inventoryGrams: 100.0,
      isKnown: true,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: .1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The Info Header
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.fastfood, color: Colors.green),
              ),
              title: Text(
                aiFoodItem.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                "${cals.round()} kcal • ${aiFoodItem.packageSize}",
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),

            const Divider(height: 1),

            // The Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // EDIT
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CustomProductPage(initialItem: aiFoodItem),
                        ),
                      );

                      if (result != null && context.mounted) {
                        if (GlobalState.addFoodToInventory != null) {
                          GlobalState.addFoodToInventory!(result);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${result.name} saved!')),
                        );
                      }
                    },
                    icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                    label: const Text(
                      'Edit',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // QUICK ADD
                  ElevatedButton.icon(
                    onPressed: () {
                      if (GlobalState.addFoodToInventory != null) {
                        GlobalState.addFoodToInventory!(aiFoodItem);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${aiFoodItem.name} added to inventory!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.bolt, size: 18),
                    label: const Text('Quick Add'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
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
    );
  }

  // on empty suggest some sentences
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 64, color: Colors.white54),
            const SizedBox(height: 24),
            const Text(
              "How can I help you today?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // grey typing box
            Container(
              width: double.infinity, // Stretches nicely across the screen
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: .1)),
              ),
              child: SizedBox(
                height: 20, // Fixed height to prevent jumping
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                  child: AnimatedTextKit(
                    repeatForever: true,
                    pause: const Duration(milliseconds: 1500),
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'Give me a high protein breakfast idea...',
                      ),
                      TypewriterAnimatedText(
                        'How many calories are in 200g of rice?',
                      ),
                      TypewriterAnimatedText(
                        'What can I cook with chicken and broccoli?',
                      ),
                      TypewriterAnimatedText(
                        'Explain the benefits of fiber...',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(
            20,
          ).copyWith(bottomLeft: const Radius.circular(0)),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.blueAccent,
          ),
        ),
      ),
    );
  }
}
