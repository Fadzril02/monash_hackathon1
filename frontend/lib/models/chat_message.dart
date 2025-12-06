class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final List<String>? toolsUsed;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.toolsUsed,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      toolsUsed: json['toolsUsed'] != null
          ? List<String>.from(json['toolsUsed'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      if (toolsUsed != null) 'toolsUsed': toolsUsed,
    };
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

class ChatResponse {
  final String response;
  final List<String>? toolsUsed;
  final DateTime timestamp;
  final Map<String, dynamic>? usage;

  ChatResponse({
    required this.response,
    this.toolsUsed,
    DateTime? timestamp,
    this.usage,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      response: json['response'] as String,
      toolsUsed: json['toolsUsed'] != null
          ? List<String>.from(json['toolsUsed'] as List)
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      usage: json['usage'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'response': response,
      if (toolsUsed != null) 'toolsUsed': toolsUsed,
      'timestamp': timestamp.toIso8601String(),
      if (usage != null) 'usage': usage,
    };
  }
}
