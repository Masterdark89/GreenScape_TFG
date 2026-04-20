import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/route_catalog.dart';
import 'ruta.dart';
import 'chatCliente.dart';
import 'pago.dart';
import 'perfilC.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
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
      body: const GreenScapeContent(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
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
}

enum _SortField { difficulty, duration, elevation }

enum _SortDirection { none, desc, asc }

class GreenScapeContent extends StatefulWidget {
  const GreenScapeContent({super.key});

  @override
  State<GreenScapeContent> createState() => _GreenScapeContentState();
}

class _GreenScapeContentState extends State<GreenScapeContent> {
  final List<Map<String, dynamic>> _routes =
      kExploreRoutes.map((route) => Map<String, dynamic>.from(route)).toList();

  String _searchQuery = '';
  _SortField? _activeSortField;
  _SortDirection _sortDirection = _SortDirection.none;

  List<Map<String, dynamic>> get _visibleRoutes {
    final String query = _normalizeForSearch(_searchQuery.trim());

    final List<Map<String, dynamic>> filtered = _routes.where((route) {
      if (query.isEmpty) {
        return true;
      }

      final String routeName = _normalizeForSearch(route['name'] as String);
      final String difficulty = _normalizeForSearch(route['difficulty'] as String);
      return routeName.contains(query) || difficulty.contains(query);
    }).toList();

    if (_activeSortField == null || _sortDirection == _SortDirection.none) {
      return filtered;
    }

    int comparator(Map<String, dynamic> a, Map<String, dynamic> b) {
      switch (_activeSortField!) {
        case _SortField.difficulty:
          return _difficultyRank(a['difficulty']).compareTo(
            _difficultyRank(b['difficulty']),
          );
        case _SortField.duration:
          return _extractNumber(a['duration']).compareTo(
            _extractNumber(b['duration']),
          );
        case _SortField.elevation:
          return _extractNumber(a['elevation']).compareTo(
            _extractNumber(b['elevation']),
          );
      }
    }

    filtered.sort(comparator);
    if (_sortDirection == _SortDirection.desc) {
      return filtered.reversed.toList();
    }
    return filtered;
  }

  String _normalizeForSearch(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        physics: const BouncingScrollPhysics(),
        children: [
          // Header
          const SizedBox(height: 8),
          Text(
            'GreenScape',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Encuentra tu siguiente cima',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // Search bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Busca tu ruta...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 16),

          // Filter chips (horizontal scroll)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Dificultad',
                  field: _SortField.difficulty,
                ),
                const SizedBox(width: 12),
                _buildFilterChip(
                  label: 'Duración',
                  field: _SortField.duration,
                ),
                const SizedBox(width: 12),
                _buildFilterChip(
                  label: 'Elevación',
                  field: _SortField.elevation,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Route cards
          ..._visibleRoutes.map(
                (entry) => _buildRouteCard(
                  context,
                  entry,
                ),
              ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required _SortField field,
  }) {
    final bool isActive = _activeSortField == field;
    final bool showArrow = isActive && _sortDirection != _SortDirection.none;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _toggleSort(field),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.green.shade800 : Colors.black87,
                ),
              ),
              if (showArrow) ...[
                const SizedBox(width: 6),
                Icon(
                  _sortDirection == _SortDirection.desc
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  size: 16,
                  color: Colors.green.shade800,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSort(_SortField field) {
    setState(() {
      if (_activeSortField != field) {
        _activeSortField = field;
        _sortDirection = _SortDirection.asc;
        return;
      }

      if (_sortDirection == _SortDirection.asc) {
        _sortDirection = _SortDirection.desc;
        return;
      }

      if (_sortDirection == _SortDirection.desc) {
        _sortDirection = _SortDirection.none;
        _activeSortField = null;
        return;
      }

      _sortDirection = _SortDirection.asc;
    });
  }

  int _difficultyRank(String difficulty) {
    final String value = difficulty.toLowerCase();

    if (value.contains('dificil') || value.contains('difícil')) {
      return 3;
    }
    if (value.contains('medio') || value.contains('moderad')) {
      return 2;
    }
    return 1;
  }

  double _extractNumber(String text) {
    final RegExpMatch? match = RegExp(r'\d+(?:\.\d+)?').firstMatch(text);
    if (match == null) {
      return 0;
    }
    return double.tryParse(match.group(0) ?? '') ?? 0;
  }

  Widget _buildRouteCard(
    BuildContext context,
    Map<String, dynamic> route,
  ) {
    final Color difficultyColor = _difficultyColor(route['difficulty']);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 190,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      route['imagePath'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 42,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.20),
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: difficultyColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          route['difficulty'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Text(
                        route['name'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.05,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn('DISTANCIA', route['distance']),
                _buildStatColumn('DURACIÓN', route['duration']),
                _buildStatColumn('DESNIVEL', route['elevation']),
              ],
            ),
            const SizedBox(height: 20),
            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final RouteDetailData detail = buildRouteDetailFromRoute(route);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteDetailScreen(detail: detail),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('VER RUTA'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _difficultyColor(String difficulty) {
    final String value = difficulty.toLowerCase();

    if (value.contains('dificil') || value.contains('difícil')) {
      return Colors.red.shade700;
    }

    if (value.contains('medio') || value.contains('moderad')) {
      return Colors.orange.shade700;
    }

    return Colors.green.shade700;
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
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