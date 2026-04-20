import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'route_catalog.dart';

class RouteRentalEquipment {
  const RouteRentalEquipment({
    required this.name,
    required this.price,
  });

  final String name;
  final double price;
}

const Map<String, List<String>> kDefaultRequiredEquipmentByRoute =
    <String, List<String>>{
  'Refugio del Reloj': <String>[
    'Botas de senderismo',
    '2L de agua',
    'Cortavientos',
    'Frontal o linterna',
    'Manta térmica',
    'Comida energética',
  ],
  'Reloj y Simancón': <String>[
    'Botas de caña alta',
    '3L de agua',
    'Ropa térmica',
    'Bastones',
    'Guantes de montaña',
    'Gafas de protección UV',
    'Protección solar alta',
  ],
  'Charca Verde': <String>[
    'Calzado cómodo',
    '1.5L de agua',
    'Gorra',
    'Protector solar',
    'Mochila ligera',
    'Snacks',
  ],
  'Cueva del Gato': <String>[
    'Calzado con buen agarre',
    '1.5L de agua',
    'Toalla pequeña',
    'Chaqueta ligera',
    'Ropa de recambio',
    'Bolsa estanca',
  ],
  'Pico Mulhacén': <String>[
    'Botas de montaña',
    '2.5L de agua',
    'Capa térmica',
    'Gafas de sol',
    'Cortavientos',
    'Guantes',
    'Gorro térmico',
  ],
};

const Map<String, List<RouteRentalEquipment>>
    kDefaultRentableEquipmentByRoute =
    <String, List<RouteRentalEquipment>>{
  'Refugio del Reloj': <RouteRentalEquipment>[
    RouteRentalEquipment(name: 'Bastones de trekking', price: 9.0),
    RouteRentalEquipment(name: 'Chubasquero impermeable', price: 11.0),
    RouteRentalEquipment(name: 'Frontal LED', price: 7.5),
  ],
  'Reloj y Simancón': <RouteRentalEquipment>[
    RouteRentalEquipment(name: 'Guantes térmicos', price: 8.0),
    RouteRentalEquipment(name: 'Polainas', price: 7.0),
    RouteRentalEquipment(name: 'Poncho técnico', price: 12.0),
  ],
  'Charca Verde': <RouteRentalEquipment>[
    RouteRentalEquipment(name: 'Cantimplora 1L', price: 5.0),
    RouteRentalEquipment(name: 'Gorra transpirable', price: 6.0),
    RouteRentalEquipment(name: 'Crema solar SPF50', price: 4.5),
  ],
  'Cueva del Gato': <RouteRentalEquipment>[
    RouteRentalEquipment(name: 'Escarpines', price: 6.5),
    RouteRentalEquipment(name: 'Bolsa estanca 5L', price: 5.5),
    RouteRentalEquipment(name: 'Toalla microfibra', price: 4.0),
  ],
  'Pico Mulhacén': <RouteRentalEquipment>[
    RouteRentalEquipment(name: 'Forro polar', price: 14.0),
    RouteRentalEquipment(name: 'Gorro térmico', price: 6.0),
    RouteRentalEquipment(name: 'Mochila 20L', price: 15.0),
  ],
};

class RouteEquipmentRepository {
  RouteEquipmentRepository._();

  static final RouteEquipmentRepository instance = RouteEquipmentRepository._();

  static const String _prefsKey = 'route.required_equipment.overrides';
  static const String _rentalPrefsKey = 'route.rental_equipment.overrides';

  List<String> get knownRouteNames {
    final names = <String>{
      ...kDefaultRequiredEquipmentByRoute.keys,
      ...kExploreRoutes
          .map((route) => (route['name'] ?? '').trim())
          .where((name) => name.isNotEmpty),
    };

    final result = names.toList();
    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  String _routeKey(String routeName) {
    return routeName.trim().toLowerCase();
  }

  List<String> _sanitizeEquipment(Iterable<String> equipment) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in equipment) {
      final value = raw.trim();
      if (value.isEmpty) {
        continue;
      }
      final normalized = value.toLowerCase();
      if (seen.contains(normalized)) {
        continue;
      }
      seen.add(normalized);
      result.add(value);
    }
    return result;
  }

  List<RouteRentalEquipment> _sanitizeRentableEquipment(
    Iterable<RouteRentalEquipment> equipment,
  ) {
    final seen = <String>{};
    final result = <RouteRentalEquipment>[];
    for (final item in equipment) {
      final name = item.name.trim();
      if (name.isEmpty) {
        continue;
      }

      final normalized = name.toLowerCase();
      if (seen.contains(normalized)) {
        continue;
      }

      seen.add(normalized);
      result.add(
        RouteRentalEquipment(
          name: name,
          price: item.price < 0 ? 0 : item.price,
        ),
      );
    }
    return result;
  }

  Future<Map<String, List<String>>> _readAllOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, List<String>>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, List<String>>{};
      }

      final result = <String, List<String>>{};
      decoded.forEach((key, value) {
        if (value is! List) {
          return;
        }
        final items = value.map((item) => item.toString()).toList();
        result[key.toString()] = _sanitizeEquipment(items);
      });
      return result;
    } catch (_) {
      return <String, List<String>>{};
    }
  }

  Future<void> _writeAllOverrides(Map<String, List<String>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  Future<Map<String, List<RouteRentalEquipment>>> _readAllRentalOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rentalPrefsKey);
    if (raw == null || raw.trim().isEmpty) {
      return <String, List<RouteRentalEquipment>>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, List<RouteRentalEquipment>>{};
      }

      final result = <String, List<RouteRentalEquipment>>{};
      decoded.forEach((key, value) {
        if (value is! List) {
          return;
        }

        final items = <RouteRentalEquipment>[];
        for (final rawItem in value) {
          if (rawItem is! Map) {
            continue;
          }

          final name = (rawItem['name'] ?? '').toString().trim();
          final priceRaw = rawItem['price'];
          final price = (priceRaw is num)
              ? priceRaw.toDouble()
              : double.tryParse(priceRaw?.toString() ?? '') ?? 0;
          if (name.isEmpty) {
            continue;
          }
          items.add(RouteRentalEquipment(name: name, price: price));
        }

        result[key.toString()] = _sanitizeRentableEquipment(items);
      });

      return result;
    } catch (_) {
      return <String, List<RouteRentalEquipment>>{};
    }
  }

  Future<void> _writeAllRentalOverrides(
    Map<String, List<RouteRentalEquipment>> data,
  ) async {
    final encoded = <String, List<Map<String, Object?>>>{
      for (final entry in data.entries)
        entry.key: entry.value
            .map(
              (item) => <String, Object?>{
                'name': item.name,
                'price': item.price,
              },
            )
            .toList(),
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rentalPrefsKey, jsonEncode(encoded));
  }

  Future<List<String>> getRequiredEquipment({
    required String routeName,
    required List<String> fallback,
  }) async {
    final overrides = await _readAllOverrides();
    final key = _routeKey(routeName);
    final stored = overrides[key];
    if (stored != null) {
      return List<String>.from(stored);
    }

    return _sanitizeEquipment(fallback);
  }

  Future<void> saveRequiredEquipment({
    required String routeName,
    required List<String> equipment,
  }) async {
    final overrides = await _readAllOverrides();
    overrides[_routeKey(routeName)] = _sanitizeEquipment(equipment);
    await _writeAllOverrides(overrides);
  }

  Future<List<RouteRentalEquipment>> getRentableEquipment({
    required String routeName,
    required List<RouteRentalEquipment> fallback,
  }) async {
    final overrides = await _readAllRentalOverrides();
    final key = _routeKey(routeName);
    final stored = overrides[key];
    if (stored != null) {
      return List<RouteRentalEquipment>.from(stored);
    }

    return _sanitizeRentableEquipment(fallback);
  }

  Future<void> saveRentableEquipment({
    required String routeName,
    required List<RouteRentalEquipment> equipment,
  }) async {
    final overrides = await _readAllRentalOverrides();
    overrides[_routeKey(routeName)] = _sanitizeRentableEquipment(equipment);
    await _writeAllRentalOverrides(overrides);
  }
}
