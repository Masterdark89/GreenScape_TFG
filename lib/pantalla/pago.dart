import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chatCliente.dart';
import 'cliente1.dart';
import 'perfilC.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedIndex = 0;
  DateTime _selectedDate = DateTime(2026, 11, 24);
  int _clientCount = 2;
  String _selectedRoute = 'Refugio del Reloj';
  final List<String> _availableRoutes = const [
    'Refugio del Reloj',
    'Reloj y Simancón',
    'Charca Verde',
  ];
  final double _pricePerPerson = 17.50; // Precio base por persona (ajústalo)

  double get _totalCost => _clientCount * _pricePerPerson;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _incrementClients() {
    setState(() {
      _clientCount++;
    });
  }

  void _decrementClients() {
    if (_clientCount > 1) {
      setState(() {
        _clientCount--;
      });
    }
  }

  void _bookNow() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reserva de $_selectedRoute para $_clientCount personas el ${_selectedDate.toLocal()}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) {
      return;
    }

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
      return;
    }

    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
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

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(248, 250, 245, 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'GreenScape',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 20),

              // Título de la pantalla
              Text(
                'Reserve su ruta',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 24),

              // Día de salida
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DIA DE SALIDA',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Row(
                        children: [
                          Text(
                            '${_selectedDate.day} / ${_selectedDate.month} / ${_selectedDate.year}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.calendar_today, size: 16, color: Colors.green.shade700),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Número de clientes
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'NUMERO DE CLIENTES',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _decrementClients,
                          icon: const Icon(Icons.remove),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          splashRadius: 20,
                        ),
                        Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text(
                            '$_clientCount',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          onPressed: _incrementClients,
                          icon: const Icon(Icons.add),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Selector de rutas
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRoute,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: _availableRoutes
                        .map(
                          (route) => DropdownMenuItem<String>(
                            value: route,
                            child: Text(route),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedRoute = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Coste total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Coste total',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${_totalCost.toStringAsFixed(2)}€',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Botón Reservar ahora
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _bookNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Reservar ahora', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),

              // Texto inclusión
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Incluye guía profesional, equipo de seguridad y permisos para el parque nacional.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Reservas'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explorar'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}