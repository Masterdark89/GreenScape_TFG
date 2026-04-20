import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/chat_database.dart';
import '../data/current_user_session.dart';
import '../data/user_database.dart';
import '../models/chat_message.dart';
import 'inventario.dart';
import 'perfilT.dart';
import 'trabajador1.dart';

class WorkerChatScreen extends StatefulWidget {
  const WorkerChatScreen({super.key});

  @override
  State<WorkerChatScreen> createState() => _WorkerChatScreenState();
}

class _WorkerChatScreenState extends State<WorkerChatScreen> {
  final int _selectedIndex = 2;
  Future<List<Conversation>> _conversationsFuture = Future.value(const <Conversation>[]);

  Future<void> _startConversationWithClient() async {
    final workerEmail = CurrentUserSession.instance.currentUserEmail;
    if (workerEmail == null || workerEmail.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión primero.')),
      );
      return;
    }

    final users = await UserDatabase.instance.getAllUsers();
    final clients = users.where((row) {
      final email = (row['email'] as String?)?.trim().toLowerCase();
      return email != null && email.isNotEmpty && email != workerEmail;
    }).toList()
      ..sort((a, b) {
        final aName = ((a['name'] as String?) ?? '').toLowerCase();
        final bName = ((b['name'] as String?) ?? '').toLowerCase();
        return aName.compareTo(bName);
      });

    if (!mounted) return;
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay clientes disponibles para iniciar chat.')),
      );
      return;
    }

    final searchController = TextEditingController();

    final selected = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final query = searchController.text.trim().toLowerCase();
            final filteredClients = query.isEmpty
                ? clients
                : clients.where((client) {
                    final clientName =
                        ((client['name'] as String?) ?? '').toLowerCase();
                    final clientEmail =
                        ((client['email'] as String?) ?? '').toLowerCase();
                    return clientName.contains(query) ||
                        clientEmail.contains(query);
                  }).toList();

            return AlertDialog(
              title: const Text('Seleccionar cliente'),
              content: SizedBox(
                width: double.maxFinite,
                height: 360,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o correo',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  setDialogState(() {});
                                },
                                icon: const Icon(Icons.close),
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filteredClients.isEmpty
                          ? Center(
                              child: Text(
                                'No hay clientes que coincidan.',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredClients.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (_, index) {
                                final client = filteredClients[index];
                                final clientName =
                                    ((client['name'] as String?)?.trim().isNotEmpty ?? false)
                                        ? (client['name'] as String)
                                        : 'Cliente';
                                final clientEmail = (client['email'] as String?) ?? '';

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green.shade100,
                                    child: Text(
                                      clientName[0].toUpperCase(),
                                      style: TextStyle(color: Colors.green.shade800),
                                    ),
                                  ),
                                  title: Text(clientName),
                                  subtitle: Text(clientEmail),
                                  onTap: () => Navigator.of(dialogContext).pop(client),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );

    searchController.dispose();

    if (selected == null) {
      return;
    }

    final clientEmail = ((selected['email'] as String?) ?? '').trim().toLowerCase();
    final clientName =
        ((selected['name'] as String?)?.trim().isNotEmpty ?? false)
            ? (selected['name'] as String)
            : 'Cliente';
    if (clientEmail.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente inválido.')),
      );
      return;
    }

    final workerData = await UserDatabase.instance.getUserByEmail(workerEmail);
    final workerName =
        ((workerData?['name'] as String?)?.trim().isNotEmpty ?? false)
            ? (workerData!['name'] as String)
            : 'Trabajador';

    final conversationId = await ChatDatabase.instance.getOrCreateConversation(
      clientEmail: clientEmail,
      clientName: clientName,
      workerEmail: workerEmail,
      workerName: workerName,
    );

    final conversations = await ChatDatabase.instance.getConversationsForWorker(workerEmail);
    if (conversations.isEmpty) {
      return;
    }

    final conversation = conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => conversations.first,
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkerIndividualChatScreen(conversation: conversation),
      ),
    ).then((_) {
      if (!mounted) return;
      setState(_loadConversations);
    });
  }

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
    _conversationsFuture = ChatDatabase.instance.getConversationsForWorker(userEmail);
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) {
      return;
    }

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InventoryScreen()),
      );
      return;
    }

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorkerMainScreen()),
      );
      return;
    }

    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorkerProfileScreen()),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat con Clientes',
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
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _startConversationWithClient,
                    icon: const Icon(Icons.add),
                    label: const Text('Iniciar conversación'),
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
              final otherName = conversation.clientName;
              final preview = conversation.lastMessagePreview;
              final lastTime = conversation.lastMessageTime;

              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkerIndividualChatScreen(
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
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : 'C',
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
        onPressed: _startConversationWithClient,
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
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Reservas',
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

class WorkerIndividualChatScreen extends StatefulWidget {
  const WorkerIndividualChatScreen({
    super.key,
    required this.conversation,
  });

  final Conversation conversation;

  @override
  State<WorkerIndividualChatScreen> createState() =>
      _WorkerIndividualChatScreenState();
}

class _WorkerIndividualChatScreenState extends State<WorkerIndividualChatScreen> {
  late Future<List<ChatMessage>> _messagesFuture;
  final TextEditingController _messageController = TextEditingController();
  late ScrollController _scrollController;
  String _clientPhone = '-';

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
    _loadClientPhone();
  }

  void _loadMessages() {
    _messagesFuture = ChatDatabase.instance.getMessages(widget.conversation.id);
  }

  Future<void> _loadClientPhone() async {
    final clientData =
        await UserDatabase.instance.getUserByEmail(widget.conversation.clientEmail);
    final phone = (clientData?['phone'] as String?)?.trim();
    if (!mounted) return;
    setState(() {
      _clientPhone = (phone == null || phone.isEmpty) ? '-' : phone;
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userEmail = CurrentUserSession.instance.currentUserEmail;
    if (userEmail == null) return;

    final message = ChatMessage(
      conversationId: widget.conversation.id,
      senderEmail: userEmail,
      senderName: 'Trabajador',
      senderRole: 'trabajador',
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

    final attachmentName = file.name;
    final attachmentExtension = file.extension?.trim().toLowerCase();
    final message = ChatMessage(
      conversationId: widget.conversation.id,
      senderEmail: userEmail,
      senderName: 'Trabajador',
      senderRole: 'trabajador',
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
              widget.conversation.clientName,
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.conversation.clientEmail,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Text(
              _clientPhone,
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
    final isFromWorker = message.senderRole == 'trabajador';
    return Align(
      alignment: isFromWorker ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isFromWorker ? Colors.green.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
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
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
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
            color: Colors.green.shade700,
            onPressed: _pickAndSendAttachment,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: Colors.green.shade700,
            onPressed: _sendMessage,
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
