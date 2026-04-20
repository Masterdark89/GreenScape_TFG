import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/runtime_flags.dart';
import '../models/inventory_item.dart';
import 'firestore_id_generator.dart';

class InventoryDatabase {
  InventoryDatabase._();

  static final InventoryDatabase instance = InventoryDatabase._();

  static const String _collectionName = 'inventory_items';
  static const String _prefsItemsKey = 'db.inventory.rows';
  static const String _prefsNextIdKey = 'db.inventory.next_id';

  static const List<String> _knownCategories = <String>[
    'Botas',
    'Tiendas',
    'Baz',
    'Mochilas',
    'Sacos',
    'Proteccion',
  ];

  static final Map<String, String> _knownCategoryByNormalized = <String, String>{
    for (final category in _knownCategories) category.toLowerCase(): category,
  };

  static const List<InventoryItem> _routeSelectableDefaults = <InventoryItem>[
    InventoryItem(
      name: 'Bastones de trekking',
      description: 'Alquiler para rutas',
      category: 'Botas',
      stockStatus: 'EN STOCK',
      currentUnits: 20,
      totalUnits: 20,
    ),
    InventoryItem(
      name: 'Chubasquero impermeable',
      description: 'Alquiler para rutas',
      category: 'Proteccion',
      stockStatus: 'EN STOCK',
      currentUnits: 20,
      totalUnits: 20,
    ),
    InventoryItem(
      name: 'Frontal LED',
      description: 'Alquiler para rutas',
      category: 'Baz',
      stockStatus: 'EN STOCK',
      currentUnits: 20,
      totalUnits: 20,
    ),
    InventoryItem(
      name: 'Guantes térmicos',
      description: 'Alquiler para rutas',
      category: 'Proteccion',
      stockStatus: 'EN STOCK',
      currentUnits: 20,
      totalUnits: 20,
    ),
    InventoryItem(
      name: 'Polainas',
      description: 'Alquiler para rutas',
      category: 'Proteccion',
      stockStatus: 'EN STOCK',
      currentUnits: 20,
      totalUnits: 20,
    ),
    InventoryItem(
      name: 'Poncho técnico',
      description: 'Alquiler para rutas',
      category: 'Proteccion',
      stockStatus: 'EN STOCK',
      currentUnits: 20,
      totalUnits: 20,
    ),
    InventoryItem(
      name: 'Cantimplora 1L',
      description: 'Alquiler para rutas',
      category: 'Baz',
      stockStatus: 'EN STOCK',
      currentUnits: 20,
      totalUnits: 20,
    ),
    InventoryItem(
      name: 'Gorra transpirable',
      description: 'Alquiler para rutas',
      category: 'Proteccion',
      stockStatus: 'EN STOCK',
      currentUnits: 20,
      totalUnits: 20,
    ),
    InventoryItem(
      name: 'Crema solar SPF50',
      description: 'Alquiler para rutas',
      category: 'Proteccion',
      stockStatus: 'EN STOCK',
      currentUnits: 20,
      totalUnits: 20,
    ),
    InventoryItem(
      name: 'Escarpines',
      description: 'Alquiler para rutas',
      category: 'Botas',
      stockStatus: 'EN STOCK',
      currentUnits: 20,
      totalUnits: 20,
    ),
    InventoryItem(
      name: 'Bolsa estanca 5L',
      description: 'Alquiler para rutas',
      category: 'Baz',
      stockStatus: 'EN STOCK',
      currentUnits: 20,
      totalUnits: 20,
    ),
    InventoryItem(
      name: 'Toalla microfibra',
      description: 'Alquiler para rutas',
      category: 'Baz',
      stockStatus: 'EN STOCK',
      currentUnits: 20,
      totalUnits: 20,
    ),
    InventoryItem(
      name: 'Forro polar',
      description: 'Alquiler para rutas',
      category: 'Proteccion',
      stockStatus: 'EN STOCK',
      currentUnits: 20,
      totalUnits: 20,
    ),
    InventoryItem(
      name: 'Gorro térmico',
      description: 'Alquiler para rutas',
      category: 'Proteccion',
      stockStatus: 'EN STOCK',
      currentUnits: 20,
      totalUnits: 20,
    ),
    InventoryItem(
      name: 'Mochila 20L',
      description: 'Alquiler para rutas',
      category: 'Mochilas',
      stockStatus: 'EN STOCK',
      currentUnits: 20,
      totalUnits: 20,
    ),
  ];

  static const List<InventoryItem> _defaultItems = <InventoryItem>[
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

  bool get _usePrefsStorage => isFlutterTestRuntime;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _itemsCollection =>
      _firestore.collection(_collectionName);

  Future<List<Map<String, Object?>>> _readItemsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsItemsKey);
    if (raw == null || raw.isEmpty) {
      return <Map<String, Object?>>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <Map<String, Object?>>[];
      }

      return decoded.whereType<Map>().map<Map<String, Object?>>((item) {
        final map = item.map<String, Object?>((key, value) {
          return MapEntry(key.toString(), value);
        });

        return {
          ...map,
          'id': (map['id'] as num?)?.toInt(),
          'current_units': (map['current_units'] as num?)?.toInt() ?? 0,
          'total_units': (map['total_units'] as num?)?.toInt() ?? 0,
          'pending_rental_units':
              (map['pending_rental_units'] as num?)?.toInt() ?? 0,
        };
      }).toList();
    } catch (_) {
      return <Map<String, Object?>>[];
    }
  }

  Future<void> _writeItemsToPrefs(List<Map<String, Object?>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsItemsKey, jsonEncode(items));
  }

  Future<int> _getAndAdvanceNextPrefsId() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_prefsNextIdKey) ?? 1;
    await prefs.setInt(_prefsNextIdKey, current + 1);
    return current;
  }

  Map<String, Object?> _normalizeItemMap(
    Map<String, Object?> data, {
    String? docId,
  }) {
    return {
      ...data,
      'id': (data['id'] as num?)?.toInt() ?? int.tryParse(docId ?? '') ?? 0,
      'current_units': (data['current_units'] as num?)?.toInt() ?? 0,
      'total_units': (data['total_units'] as num?)?.toInt() ?? 0,
      'pending_rental_units':
          (data['pending_rental_units'] as num?)?.toInt() ?? 0,
    };
  }

  Map<String, Object?> _toStoredMap(InventoryItem item, int id) {
    return {
      ...item.toMap(),
      'id': id,
    };
  }

  String _normalizeName(String name) => name.trim().toLowerCase();

  String _normalizeText(String value) => value.trim().toLowerCase();

  String _resolveKnownCategory(InventoryItem item) {
    final normalizedCategory = _normalizeText(item.category);
    final knownCategory = _knownCategoryByNormalized[normalizedCategory];
    if (knownCategory != null) {
      return knownCategory;
    }

    final searchable = _normalizeText('${item.name} ${item.description}');
    if (searchable.contains('tienda')) {
      return 'Tiendas';
    }
    if (searchable.contains('mochila')) {
      return 'Mochilas';
    }
    if (searchable.contains('saco')) {
      return 'Sacos';
    }
    if (searchable.contains('bota') ||
        searchable.contains('crampon') ||
        searchable.contains('escarpin') ||
        searchable.contains('baston')) {
      return 'Botas';
    }
    if (searchable.contains('chubasquero') ||
        searchable.contains('guante') ||
        searchable.contains('polaina') ||
        searchable.contains('poncho') ||
        searchable.contains('gorro') ||
        searchable.contains('forro') ||
        searchable.contains('crema') ||
        searchable.contains('gorra') ||
        searchable.contains('casco')) {
      return 'Proteccion';
    }
    if (searchable.contains('frontal') ||
        searchable.contains('linterna') ||
        searchable.contains('cuerda') ||
        searchable.contains('cantimplora') ||
        searchable.contains('bolsa estanca') ||
        searchable.contains('toalla')) {
      return 'Baz';
    }
    return 'Proteccion';
  }

  Future<List<InventoryItem>> _loadAllFromFirestore() async {
    final snapshot = await _itemsCollection.get();
    final items = snapshot.docs
        .map((doc) => InventoryItem.fromMap(
              _normalizeItemMap(Map<String, Object?>.from(doc.data()), docId: doc.id),
            ))
        .toList();
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  Future<List<InventoryItem>> _loadAllItems() async {
    if (_usePrefsStorage) {
      final rows = await _readItemsFromPrefs();
      final items = rows.map(InventoryItem.fromMap).toList();
      items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return items;
    }

    return _loadAllFromFirestore();
  }

  Future<void> _storeItem(InventoryItem item) async {
    if (_usePrefsStorage) {
      final rows = await _readItemsFromPrefs();
      final id = item.id ?? await _getAndAdvanceNextPrefsId();
      final nextRow = _toStoredMap(item, id);
      final index = rows.indexWhere((row) => (row['id'] as num?)?.toInt() == id);
      if (index == -1) {
        rows.add(nextRow);
      } else {
        rows[index] = nextRow;
      }
      await _writeItemsToPrefs(rows);
      return;
    }

    final id = item.id ?? await FirestoreIdGenerator.nextId('inventory_next_id');
    await _itemsCollection.doc(id.toString()).set(_toStoredMap(item, id));
  }

  Future<void> seedIfEmpty(List<InventoryItem> defaultItems) async {
    final items = await _loadAllItems();
    if (items.isNotEmpty) {
      return;
    }

    for (final item in defaultItems) {
      await _storeItem(item);
    }
    debugPrint('InventoryDatabase seeded with ${defaultItems.length} items');
  }

  Future<int> catalogExistingItemsByKnownCategories() async {
    final items = await _loadAllItems();
    var updates = 0;

    for (final item in items) {
      final nextCategory = _resolveKnownCategory(item);
      if (nextCategory == item.category || item.id == null) {
        continue;
      }

      await updateItem(
        InventoryItem(
          id: item.id,
          name: item.name,
          description: item.description,
          category: nextCategory,
          stockStatus: item.stockStatus,
          currentUnits: item.currentUnits,
          totalUnits: item.totalUnits,
          pendingRentalUnits: item.pendingRentalUnits,
        ),
      );
      updates += 1;
    }

    return updates;
  }

  Future<List<InventoryItem>> getAllItems() async {
    final items = await _loadAllItems();
    debugPrint('InventoryDatabase items loaded: ${items.length}');
    return items;
  }

  Future<int> insertItem(InventoryItem item) async {
    final id = item.id ??
        (_usePrefsStorage ? await _getAndAdvanceNextPrefsId() : await FirestoreIdGenerator.nextId('inventory_next_id'));
    await _storeItem(InventoryItem(
      id: id,
      name: item.name,
      description: item.description,
      category: item.category,
      stockStatus: item.stockStatus,
      currentUnits: item.currentUnits,
      totalUnits: item.totalUnits,
      pendingRentalUnits: item.pendingRentalUnits,
    ));
    return id;
  }

  Future<int> updateItem(InventoryItem item) async {
    if (item.id == null) {
      throw StateError('No se puede actualizar un artículo sin identificador.');
    }

    await _storeItem(item);
    return item.id!;
  }

  Future<int> deleteItem(int id) async {
    if (_usePrefsStorage) {
      final rows = await _readItemsFromPrefs();
      rows.removeWhere((row) => (row['id'] as num?)?.toInt() == id);
      await _writeItemsToPrefs(rows);
      return id;
    }

    await _itemsCollection.doc(id.toString()).delete();
    return id;
  }

  Future<void> ensureRouteSelectableItems() async {
    final existingNames = (await _loadAllItems())
        .map((item) => _normalizeName(item.name))
        .toSet();

    for (final item in _routeSelectableDefaults) {
      if (existingNames.contains(_normalizeName(item.name))) {
        continue;
      }
      await insertItem(item);
    }
  }

  Future<void> seedAppDefaults() async {
    await seedIfEmpty(_defaultItems);
    await ensureRouteSelectableItems();
  }

  Future<void> applyConfirmedRental(Map<String, int> equipmentQuantities) async {
    if (equipmentQuantities.isEmpty) {
      return;
    }

    final items = await _loadAllItems();
    final byName = <String, InventoryItem>{
      for (final item in items) _normalizeName(item.name): item,
    };

    for (final entry in equipmentQuantities.entries) {
      final quantity = entry.value;
      if (quantity <= 0) {
        continue;
      }

      final key = _normalizeName(entry.key);
      final existing = byName[key];

      if (existing == null) {
        final inferredCategory = _resolveKnownCategory(
          InventoryItem(
            name: entry.key.trim(),
            description: 'Alta automática por reserva confirmada',
            category: '',
            stockStatus: 'SIN STOCK',
            currentUnits: 0,
            totalUnits: quantity,
            pendingRentalUnits: quantity,
          ),
        );
        await insertItem(
          InventoryItem(
            name: entry.key.trim(),
            description: 'Alta automática por reserva confirmada',
            category: inferredCategory,
            stockStatus: 'SIN STOCK',
            currentUnits: 0,
            totalUnits: quantity,
            pendingRentalUnits: quantity,
          ),
        );
        continue;
      }

      await updateItem(
        InventoryItem(
          id: existing.id,
          name: existing.name,
          description: existing.description,
          category: existing.category,
          stockStatus: existing.stockStatus,
          currentUnits: (existing.currentUnits - quantity).clamp(0, existing.totalUnits),
          totalUnits: existing.totalUnits,
          pendingRentalUnits: existing.pendingRentalUnits + quantity,
        ),
      );
    }
  }

  Future<void> applyCompletedReturn(Map<String, int> equipmentQuantities) async {
    if (equipmentQuantities.isEmpty) {
      return;
    }

    final items = await _loadAllItems();
    final byName = <String, InventoryItem>{
      for (final item in items) _normalizeName(item.name): item,
    };

    for (final entry in equipmentQuantities.entries) {
      final quantity = entry.value;
      if (quantity <= 0) {
        continue;
      }

      final key = _normalizeName(entry.key);
      final existing = byName[key];

      if (existing == null) {
        final inferredCategory = _resolveKnownCategory(
          InventoryItem(
            name: entry.key.trim(),
            description: 'Alta automática por devolución de ruta',
            category: '',
            stockStatus: 'EN STOCK',
            currentUnits: quantity,
            totalUnits: quantity,
            pendingRentalUnits: 0,
          ),
        );
        await insertItem(
          InventoryItem(
            name: entry.key.trim(),
            description: 'Alta automática por devolución de ruta',
            category: inferredCategory,
            stockStatus: 'EN STOCK',
            currentUnits: quantity,
            totalUnits: quantity,
            pendingRentalUnits: 0,
          ),
        );
        continue;
      }

      final nextPending =
          (existing.pendingRentalUnits - quantity).clamp(0, existing.totalUnits);
      final nextCurrent =
          (existing.currentUnits + quantity).clamp(0, existing.totalUnits);

      await updateItem(
        InventoryItem(
          id: existing.id,
          name: existing.name,
          description: existing.description,
          category: existing.category,
          stockStatus: existing.stockStatus,
          currentUnits: nextCurrent,
          totalUnits: existing.totalUnits,
          pendingRentalUnits: nextPending,
        ),
      );
    }
  }
}
