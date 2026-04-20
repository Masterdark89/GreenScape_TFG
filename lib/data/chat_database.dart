import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_notification_service.dart';
import '../core/runtime_flags.dart';
import '../models/chat_message.dart';
import 'firestore_id_generator.dart';

class ChatDatabase {
  ChatDatabase._();

  static final ChatDatabase instance = ChatDatabase._();
  static const String supportWorkerEmail = 'trabajador@gmail.com';
  static const String legacySupportWorkerEmail = 'soporte@greenscape.com';
  static const String supportWorkerName = 'Soporte GreenScape';

  static const String _conversationsPrefsKey = 'db.chat.conversations';
  static const String _messagesPrefsKey = 'db.chat.messages';
  static const String _messagesNextIdPrefsKey = 'db.chat.next_message_id';
  static const String _conversationCollectionName = 'chat_conversations';
  static const String _messageCollectionName = 'chat_messages';

  bool get _usePrefsStorage => isFlutterTestRuntime;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _conversationCollection =>
      _firestore.collection(_conversationCollectionName);

  CollectionReference<Map<String, dynamic>> get _messageCollection =>
      _firestore.collection(_messageCollectionName);

  Future<List<Map<String, Object?>>> _readConversationsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_conversationsPrefsKey);
    if (raw == null || raw.isEmpty) {
      return <Map<String, Object?>>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <Map<String, Object?>>[];
      }

      return decoded.whereType<Map>().map<Map<String, Object?>>((item) {
        final map = item.map<String, Object?>((key, value) {
          return MapEntry(key.toString(), value);
        });

        return {
          ...map,
          'last_message_time': (map['last_message_time'] as num?)?.toInt() ?? 0,
          'unread_count': (map['unread_count'] as num?)?.toInt() ?? 0,
        };
      }).toList();
    } catch (_) {
      return <Map<String, Object?>>[];
    }
  }

  Future<void> _writeConversationsToPrefs(
    List<Map<String, Object?>> conversations,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_conversationsPrefsKey, jsonEncode(conversations));
  }

  Future<List<Map<String, Object?>>> _readMessagesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_messagesPrefsKey);
    if (raw == null || raw.isEmpty) {
      return <Map<String, Object?>>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <Map<String, Object?>>[];
      }

      return decoded.whereType<Map>().map<Map<String, Object?>>((item) {
        final map = item.map<String, Object?>((key, value) {
          return MapEntry(key.toString(), value);
        });

        return {
          ...map,
          'id': (map['id'] as num?)?.toInt(),
          'timestamp': (map['timestamp'] as num?)?.toInt() ?? 0,
          'is_file': (map['is_file'] as num?)?.toInt() ?? 0,
        };
      }).toList();
    } catch (_) {
      return <Map<String, Object?>>[];
    }
  }

  Future<void> _writeMessagesToPrefs(List<Map<String, Object?>> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_messagesPrefsKey, jsonEncode(messages));
  }

  Future<int> _getAndAdvanceNextMessageId() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_messagesNextIdPrefsKey) ?? 1;
    await prefs.setInt(_messagesNextIdPrefsKey, current + 1);
    return current;
  }

  Map<String, Object?> _normalizeConversationMap(
    Map<String, Object?> data, {
    String? docId,
  }) {
    return {
      ...data,
      'id': (data['id'] as String?) ?? docId ?? '',
      'last_message_time': (data['last_message_time'] as num?)?.toInt() ?? 0,
      'unread_count': (data['unread_count'] as num?)?.toInt() ?? 0,
    };
  }

  Map<String, Object?> _normalizeMessageMap(
    Map<String, Object?> data, {
    String? docId,
  }) {
    return {
      ...data,
      'id': (data['id'] as num?)?.toInt() ?? int.tryParse(docId ?? ''),
      'timestamp': (data['timestamp'] as num?)?.toInt() ?? 0,
      'is_file': (data['is_file'] as num?)?.toInt() ?? 0,
    };
  }

  Future<List<Map<String, Object?>>> _readConversationsFromFirestore() async {
    final snapshot = await _conversationCollection.get();
    final rows = snapshot.docs
        .map((doc) => _normalizeConversationMap(Map<String, Object?>.from(doc.data()), docId: doc.id))
        .toList();
    rows.sort((a, b) {
      final aTime = (a['last_message_time'] as int?) ?? 0;
      final bTime = (b['last_message_time'] as int?) ?? 0;
      return bTime.compareTo(aTime);
    });
    return rows;
  }

  Future<List<Map<String, Object?>>> _readMessagesFromFirestore() async {
    final snapshot = await _messageCollection.get();
    final rows = snapshot.docs
        .map((doc) => _normalizeMessageMap(Map<String, Object?>.from(doc.data()), docId: doc.id))
        .toList();
    rows.sort((a, b) {
      final aTime = (a['timestamp'] as int?) ?? 0;
      final bTime = (b['timestamp'] as int?) ?? 0;
      return aTime.compareTo(bTime);
    });
    return rows;
  }

  Future<void> _writeConversationMap(Map<String, Object?> data) async {
    final id = data['id']?.toString() ?? '';
    if (id.isEmpty) {
      return;
    }
    await _conversationCollection.doc(id).set(data);
  }

  Future<void> _writeMessageMap(Map<String, Object?> data) async {
    final id = (data['id'] as num?)?.toInt();
    if (id == null) {
      return;
    }
    await _messageCollection.doc(id.toString()).set(data);
  }

  Future<String> getOrCreateConversation({
    required String clientEmail,
    required String clientName,
    required String workerEmail,
    required String workerName,
  }) async {
    final normalizedClientEmail = clientEmail.trim().toLowerCase();
    final normalizedWorkerEmail = workerEmail.trim().toLowerCase();
    final conversationId = '${normalizedClientEmail}_$normalizedWorkerEmail'.toLowerCase();

    if (_usePrefsStorage) {
      final conversations = await _readConversationsFromPrefs();
      final existingIndex = conversations.indexWhere((row) => row['id'] == conversationId);
      if (existingIndex != -1) {
        conversations[existingIndex] = {
          ...conversations[existingIndex],
          'client_name': clientName,
          'worker_name': workerName,
          'client_email': normalizedClientEmail,
          'worker_email': normalizedWorkerEmail,
        };
        await _writeConversationsToPrefs(conversations);
        return conversationId;
      }

      conversations.add({
        'id': conversationId,
        'client_email': normalizedClientEmail,
        'client_name': clientName,
        'worker_email': normalizedWorkerEmail,
        'worker_name': workerName,
        'last_message_time': DateTime.now().millisecondsSinceEpoch,
        'last_message_preview': 'Conversación iniciada',
        'unread_count': 0,
      });
      await _writeConversationsToPrefs(conversations);
      return conversationId;
    }

    final doc = await _conversationCollection.doc(conversationId).get();
    if (doc.exists) {
      await doc.reference.update({
        'client_name': clientName,
        'worker_name': workerName,
        'client_email': normalizedClientEmail,
        'worker_email': normalizedWorkerEmail,
      });
      return conversationId;
    }

    await _writeConversationMap({
      'id': conversationId,
      'client_email': normalizedClientEmail,
      'client_name': clientName,
      'worker_email': normalizedWorkerEmail,
      'worker_name': workerName,
      'last_message_time': DateTime.now().millisecondsSinceEpoch,
      'last_message_preview': 'Conversación iniciada',
      'unread_count': 0,
    });

    return conversationId;
  }

  Future<List<Conversation>> getConversationsForUser(String userEmail) async {
    if (_usePrefsStorage) {
      final normalizedEmail = userEmail.trim().toLowerCase();
      final rows = await _readConversationsFromPrefs();
      final filtered = rows.where((row) {
        final clientEmail = (row['client_email'] as String?)?.trim().toLowerCase();
        final workerEmail = (row['worker_email'] as String?)?.trim().toLowerCase();
        return clientEmail == normalizedEmail || workerEmail == normalizedEmail;
      }).toList();

      filtered.sort((a, b) {
        final aTime = (a['last_message_time'] as int?) ?? 0;
        final bTime = (b['last_message_time'] as int?) ?? 0;
        return bTime.compareTo(aTime);
      });

      return filtered.map(Conversation.fromMap).toList();
    }

    final normalizedEmail = userEmail.trim().toLowerCase();
    final rows = await _readConversationsFromFirestore();
    final filtered = rows.where((row) {
      final clientEmail = (row['client_email'] as String?)?.trim().toLowerCase();
      final workerEmail = (row['worker_email'] as String?)?.trim().toLowerCase();
      return clientEmail == normalizedEmail || workerEmail == normalizedEmail;
    }).toList();

    return filtered.map(Conversation.fromMap).toList();
  }

  Future<List<Conversation>> getConversationsForWorker(String workerEmail) async {
    if (_usePrefsStorage) {
      final normalizedWorkerEmail = workerEmail.trim().toLowerCase();
      final rows = await _readConversationsFromPrefs();
      final filtered = rows.where((row) {
        final rowWorker = (row['worker_email'] as String?)?.trim().toLowerCase();
        return rowWorker == normalizedWorkerEmail ||
            rowWorker == legacySupportWorkerEmail;
      }).toList();

      filtered.sort((a, b) {
        final aTime = (a['last_message_time'] as int?) ?? 0;
        final bTime = (b['last_message_time'] as int?) ?? 0;
        return bTime.compareTo(aTime);
      });

      return filtered.map(Conversation.fromMap).toList();
    }

    final normalizedWorkerEmail = workerEmail.trim().toLowerCase();
    final rows = await _readConversationsFromFirestore();
    final filtered = rows.where((row) {
      final rowWorker = (row['worker_email'] as String?)?.trim().toLowerCase();
      return rowWorker == normalizedWorkerEmail ||
          rowWorker == legacySupportWorkerEmail;
    }).toList();

    return filtered.map(Conversation.fromMap).toList();
  }

  Future<int> insertMessage(ChatMessage message) async {
    if (_usePrefsStorage) {
      final messages = await _readMessagesFromPrefs();
      final nextId = await _getAndAdvanceNextMessageId();
      messages.add({
        'id': nextId,
        ...message.toMap()..remove('id'),
      });
      await _writeMessagesToPrefs(messages);
      await _notifyRecipientAboutMessage(message);
      return nextId;
    }

    final nextId = await FirestoreIdGenerator.nextId('chat_message_next_id');
    final stored = <String, Object?>{
      ...message.toMap(),
      'id': nextId,
    };
    await _writeMessageMap(stored);
    await _notifyRecipientAboutMessage(message);
    return nextId;
  }

  Future<void> _notifyRecipientAboutMessage(ChatMessage message) async {
    final conversation = await _findConversationById(message.conversationId);
    if (conversation == null) {
      return;
    }

    final recipientEmail = message.senderRole == 'trabajador'
        ? conversation.clientEmail
        : conversation.workerEmail;

    final preview = message.isFile ? 'Te ha enviado un archivo' : message.text.trim();

    await AppNotificationService.instance.notifyMessageReceived(
      recipientEmail: recipientEmail.trim().toLowerCase(),
      senderName: message.senderName,
      preview: preview.isEmpty ? 'Nuevo mensaje' : preview,
    );
  }

  Future<Conversation?> _findConversationById(String conversationId) async {
    if (_usePrefsStorage) {
      final rows = await _readConversationsFromPrefs();
      for (final row in rows) {
        if ((row['id'] as String?) == conversationId) {
          return Conversation.fromMap(row);
        }
      }
      return null;
    }

    final doc = await _conversationCollection.doc(conversationId).get();
    if (!doc.exists) {
      return null;
    }

    return Conversation.fromMap(
      _normalizeConversationMap(Map<String, Object?>.from(doc.data()!), docId: doc.id),
    );
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    if (_usePrefsStorage) {
      final messages = await _readMessagesFromPrefs();
      final filtered = messages.where((row) {
        return row['conversation_id'] == conversationId;
      }).toList();

      filtered.sort((a, b) {
        final aTime = (a['timestamp'] as int?) ?? 0;
        final bTime = (b['timestamp'] as int?) ?? 0;
        return aTime.compareTo(bTime);
      });

      return filtered.map(ChatMessage.fromMap).toList();
    }

    final rows = await _readMessagesFromFirestore();
    final filtered = rows.where((row) {
      return row['conversation_id'] == conversationId;
    }).toList();

    return filtered.map(ChatMessage.fromMap).toList();
  }

  Future<void> updateConversationLastMessage(
    String conversationId,
    String preview,
  ) async {
    if (_usePrefsStorage) {
      final conversations = await _readConversationsFromPrefs();
      for (var i = 0; i < conversations.length; i++) {
        if (conversations[i]['id'] == conversationId) {
          conversations[i] = {
            ...conversations[i],
            'last_message_time': DateTime.now().millisecondsSinceEpoch,
            'last_message_preview': preview,
          };
          break;
        }
      }
      await _writeConversationsToPrefs(conversations);
      return;
    }

    final doc = await _conversationCollection.doc(conversationId).get();
    if (!doc.exists) {
      return;
    }

    await doc.reference.update({
      'last_message_time': DateTime.now().millisecondsSinceEpoch,
      'last_message_preview': preview,
    });
  }

  Future<void> clearDatabase() async {
    if (_usePrefsStorage) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_conversationsPrefsKey);
      await prefs.remove(_messagesPrefsKey);
      await prefs.remove(_messagesNextIdPrefsKey);
      return;
    }

    final conversations = await _conversationCollection.get();
    for (final doc in conversations.docs) {
      await doc.reference.delete();
    }

    final messages = await _messageCollection.get();
    for (final doc in messages.docs) {
      await doc.reference.delete();
    }
  }
}
