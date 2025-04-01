class ChatMessageModel {
  final String text;
  final bool isFromUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessageModel({
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    this.isError = false,
  });

  // Convert ChatMessageModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isFromUser': isFromUser,
      'timestamp': timestamp.toIso8601String(),
      'isError': isError,
    };
  }

  // Create ChatMessageModel from JSON
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      text: json['text'] as String,
      isFromUser: json['isFromUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isError: json['isError'] as bool? ?? false,
    );
  }
}
