class ChatMessage {
  final int? id;
  final String conversationId;
  final String senderEmail;
  final String senderName;
  final String senderRole; // 'cliente' o 'trabajador'
  final String text;
  final DateTime timestamp;
  final bool isFile;
  final String? fileName;
  final String? fileExtension;
  final String? fileSize;
  final String? filePath;
  final String? fileBytesBase64;

  ChatMessage({
    this.id,
    required this.conversationId,
    required this.senderEmail,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.timestamp,
    this.isFile = false,
    this.fileName,
    this.fileExtension,
    this.fileSize,
    this.filePath,
    this.fileBytesBase64,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_email': senderEmail,
      'sender_name': senderName,
      'sender_role': senderRole,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'is_file': isFile ? 1 : 0,
      'file_name': fileName,
      'file_extension': fileExtension,
      'file_size': fileSize,
      'file_path': filePath,
      'file_bytes_b64': fileBytesBase64,
    };
  }

  factory ChatMessage.fromMap(Map<String, Object?> map) {
    return ChatMessage(
      id: map['id'] as int?,
      conversationId: map['conversation_id'] as String,
      senderEmail: map['sender_email'] as String,
      senderName: map['sender_name'] as String,
      senderRole: map['sender_role'] as String,
      text: map['text'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as int?) ?? 0,
      ),
      isFile: (map['is_file'] as int?) == 1,
      fileName: map['file_name'] as String?,
      fileExtension: map['file_extension'] as String?,
      fileSize: map['file_size'] as String?,
      filePath: map['file_path'] as String?,
      fileBytesBase64: map['file_bytes_b64'] as String?,
    );
  }
}

class Conversation {
  final String id;
  final String clientEmail;
  final String clientName;
  final String workerEmail;
  final String workerName;
  final DateTime lastMessageTime;
  final String lastMessagePreview;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.clientEmail,
    required this.clientName,
    required this.workerEmail,
    required this.workerName,
    required this.lastMessageTime,
    required this.lastMessagePreview,
    this.unreadCount = 0,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'client_email': clientEmail,
      'client_name': clientName,
      'worker_email': workerEmail,
      'worker_name': workerName,
      'last_message_time': lastMessageTime.millisecondsSinceEpoch,
      'last_message_preview': lastMessagePreview,
      'unread_count': unreadCount,
    };
  }

  factory Conversation.fromMap(Map<String, Object?> map) {
    return Conversation(
      id: map['id'] as String,
      clientEmail: map['client_email'] as String,
      clientName: map['client_name'] as String,
      workerEmail: map['worker_email'] as String,
      workerName: map['worker_name'] as String,
      lastMessageTime: DateTime.fromMillisecondsSinceEpoch(
        (map['last_message_time'] as int?) ?? 0,
      ),
      lastMessagePreview: map['last_message_preview'] as String,
      unreadCount: (map['unread_count'] as int?) ?? 0,
    );
  }
}
