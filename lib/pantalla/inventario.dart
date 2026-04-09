import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chatTrabajador.dart';
import 'perfilT.dart';
import 'trabajador1.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todo';
  int _currentPage = 1;
  final int _itemsPerPage = 4;

  final List<InventoryItem> _allItems = [
    InventoryItem(
      name: 'Botas Travesía',
      description: 'Talla: 41-42',
      category: 'Botas',
      stockStatus: 'EN ESTOCK',
      stockStatusColor: Colors.green,
      currentUnits: 24,
      totalUnits: 30,
    ),
    InventoryItem(
      name: 'Tienda Decathlon',
      description: 'Tienda 4 adultos',
      category: 'Tiendas',
      stockStatus: 'EN ESTOCK',
      stockStatusColor: Colors.green,
      currentUnits: 12,
      totalUnits: 12,
    ),
    InventoryItem(
      name: 'Mochila 65L',
      description: 'Marco grande',
      category: 'Mochilas',
      stockStatus: 'MANTENIMIENTO',
      stockStatusColor: Colors.orange,
      currentUnits: 2,
      totalUnits: 15,
    ),
    InventoryItem(
      name: 'Saco adulto',
      description: 'Pluma de pato',
      category: 'Sacos',
      stockStatus: 'EN ESTOCK',
      stockStatusColor: Colors.green,
      currentUnits: 8,
      totalUnits: 10,
    ),
    // Additional items for pagination demo
    InventoryItem(
      name: 'Crampones',
      description: 'Acero inoxidable',
      category: 'Botas',
      stockStatus: 'BAJO STOCK',
      stockStatusColor: Colors.red,
      currentUnits: 3,
      totalUnits: 20,
    ),
    InventoryItem(
      name: 'Linterna frontal',
      description: '300 lúmenes',
      category: 'Baz',
      stockStatus: 'EN ESTOCK',
      stockStatusColor: Colors.green,
      currentUnits: 18,
      totalUnits: 25,
    ),
    InventoryItem(
      name: 'Cuerda dinámica',
      description: '60m, 10.2mm',
      category: 'Baz',
      stockStatus: 'MANTENIMIENTO',
      stockStatusColor: Colors.orange,
      currentUnits: 4,
      totalUnits: 8,
    ),
    InventoryItem(
      name: 'Casco Petzl',
      description: 'Talla única',
      category: 'Baz',
      stockStatus: 'EN ESTOCK',
      stockStatusColor: Colors.green,
      currentUnits: 14,
      totalUnits: 20,
    ),
    InventoryItem(
      name: 'Tienda 3 estaciones',
      description: 'Para 2 personas',
      category: 'Tiendas',
      stockStatus: 'EN ESTOCK',
      stockStatusColor: Colors.green,
      currentUnits: 9,
      totalUnits: 12,
    ),
  ];

  List<InventoryItem> get _filteredItems {
    List<InventoryItem> items = _allItems;
    // Filter by search
    if (_searchController.text.isNotEmpty) {
      items = items.where((item) =>
          item.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    }
    // Filter by category
    if (_selectedCategory != 'Todo') {
      items = items.where((item) => item.category == _selectedCategory).toList();
    }
    return items;
  }

  List<InventoryItem> get _paginatedItems {
    int start = (_currentPage - 1) * _itemsPerPage;
    int end = start + _itemsPerPage;
    if (start >= _filteredItems.length) return [];
    if (end > _filteredItems.length) end = _filteredItems.length;
    return _filteredItems.sublist(start, end);
  }

  int get _totalPages => (_filteredItems.length / _itemsPerPage).ceil();

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(1, _totalPages);
    });
  }

  void _addMerchandise() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Añadir mercancía (próximamente)')),
    );
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) {
      return;
    }

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorkerMainScreen()),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(248, 250, 245, 1),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'GreenScape',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CENTRO LOGÍSTICO',
                    style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gestionar el equipo listo para la ruta, controlar los ciclos de mantenimiento y garantizar la seguridad de los exploradores en todas las expediciones.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _addMerchandise,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Añadir mercancía'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                    onChanged: (_) => setState(() => _currentPage = 1),
                  ),
                  const SizedBox(height: 12),
                  // Category chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('Todo'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Botas'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Tiendas'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Baz'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Mochilas'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Sacos'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Inventory list
            Expanded(
              child: _paginatedItems.isEmpty
                  ? const Center(child: Text('No hay artículos'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _paginatedItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _paginatedItems[index];
                        return _buildInventoryCard(item);
                      },
                    ),
            ),
            // Pagination
            if (_totalPages > 1)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    for (int i = 1; i <= _totalPages; i++)
                      GestureDetector(
                        onTap: () => _goToPage(i),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _currentPage == i ? Colors.green.shade700 : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$i',
                            style: TextStyle(
                              color: _currentPage == i ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
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

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = label;
          _currentPage = 1;
        });
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.green.shade100,
      checkmarkColor: Colors.green,
    );
  }

  Widget _buildInventoryCard(InventoryItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.stockStatusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: item.stockStatusColor),
                    const SizedBox(width: 4),
                    Text(
                      item.stockStatus,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: item.stockStatusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.inventory, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${item.currentUnits} / ${item.totalUnits} Unidades',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.category,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class InventoryItem {
  final String name;
  final String description;
  final String category;
  final String stockStatus;
  final Color stockStatusColor;
  final int currentUnits;
  final int totalUnits;

  InventoryItem({
    required this.name,
    required this.description,
    required this.category,
    required this.stockStatus,
    required this.stockStatusColor,
    required this.currentUnits,
    required this.totalUnits,
  });
}