import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cliente1.dart';
import 'pago.dart';
import 'perfilC.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int _selectedIndex = 2;
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: '¡Hola! He comprobado la disponibilidad para la excursión a la Charca Verde. Su permiso para la ruta ha sido aprobado y emitido oficialmente por el guarda forestal.',
      timestamp: DateTime(2025, 11, 24, 10, 38),
      isUser: false,
    ),
    ChatMessage(
      text: 'Permiso_ChV.pdf',
      timestamp: DateTime(2025, 11, 24, 10, 39),
      isUser: false,
      isFile: true,
      fileSize: '2.4 MB',
    ),
    ChatMessage(
      text: 'Muchísimas gracias por la rapidez. ¿Necesito imprimir una copia física o el PDF digital es suficiente para el control?',
      timestamp: DateTime(2025, 11, 24, 10, 41),
      isUser: true,
    ),
    ChatMessage(
      text: '¡Tu permiso está listo! Puedes tomar el formato digital!',
      timestamp: DateTime(2025, 11, 24, 10, 43),
      isUser: false,
    ),
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        text: _messageController.text.trim(),
        timestamp: DateTime.now(),
        isUser: true,
      ));
      _messageController.clear();
    });
    // Simulate reply after a delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Gracias por tu mensaje. Te responderemos pronto.',
          timestamp: DateTime.now(),
          isUser: false,
        ));
      });
    });
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GreenScape',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Soporte EN LÍNEA',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              'HOY, 24 NOV',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.green.shade800,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildMessageInput(),
        ],
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

  Widget _buildMessageBubble(ChatMessage message) {
    final alignment = message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start;
    final color = message.isUser ? Colors.green.shade50 : Colors.grey.shade100;
    final textColor = Colors.black87;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
      bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
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
                    Text(message.text, style: TextStyle(color: textColor)),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.insert_drive_file, color: Colors.green.shade700, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(message.fileSize ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
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
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // Handle file attachment
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Adjuntar archivo (simulado)')),
              );
            },
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
}

class ChatMessage {
  final String text;
  final DateTime timestamp;
  final bool isUser;
  final bool isFile;
  final String? fileSize;

  ChatMessage({
    required this.text,
    required this.timestamp,
    required this.isUser,
    this.isFile = false,
    this.fileSize,
  });
}