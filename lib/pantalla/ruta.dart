import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chatCliente.dart';
import 'cliente1.dart';
import 'perfilC.dart';
import 'pago.dart';

class RouteDetailScreen extends StatefulWidget {
  const RouteDetailScreen({super.key});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  int _selectedIndex = 1;
  DateTime _selectedDate = DateTime.now();
  int _peopleCount = 2;
  final double _pricePerPerson = 17.50;

  // Lista de equipo obligatorio (cada item tiene nombre y estado)
  final List<Map<String, dynamic>> _equipmentList = [
    {'name': 'Botas de senderismo', 'checked': false},
    {'name': '3L de agua', 'checked': false},
    {'name': 'Capa térmica', 'checked': false},
    {'name': 'Búfalo personal', 'checked': false},
  ];

  double get totalPrice => _peopleCount * _pricePerPerson;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _incrementPeople() {
    setState(() {
      _peopleCount++;
    });
  }

  void _decrementPeople() {
    if (_peopleCount > 1) {
      setState(() {
        _peopleCount--;
      });
    }
  }

  void _bookRoute() {
    // Acción de reserva
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reserva confirmada para ${_selectedDate.toLocal()} con $_peopleCount personas. Total: ${totalPrice.toStringAsFixed(2)}€'),
        duration: const Duration(seconds: 3),
      ),
    );
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

    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ClientProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(248, 250, 245, 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Volver',
                ),
              ),

              // Cabecera con temperatura y ciudad
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GreenScape',
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.thermostat, size: 16),
                        const SizedBox(width: 4),
                        const Text('22°C', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(width: 4),
                        Text('Cía de Apelido', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nombre de la ruta
              Text(
                'Refugio del Reloj',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Descripción
              Text(
                'Ruta clasica desde Villaluenga con salida desde el aparcamiento, continuando por el camino de pieda y empezamos la subida por la Cañada de Perarta para llegar al Portillon de Navazo giro a la derecha y continuamos subiendo por la cuesta de los pinos y seguir sendero hasta el Refugio del reloj. Vuelta a Villaluenga por el mismo recorrido. ¡Ruta muy recomendable para hacer en familia!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Estadísticas (Precio, Altura, Difícil)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('Precio', '3,75 km'),
                  _buildStatItem('Altura', '477 m'),
                  _buildStatItem('Difícil', '6 horas 52 min'),
                ],
              ),
              const SizedBox(height: 24),

              // Mapa (placeholder)
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 48, color: Colors.grey.shade600),
                      const SizedBox(height: 8),
                      Text(
                        'Mapa',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Información del tiempo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wb_sunny, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Información del tiempo: Acción: Contratar con tiendas a la orilla.',
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Lista de equipo obligatorio
              Text(
                'Lista de equipo obligatorio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              ..._equipmentList.map((item) => CheckboxListTile(
                    title: Text(item['name']),
                    value: item['checked'],
                    onChanged: (bool? value) {
                      setState(() {
                        item['checked'] = value ?? false;
                      });
                    },
                    activeColor: Colors.green,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  )),
              const SizedBox(height: 16),

              // Sección de reserva
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reserve su ruta',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Día del salida (selector de fecha)
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Día del Salado:', style: TextStyle(fontWeight: FontWeight.w500)),
                            Row(
                              children: [
                                Text(
                                  '${_selectedDate.day} / ${_selectedDate.month} / ${_selectedDate.year}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.calendar_today, size: 16),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Presupuesto (número de personas)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Presupuesto (incluidos):', style: TextStyle(fontWeight: FontWeight.w500)),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _decrementPeople,
                              icon: const Icon(Icons.remove_circle_outline),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text('$_peopleCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                            ),
                            IconButton(
                              onPressed: _incrementPeople,
                              icon: const Icon(Icons.add_circle_outline),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Crédito total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Crédito total:', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text(
                          '${totalPrice.toStringAsFixed(2)}€',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Botón Reservar ahora
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _bookRoute,
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
                  ],
                ),
              ),
              const SizedBox(height: 24),
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

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}