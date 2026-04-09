import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'inventario.dart';
import 'perfilT.dart';
import 'trabajador1.dart';

class WorkerChatScreen extends StatefulWidget {
	const WorkerChatScreen({super.key});

	@override
	State<WorkerChatScreen> createState() => _WorkerChatScreenState();
}

class _WorkerChatScreenState extends State<WorkerChatScreen> {
	int _selectedIndex = 2;
	final TextEditingController _messageController = TextEditingController();
	final List<_WorkerChatMessage> _messages = [
		_WorkerChatMessage(
			text: 'Recuerda revisar las reservas de la ruta de las 09:30.',
			timestamp: DateTime(2026, 3, 26, 9, 5),
			isUser: false,
		),
		_WorkerChatMessage(
			text: 'Perfecto, ahora mismo actualizo también el inventario de cascos.',
			timestamp: DateTime(2026, 3, 26, 9, 7),
			isUser: true,
		),
	];

	void _sendMessage() {
		if (_messageController.text.trim().isEmpty) return;
		setState(() {
			_messages.add(
				_WorkerChatMessage(
					text: _messageController.text.trim(),
					timestamp: DateTime.now(),
					isUser: true,
				),
			);
			_messageController.clear();
		});
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
					'Chat trabajador',
					style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
				),
				backgroundColor: Colors.white,
				foregroundColor: Colors.green.shade800,
			),
			body: Column(
				children: [
					Expanded(
						child: ListView.builder(
							padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
							itemCount: _messages.length,
							itemBuilder: (context, index) {
								final message = _messages[index];
								return _buildMessageBubble(message);
							},
						),
					),
					Container(
						padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
						child: Row(
							children: [
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
					),
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

	Widget _buildMessageBubble(_WorkerChatMessage message) {
		final isUser = message.isUser;
		return Align(
			alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
			child: Container(
				margin: const EdgeInsets.symmetric(vertical: 4),
				padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
				decoration: BoxDecoration(
					color: isUser ? Colors.green.shade50 : Colors.grey.shade100,
					borderRadius: BorderRadius.circular(12),
				),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(message.text),
						const SizedBox(height: 4),
						Text(
							'${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
							style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
						),
					],
				),
			),
		);
	}
}

class _WorkerChatMessage {
	final String text;
	final DateTime timestamp;
	final bool isUser;

	_WorkerChatMessage({
		required this.text,
		required this.timestamp,
		required this.isUser,
	});
}
