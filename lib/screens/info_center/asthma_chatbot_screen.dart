import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../services/ai_service.dart';
import '../../models/chat_message_model.dart';
import '../../widgets/custom_button.dart';

class AsthmaChatbotScreen extends StatefulWidget {
  const AsthmaChatbotScreen({Key? key}) : super(key: key);

  @override
  State<AsthmaChatbotScreen> createState() => _AsthmaChatbotScreenState();
}

class _AsthmaChatbotScreenState extends State<AsthmaChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessageModel> _messages = [];
  bool _isTyping = false;
  String _errorMessage = '';
  bool _initialMessageSent = false;
  bool _isLoadingMessages = true;

  // Reference to AI service
  final AIService _aiService = AIService();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Load saved messages from SharedPreferences
  Future<void> _loadMessages() async {
    setState(() {
      _isLoadingMessages = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getStringList('asthma_chat_messages') ?? [];

      if (messagesJson.isNotEmpty) {
        setState(() {
          _messages = messagesJson
              .map((json) => ChatMessageModel.fromJson(jsonDecode(json)))
              .toList();
          _initialMessageSent = true;
        });
      } else {
        _sendInitialGreeting();
      }
    } catch (e) {
      print('Error loading messages: $e');
      _sendInitialGreeting();
    } finally {
      setState(() {
        _isLoadingMessages = false;
      });
    }
  }

  // Save messages to SharedPreferences
  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson =
          _messages.map((message) => jsonEncode(message.toJson())).toList();
      await prefs.setStringList('asthma_chat_messages', messagesJson);
    } catch (e) {
      print('Error saving messages: $e');
    }
  }

  // Initial greeting message from the bot
  void _sendInitialGreeting() {
    if (!_initialMessageSent) {
      setState(() {
        _messages.add(
          ChatMessageModel(
            text:
                "Hello! I'm your AsthmaGuard AI assistant. I can answer questions about asthma, triggers, symptoms, treatment, and management. How can I help you today?",
            isFromUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _initialMessageSent = true;
      });
      _saveMessages();
    }
  }

  // Handle sending messages
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      // Add user message
      _messages.add(
        ChatMessageModel(
          text: message,
          isFromUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
      _errorMessage = '';
      _messageController.clear();
    });

    // Save messages after adding user message
    await _saveMessages();

    // Scroll to bottom
    _scrollToBottom();

    try {
      // Get response from AI service
      final response = await _aiService.getAsthmaResponse(message);

      if (mounted) {
        setState(() {
          // Add AI response
          _messages.add(
            ChatMessageModel(
              text: response,
              isFromUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isTyping = false;
        });

        // Save messages after adding AI response
        await _saveMessages();

        // Scroll to bottom again
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isTyping = false;

          // Add error message
          _messages.add(
            ChatMessageModel(
              text:
                  "I'm sorry, I couldn't process your request. Please try again.",
              isFromUser: false,
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
        });

        // Save messages after adding error message
        await _saveMessages();

        // Scroll to bottom
        _scrollToBottom();
      }
    }
  }

  // Helper method to scroll to the bottom of the chat
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

  // Clear chat history
  Future<void> _clearChat() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Chat History',
          style: TextStyle(
            color: AppColors.primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to clear your chat history? This action cannot be undone.',
          style: TextStyle(
            color: AppColors.secondaryTextColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.secondaryTextColor,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _messages = [];
                _initialMessageSent = false;
              });

              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('asthma_chat_messages');
              } catch (e) {
                print('Error clearing messages: $e');
              }

              _sendInitialGreeting();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Asthma Chatbot',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        actions: [
          // Clear chat button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearChat,
            tooltip: 'Clear chat history',
            color: AppColors.primaryColor,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingMessages
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              )
            : Column(
                children: [
                  // Suggestion chips
                  if (_messages.length <= 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildSuggestionChip(
                                'What are common asthma triggers?'),
                            _buildSuggestionChip(
                                'How to use an inhaler properly?'),
                            _buildSuggestionChip('Signs of an asthma attack'),
                            _buildSuggestionChip('Asthma vs. allergies'),
                          ],
                        ),
                      ),
                    ),

                  // Chat messages
                  Expanded(
                    child: _messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(bottom: 16, top: 16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return _buildMessageBubble(message);
                            },
                          ),
                  ),

                  // Error message if any
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.errorColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Error: $_errorMessage',
                        style: TextStyle(
                          color: AppColors.errorColor,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  // Typing indicator
                  if (_isTyping)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI is thinking...',
                            style: TextStyle(
                              color: AppColors.secondaryTextColor,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Message input
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Ask about asthma...',
                              hintStyle: TextStyle(
                                  color: AppColors.secondaryTextColor),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            minLines: 1,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            onTap: _isTyping ? null : _sendMessage,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
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

  // Widget for empty state when no messages exist
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_outlined,
              size: 60,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ask anything about asthma',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Get answers about asthma symptoms, treatments, triggers, and management strategies',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for building message bubbles
  Widget _buildMessageBubble(ChatMessageModel message) {
    return Align(
      alignment:
          message.isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: message.isFromUser ? 64 : 16,
          right: message.isFromUser ? 16 : 64,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isFromUser
              ? AppColors.primaryColor
              : message.isError
                  ? AppColors.errorColor.withOpacity(0.1)
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          border: message.isFromUser
              ? null
              : Border.all(
                  color: message.isError
                      ? AppColors.errorColor.withOpacity(0.3)
                      : Colors.grey.shade200,
                  width: 1,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isFromUser
                    ? Colors.white
                    : message.isError
                        ? AppColors.errorColor
                        : AppColors.primaryTextColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: message.isFromUser
                    ? Colors.white.withOpacity(0.7)
                    : AppColors.secondaryTextColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for quick suggestion chips
  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Helper method to format time
  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : time.hour == 0
            ? 12
            : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
