import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/chat_database.dart';
import '../data/current_user_session.dart';
import '../data/user_database.dart';
import '../models/chat_message.dart';
import 'cliente1.dart';
import 'pago.dart';
import 'perfilC.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final int _selectedIndex = 2;
  Future<List<Conversation>> _conversationsFuture = Future.value(const <Conversation>[]);

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    final userEmail = CurrentUserSession.instance.currentUserEmail;
    if (userEmail == null) {
      _conversationsFuture = Future.value(const <Conversation>[]);
      return;
    }
    _conversationsFuture = ChatDatabase.instance.getConversationsForUser(userEmail);
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) {
      return;
    }

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CheckoutScreen()),
      );
      return;
    }

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
      return;
    }

    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ClientProfileScreen()),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat con GreenScape',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green.shade800,
      ),
      body: FutureBuilder<List<Conversation>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sin conversaciones aún',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _startNewConversation,
                    icon: const Icon(Icons.add),
                    label: const Text('Iniciar Chat con Soporte'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final otherName = conversation.workerName;
              final preview = conversation.lastMessagePreview;
              final lastTime = conversation.lastMessageTime;

              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClientIndividualChatScreen(
                        conversation: conversation,
                      ),
                    ),
                  ).then((_) {
                    setState(() {
                      _loadConversations();
                    });
                  });
                },
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade700,
                  child: Text(
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : 'W',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(otherName),
                subtitle: Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(lastTime),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (conversation.unreadCount > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${conversation.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewConversation,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Reservas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explorar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  void _startNewConversation() {
    final rootContext = context;
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Iniciar nuevo chat'),
        content: const Text('Se abrirá una conversación con el equipo de soporte de GreenScape.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final userEmail = CurrentUserSession.instance.currentUserEmail;
              if (userEmail == null) {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(content: Text('Debes iniciar sesión primero')),
                );
                return;
              }

              final clientData = await UserDatabase.instance.getUserByEmail(userEmail);
              final clientName =
                  ((clientData?['name'] as String?)?.trim().isNotEmpty ?? false)
                      ? (clientData!['name'] as String)
                      : 'Cliente';

              // Crear conversación con soporte
              final conversationId = await ChatDatabase.instance.getOrCreateConversation(
                clientEmail: userEmail,
                clientName: clientName,
                workerEmail: ChatDatabase.supportWorkerEmail,
                workerName: ChatDatabase.supportWorkerName,
              );

              // Buscar la conversación recién creada
              final conversations = await ChatDatabase.instance.getConversationsForUser(userEmail);
              final newConversation = conversations.firstWhere(
                (c) => c.id == conversationId,
                orElse: () => conversations.first,
              );

              if (mounted) {
                Navigator.push(
                  rootContext,
                  MaterialPageRoute(
                    builder: (_) => ClientIndividualChatScreen(
                      conversation: newConversation,
                    ),
                  ),
                ).then((_) {
                  setState(() {
                    _loadConversations();
                  });
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Ayer';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}

class ClientIndividualChatScreen extends StatefulWidget {
  const ClientIndividualChatScreen({
    super.key,
    required this.conversation,
  });

  final Conversation conversation;

  @override
  State<ClientIndividualChatScreen> createState() =>
      _ClientIndividualChatScreenState();
}

class _ClientIndividualChatScreenState extends State<ClientIndividualChatScreen> {
  late Future<List<ChatMessage>> _messagesFuture;
  final TextEditingController _messageController = TextEditingController();
  late ScrollController _scrollController;

  static const List<String> _imageExtensions = <String>[
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadMessages();
  }

  void _loadMessages() {
    _messagesFuture = ChatDatabase.instance.getMessages(widget.conversation.id);
  }

  Future<String> _resolveClientDisplayName() async {
    final userEmail = CurrentUserSession.instance.currentUserEmail;
    if (userEmail == null || userEmail.isEmpty) {
      return 'Cliente';
    }

    final userData = await UserDatabase.instance.getUserByEmail(userEmail);
    final name = (userData?['name'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      return 'Cliente';
    }
    return name;
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userEmail = CurrentUserSession.instance.currentUserEmail;
    if (userEmail == null) return;
    final clientName = await _resolveClientDisplayName();

    final message = ChatMessage(
      conversationId: widget.conversation.id,
      senderEmail: userEmail,
      senderName: clientName,
      senderRole: 'cliente',
      text: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    await ChatDatabase.instance.insertMessage(message);
    await ChatDatabase.instance.updateConversationLastMessage(
      widget.conversation.id,
      message.text,
    );

    _messageController.clear();
    setState(() {
      _loadMessages();
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool _isImageAttachment(ChatMessage message) {
    final extension = (message.fileExtension ?? '').trim().toLowerCase();
    return _imageExtensions.contains(extension);
  }

  Future<void> _pickAndSendAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    final userEmail = CurrentUserSession.instance.currentUserEmail;
    if (bytes == null || userEmail == null || userEmail.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo adjuntar el archivo.')),
      );
      return;
    }

    final clientName = await _resolveClientDisplayName();

    final attachmentName = file.name;
    final attachmentExtension = file.extension?.trim().toLowerCase();
    final message = ChatMessage(
      conversationId: widget.conversation.id,
      senderEmail: userEmail,
      senderName: clientName,
      senderRole: 'cliente',
      text: attachmentName,
      timestamp: DateTime.now(),
      isFile: true,
      fileName: attachmentName,
      fileExtension: attachmentExtension,
      fileSize: _formatFileSize(file.size),
      fileBytesBase64: base64Encode(bytes),
    );

    await ChatDatabase.instance.insertMessage(message);
    await ChatDatabase.instance.updateConversationLastMessage(
      widget.conversation.id,
      'Archivo: $attachmentName',
    );

    if (!mounted) return;
    setState(() {
      _loadMessages();
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.conversation.workerName,
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.conversation.workerEmail,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green.shade800,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<ChatMessage>>(
              future: _messagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Inicia la conversación',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isFromClient = message.senderRole == 'cliente';
    final alignment = isFromClient ? MainAxisAlignment.end : MainAxisAlignment.start;
    final color = isFromClient ? Colors.green.shade50 : Colors.grey.shade100;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isFromClient ? const Radius.circular(16) : const Radius.circular(4),
      bottomRight: isFromClient ? const Radius.circular(4) : const Radius.circular(16),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: alignment,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: borderRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isFile)
                    _buildFileWidget(message)
                  else
                    Text(message.text),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileWidget(ChatMessage message) {
    final bytes = message.fileBytesBase64 == null ? null : base64Decode(message.fileBytesBase64!);
    final isImage = _isImageAttachment(message) && bytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              width: 220,
              fit: BoxFit.cover,
            ),
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? message.text,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    message.fileSize ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        if (isImage) ...[
          const SizedBox(height: 8),
          Text(
            message.fileName ?? message.text,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            message.fileSize ?? '',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _pickAndSendAttachment,
            color: Colors.grey.shade600,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Mensaje...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            color: Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}