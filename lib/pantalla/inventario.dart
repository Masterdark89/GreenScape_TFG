import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/inventory_database.dart';
import '../data/route_equipment_repository.dart';
import '../models/inventory_item.dart';
import 'chatTrabajador.dart';
import 'perfilT.dart';
import 'trabajador1.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({
    super.key,
    this.initialStockFilter = 'Todo',
  });

  final String initialStockFilter;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todo';
  String _selectedStockFilter = 'Todo';
  String _selectedRentalFilter = 'Todo';
  int _currentPage = 1;
  final int _itemsPerPage = 4;
  final InventoryDatabase _inventoryDatabase = InventoryDatabase.instance;
  final RouteEquipmentRepository _routeEquipmentRepository =
      RouteEquipmentRepository.instance;
  final List<InventoryItem> _allItems = [];
  bool _isLoading = true;
  String? _loadError;

  static const List<String> _categoryOptions = <String>[
    'Todo',
    'Botas',
    'Tiendas',
    'Baz',
    'Mochilas',
    'Sacos',
    'Proteccion',
  ];

  List<DropdownMenuItem<String>> _buildCategoryDropdownItems({
    String? currentValue,
  }) {
    final categories = <String>{
      ..._categoryOptions,
      if (currentValue != null && currentValue.isNotEmpty) currentValue,
    }.toList();

    return categories
        .map((category) => DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            ))
        .toList();
  }

  List<InventoryItem> get _defaultItems => const [
        InventoryItem(
          name: 'Botas Travesía',
          description: 'Talla: 41-42',
          category: 'Botas',
          stockStatus: 'EN STOCK',
          currentUnits: 24,
          totalUnits: 30,
        ),
        InventoryItem(
          name: 'Tienda Decathlon',
          description: 'Tienda 4 adultos',
          category: 'Tiendas',
          stockStatus: 'EN STOCK',
          currentUnits: 12,
          totalUnits: 12,
        ),
        InventoryItem(
          name: 'Mochila 65L',
          description: 'Marco grande',
          category: 'Mochilas',
          stockStatus: 'MANTENIMIENTO',
          currentUnits: 2,
          totalUnits: 15,
        ),
        InventoryItem(
          name: 'Saco adulto',
          description: 'Pluma de pato',
          category: 'Sacos',
          stockStatus: 'EN STOCK',
          currentUnits: 8,
          totalUnits: 10,
        ),
        InventoryItem(
          name: 'Crampones',
          description: 'Acero inoxidable',
          category: 'Botas',
          stockStatus: 'BAJO STOCK',
          currentUnits: 3,
          totalUnits: 20,
        ),
        InventoryItem(
          name: 'Linterna frontal',
          description: '300 lúmenes',
          category: 'Baz',
          stockStatus: 'EN STOCK',
          currentUnits: 18,
          totalUnits: 25,
        ),
        InventoryItem(
          name: 'Cuerda dinámica',
          description: '60m, 10.2mm',
          category: 'Baz',
          stockStatus: 'MANTENIMIENTO',
          currentUnits: 4,
          totalUnits: 8,
        ),
        InventoryItem(
          name: 'Casco Petzl',
          description: 'Talla única',
          category: 'Baz',
          stockStatus: 'EN STOCK',
          currentUnits: 14,
          totalUnits: 20,
        ),
        InventoryItem(
          name: 'Tienda 3 estaciones',
          description: 'Para 2 personas',
          category: 'Tiendas',
          stockStatus: 'EN STOCK',
          currentUnits: 9,
          totalUnits: 12,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _selectedStockFilter = widget.initialStockFilter;
    _loadItemsFromDatabase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItemsFromDatabase() async {
    try {
      await _inventoryDatabase.seedIfEmpty(_defaultItems);
      await _inventoryDatabase.ensureRouteSelectableItems();
      await _inventoryDatabase.catalogExistingItemsByKnownCategories();
      final items = await _inventoryDatabase.getAllItems();

      if (!mounted) return;
      setState(() {
        _allItems
          ..clear()
          ..addAll(items);
        _isLoading = false;
        _loadError = null;
        _currentPage = 1;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
      debugPrint('Error loading inventory from database: $error');
    }
  }

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
    // Filter by stock status (can be combined with category/search)
    if (_selectedStockFilter != 'Todo') {
      final selected = _normalizeStockStatus(_selectedStockFilter).toUpperCase();
      items = items.where((item) {
        final status = _normalizeStockStatus(item.stockStatusDisplay).toUpperCase();
        return status == selected;
      }).toList();
    }
    // Filter by items currently pending rental
    if (_selectedRentalFilter == 'En uso') {
      items = items.where((item) => item.pendingRentalUnits > 0).toList();
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

  int get _totalPages {
    if (_filteredItems.isEmpty) return 1;
    return (_filteredItems.length / _itemsPerPage).ceil();
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(1, _totalPages);
    });
  }

  String _normalizeStockStatus(String status) {
    return InventoryItem.normalizeStatus(status);
  }

  String _deriveStockStatus({
    required int currentUnits,
    required int totalUnits,
  }) {
    return InventoryItem.deriveStockStatus(
      currentUnits: currentUnits,
      totalUnits: totalUnits,
    );
  }

  Future<void> _addMerchandise() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final currentUnitsController = TextEditingController();
    final totalUnitsController = TextEditingController();

    String selectedCategory = 'Botas';

    final action = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Añadir mercancía'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: _buildCategoryDropdownItems(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedCategory = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: currentUnitsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Unidades actuales'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: totalUnitsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Unidades totales'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'cancel'),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, 'save'),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (action != 'save') {
      return;
    }

    final currentUnits = int.tryParse(currentUnitsController.text.trim());
    final totalUnits = int.tryParse(totalUnitsController.text.trim());

    if (nameController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        currentUnits == null ||
        totalUnits == null ||
        currentUnits < 0 ||
        totalUnits <= 0 ||
        currentUnits > totalUnits) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa unidades: totales > 0 y actuales entre 0 y total.'),
        ),
      );
      return;
    }

    try {
      await _inventoryDatabase.insertItem(
        InventoryItem(
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          category: selectedCategory,
          stockStatus: _deriveStockStatus(
            currentUnits: currentUnits,
            totalUnits: totalUnits,
          ),
          currentUnits: currentUnits,
          totalUnits: totalUnits,
        ),
      );

      await _loadItemsFromDatabase();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artículo guardado en la base de datos.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando en la base de datos: $error')),
      );
    }
  }

  Future<void> _editMerchandise(InventoryItem item) async {
    final nameController = TextEditingController(text: item.name);
    final descriptionController = TextEditingController(text: item.description);
    final currentUnitsController = TextEditingController(text: item.currentUnits.toString());
    final totalUnitsController = TextEditingController(text: item.totalUnits.toString());

    String selectedCategory = item.category;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar artículo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: _buildCategoryDropdownItems(currentValue: selectedCategory),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedCategory = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: currentUnitsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Unidades actuales'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: totalUnitsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Unidades totales'),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pendiente de alquilar: ${item.pendingRentalUnits}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave != true) {
      return;
    }

    final currentUnits = int.tryParse(currentUnitsController.text.trim());
    final totalUnits = int.tryParse(totalUnitsController.text.trim());

    if (nameController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        currentUnits == null ||
        totalUnits == null ||
        currentUnits < 0 ||
        totalUnits <= 0 ||
        currentUnits > totalUnits) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa unidades: totales > 0 y actuales entre 0 y total.'),
        ),
      );
      return;
    }

    try {
      await _inventoryDatabase.updateItem(
        InventoryItem(
          id: item.id,
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          category: selectedCategory,
          stockStatus: _deriveStockStatus(
            currentUnits: currentUnits,
            totalUnits: totalUnits,
          ),
          currentUnits: currentUnits,
          totalUnits: totalUnits,
          pendingRentalUnits: item.pendingRentalUnits,
        ),
      );

      await _loadItemsFromDatabase();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artículo actualizado correctamente.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error actualizando el artículo: $error')),
      );
    }
  }

  Future<void> _deleteMerchandise(InventoryItem item) async {
    if (item.id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede eliminar un artículo sin identificador.'),
        ),
      );
      return;
    }

    if (item.pendingRentalUnits > 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se puede eliminar un artículo con unidades pendientes de alquilar.',
          ),
        ),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar artículo'),
          content: Text(
            '¿Seguro que quieres eliminar "${item.name}"? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _inventoryDatabase.deleteItem(item.id!);
      await _loadItemsFromDatabase();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artículo eliminado correctamente.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error eliminando el artículo: $error')),
      );
    }
  }

  Future<void> _editRouteInventory() async {
    final inventoryItemNames = _allItems
        .map((item) => item.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (inventoryItemNames.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay artículos en inventario para asociar a rutas.'),
        ),
      );
      return;
    }

    final result = await showDialog<_RouteEquipmentEditResult>(
      context: context,
      builder: (_) => _RouteInventoryEditorDialog(
        inventoryItemNames: inventoryItemNames,
        repository: _routeEquipmentRepository,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Equipamiento de ${result.routeName} actualizado (${result.equipmentCount} elementos).',
        ),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _editRouteInventory,
                          icon: const Icon(Icons.route_outlined, size: 18),
                          label: const Text('Editar inventario de ruta'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green.shade700,
                            side: BorderSide(color: Colors.green.shade300),
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
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Categoría',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Todo', child: Text('Todo')),
                            DropdownMenuItem(value: 'Botas', child: Text('Botas')),
                            DropdownMenuItem(value: 'Tiendas', child: Text('Tiendas')),
                            DropdownMenuItem(value: 'Baz', child: Text('Baz')),
                            DropdownMenuItem(value: 'Mochilas', child: Text('Mochilas')),
                            DropdownMenuItem(value: 'Sacos', child: Text('Sacos')),
                            DropdownMenuItem(value: 'Proteccion', child: Text('Proteccion')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedCategory = value;
                              _currentPage = 1;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedStockFilter,
                          decoration: InputDecoration(
                            labelText: 'Stock',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Todo', child: Text('Todo')),
                            DropdownMenuItem(value: 'EN STOCK', child: Text('EN STOCK')),
                            DropdownMenuItem(value: 'BAJO STOCK', child: Text('BAJO STOCK')),
                            DropdownMenuItem(value: 'SIN STOCK', child: Text('SIN STOCK')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedStockFilter = value;
                              _currentPage = 1;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRentalFilter,
                    decoration: InputDecoration(
                      labelText: 'Alquiler',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Todo', child: Text('Todo')),
                      DropdownMenuItem(value: 'En uso', child: Text('En uso')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedRentalFilter = value;
                        _currentPage = 1;
                      });
                    },
                  ),
                  if (!_isLoading && _loadError == null) ...[
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Inventory list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                      ? Center(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'No se pudo cargar el inventario',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _loadError!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isLoading = true;
                                        _loadError = null;
                                      });
                                      _loadItemsFromDatabase();
                                    },
                                    child: const Text('Reintentar'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : _paginatedItems.isEmpty
                          ? const Center(child: Text('No hay artículos'))
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _paginatedItems.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = _paginatedItems[index];
                                return _buildInventoryCard(item);
                              },
                            ),
            ),
            // Pagination
            if (!_isLoading && _totalPages > 1)
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

  Widget _buildInventoryCard(InventoryItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
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
                  color: item.stockStatusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: item.stockStatusColor),
                    const SizedBox(width: 4),
                    Text(
                      item.stockStatusDisplay,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: item.stockStatusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editMerchandise(item),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  onPressed: () => _deleteMerchandise(item),
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red.shade700,
                  ),
                  label: Text(
                    'Eliminar',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${item.currentUnits} / ${item.totalUnits} Unidades',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.pending_actions, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Pendiente de alquilar: ${item.pendingRentalUnits}',
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

class _RouteEquipmentEditResult {
  const _RouteEquipmentEditResult({
    required this.routeName,
    required this.equipmentCount,
  });

  final String routeName;
  final int equipmentCount;
}

class _RouteInventoryEditorDialog extends StatefulWidget {
  const _RouteInventoryEditorDialog({
    required this.inventoryItemNames,
    required this.repository,
  });

  final List<String> inventoryItemNames;
  final RouteEquipmentRepository repository;

  @override
  State<_RouteInventoryEditorDialog> createState() =>
      _RouteInventoryEditorDialogState();
}

class _RouteInventoryEditorDialogState extends State<_RouteInventoryEditorDialog> {
  late final List<String> _routeNames;
  late String _selectedRoute;
  late String _selectedInventoryItemToAdd;
  List<RouteRentalEquipment> _rentableEquipment = <RouteRentalEquipment>[];
  final TextEditingController _priceController = TextEditingController(text: '0');
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _routeNames = widget.repository.knownRouteNames;
    _selectedRoute = _routeNames.first;
    _selectedInventoryItemToAdd = widget.inventoryItemNames.first;
    _loadRentableEquipmentForSelectedRoute();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadRentableEquipmentForSelectedRoute() async {
    setState(() {
      _isLoading = true;
    });

    final fallback =
        kDefaultRentableEquipmentByRoute[_selectedRoute] ??
            const <RouteRentalEquipment>[];
    final equipment = await widget.repository.getRentableEquipment(
      routeName: _selectedRoute,
      fallback: fallback,
    );

    if (!mounted) return;
    setState(() {
      _rentableEquipment = equipment;
      _isLoading = false;
    });
  }

  void _addSelectedInventoryItem() {
    final normalizedCurrent =
        _rentableEquipment.map((item) => item.name.toLowerCase()).toSet();
    final candidate = _selectedInventoryItemToAdd.trim();
    final parsedPrice = double.tryParse(_priceController.text.trim().replaceAll(',', '.'));
    final price = parsedPrice == null || parsedPrice < 0 ? 0.0 : parsedPrice;
    if (candidate.isEmpty || normalizedCurrent.contains(candidate.toLowerCase())) {
      return;
    }

    setState(() {
      _rentableEquipment = <RouteRentalEquipment>[
        ..._rentableEquipment,
        RouteRentalEquipment(name: candidate, price: price),
      ];
    });
  }

  void _removeEquipmentAt(int index) {
    setState(() {
      _rentableEquipment = List<RouteRentalEquipment>.from(_rentableEquipment)
        ..removeAt(index);
    });
  }

  Future<void> _editEquipmentPriceAt(int index) async {
    final item = _rentableEquipment[index];
    final controller = TextEditingController(text: item.price.toStringAsFixed(2));

    final newPrice = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar precio: ${item.name}'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Precio por unidad (€)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = double.tryParse(
                  controller.text.trim().replaceAll(',', '.'),
                );
                if (parsed == null || parsed < 0) {
                  Navigator.of(context).pop(item.price);
                  return;
                }
                Navigator.of(context).pop(parsed);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newPrice == null || !mounted) {
      return;
    }

    setState(() {
      final updated = List<RouteRentalEquipment>.from(_rentableEquipment);
      updated[index] = RouteRentalEquipment(
        name: item.name,
        price: newPrice,
      );
      _rentableEquipment = updated;
    });
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    await widget.repository.saveRentableEquipment(
      routeName: _selectedRoute,
      equipment: _rentableEquipment,
    );

    if (!mounted) return;
    Navigator.of(context).pop(
      _RouteEquipmentEditResult(
        routeName: _selectedRoute,
        equipmentCount: _rentableEquipment.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar inventario de ruta'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedRoute,
                decoration: const InputDecoration(labelText: 'Ruta'),
                items: _routeNames
                    .map(
                      (routeName) => DropdownMenuItem<String>(
                        value: routeName,
                        child: Text(routeName),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null || value == _selectedRoute) return;
                  setState(() {
                    _selectedRoute = value;
                  });
                  _loadRentableEquipmentForSelectedRoute();
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedInventoryItemToAdd,
                      decoration: const InputDecoration(
                        labelText: 'Añadir equipamiento desde inventario',
                      ),
                      items: widget.inventoryItemNames
                          .map(
                            (name) => DropdownMenuItem<String>(
                              value: name,
                              child: Text(name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedInventoryItemToAdd = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 105,
                    child: TextField(
                      controller: _priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Precio €',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _addSelectedInventoryItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Equipamiento en alquiler (Reserve su ruta)',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                )
              else if (_rentableEquipment.isEmpty)
                Text(
                  'No hay equipamiento disponible para alquilar en esta ruta.',
                  style: TextStyle(color: Colors.grey.shade700),
                )
              else
                ...List<Widget>.generate(_rentableEquipment.length, (index) {
                  final item = _rentableEquipment[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.price.toStringAsFixed(2)}€ por unidad',
                    ),
                    trailing: Wrap(
                      spacing: 2,
                      children: [
                        IconButton(
                          onPressed: () => _editEquipmentPriceAt(index),
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar precio',
                        ),
                        IconButton(
                          onPressed: () => _removeEquipmentAt(index),
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Eliminar',
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Guardar cambios'),
        ),
      ],
    );
  }
}