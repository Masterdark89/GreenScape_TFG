import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chatTrabajador.dart';
import 'inventario.dart';
import 'perfilT.dart';

class WorkerMainScreen extends StatefulWidget {
  const WorkerMainScreen({super.key});

  @override
  State<WorkerMainScreen> createState() => _WorkerMainScreenState();
}

class _WorkerMainScreenState extends State<WorkerMainScreen> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
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

    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorkerChatScreen()),
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                'GreenScape',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 20),

              // Tarjetas de métricas (reservas, mercancías, faltas)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'RESERVAS DEL DIA DE HOY',
                      value: '42',
                      backgroundColor: Colors.green.shade50,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'MERCANCIAS PENDIENTES',
                      value: '08',
                      subtitle: 'Hora de llegada: 14:00',
                      backgroundColor: Colors.orange.shade50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMetricCard(
                title: 'FALTAS DE INVENTARIO',
                value: '03',
                subtitle: 'Bajo Stock: Cascos de Seguridad',
                backgroundColor: Colors.red.shade50,
                fullWidth: true,
              ),
              const SizedBox(height: 24),

              // Rutas Pendientes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rutas Pendientes',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Acción "Mostrar Todo"
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mostrar todas las rutas')),
                      );
                    },
                    child: const Text(
                      'Mostrar Todo',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Lista de rutas pendientes
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pendingRoutes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final route = _pendingRoutes[index];
                  return _buildRouteCard(
                    routeName: route['name']!,
                    userName: route['user']!,
                    time: route['time']!,
                  );
                },
              ),
              const SizedBox(height: 24),

              _buildQuickAccessField(
                icon: Icons.inventory,
                title: 'Inventario',
                subtitle: 'Acceder al centro logístico',
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const InventoryScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildQuickAccessField(
                icon: Icons.wb_sunny,
                title: 'Clima',
                subtitle: 'Soleado · 24°C · Viento 12 km/h',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Clima actualizado correctamente')),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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

  // Datos de ejemplo para las rutas pendientes
  final List<Map<String, String>> _pendingRoutes = [
    {
      'name': 'Refugio del Reloj',
      'user': 'Lucky Luke',
      'time': 'Hoy, 09:30',
    },
    {
      'name': 'Charca Verde',
      'user': 'Darth Vader',
      'time': 'Hoy, 11:15',
    },
    {
      'name': 'Reloj y Simancon',
      'user': 'Indiana Jones',
      'time': 'Mañana, 01:45',
    },
  ];

  Widget _buildMetricCard({
    required String title,
    required String value,
    String? subtitle,
    Color? backgroundColor,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteCard({
    required String routeName,
    required String userName,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            routeName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userName,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessField({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.green.shade700, size: 24),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
