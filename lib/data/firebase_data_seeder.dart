import 'package:cloud_firestore/cloud_firestore.dart';

import 'inventory_database.dart';
import 'route_catalog.dart';
import 'route_equipment_repository.dart';

class FirebaseDataSeeder {
  FirebaseDataSeeder._();

  static final FirebaseDataSeeder instance = FirebaseDataSeeder._();

  static const String _routesCollection = 'routes';
  static const String _seedingMarkerCollection = 'metadata';
  static const String _seedingMarkerDocument = 'seed_state';
  static const String _seedVersionField = 'data_folder_seed_version';
  static const int _seedVersion = 1;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, Object?> _routeDocumentFromRoute(Map<String, String> route) {
    final routeName = route['name'] ?? '';
    final requiredEquipment = kDefaultRequiredEquipmentByRoute[routeName] ?? <String>[];
    final rentableEquipment = kDefaultRentableEquipmentByRoute[routeName] ?? <RouteRentalEquipment>[];

    return <String, Object?>{
      'name': route['name'] ?? '',
      'difficulty': route['difficulty'] ?? '',
      'distance': route['distance'] ?? '',
      'duration': route['duration'] ?? '',
      'elevation': route['elevation'] ?? '',
      'imagePath': route['imagePath'] ?? '',
      'required_equipment': requiredEquipment,
      'rentable_equipment': rentableEquipment
          .map(
            (item) => <String, Object?>{
              'name': item.name,
              'price': item.price,
            },
          )
          .toList(),
    };
  }

  Future<bool> _isAlreadySeeded() async {
    final snapshot = await _firestore
        .collection(_seedingMarkerCollection)
        .doc(_seedingMarkerDocument)
        .get();

    return (snapshot.data()?[_seedVersionField] as num?)?.toInt() == _seedVersion;
  }

  Future<void> _markSeeded() async {
    await _firestore
        .collection(_seedingMarkerCollection)
        .doc(_seedingMarkerDocument)
        .set(<String, Object?>{
          _seedVersionField: _seedVersion,
          'seeded_at': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
  }

  Future<void> seedAll() async {
    if (await _isAlreadySeeded()) {
      return;
    }

    final batch = _firestore.batch();
    for (final route in kExploreRoutes) {
      final routeName = route['name'];
      if (routeName == null || routeName.trim().isEmpty) {
        continue;
      }

      batch.set(
        _firestore.collection(_routesCollection).doc(routeName),
        _routeDocumentFromRoute(route),
        SetOptions(merge: true),
      );
    }

    await batch.commit();
    await InventoryDatabase.instance.seedAppDefaults();
    await _markSeeded();
  }
}
