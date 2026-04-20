import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/runtime_flags.dart';
import 'firestore_id_generator.dart';

class ReservationDatabase {
  ReservationDatabase._();

  static final ReservationDatabase instance = ReservationDatabase._();

  static const String _collectionName = 'client_reservations';
  static const String _reservationsPrefsKey = 'db.reservations.rows';
  static const String _reservationsNextIdPrefsKey = 'db.reservations.next_id';

  bool get _usePrefsStorage => isFlutterTestRuntime;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<List<Map<String, Object?>>> _readReservationsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reservationsPrefsKey);
    if (raw == null || raw.isEmpty) {
      return <Map<String, Object?>>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <Map<String, Object?>>[];
      }

      return decoded
          .whereType<Map>()
          .map<Map<String, Object?>>(
            (item) => item.map<String, Object?>((key, value) {
              return MapEntry(key.toString(), value);
            }),
          )
          .toList();
    } catch (_) {
      return <Map<String, Object?>>[];
    }
  }

  Future<void> _writeReservationsToPrefs(
    List<Map<String, Object?>> rows,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reservationsPrefsKey, jsonEncode(rows));
  }

  Future<int> _getAndAdvanceNextReservationId() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_reservationsNextIdPrefsKey) ?? 1;
    await prefs.setInt(_reservationsNextIdPrefsKey, current + 1);
    return current;
  }

  CollectionReference<Map<String, dynamic>> get _reservationsCollection =>
      _firestore.collection(_collectionName);

  Map<String, Object?> _normalizeReservationMap(
    Map<String, Object?> data, {
    String? docId,
  }) {
    return {
      ...data,
      'id': (data['id'] as num?)?.toInt() ?? int.tryParse(docId ?? '') ?? 0,
    };
  }

  Future<List<Map<String, Object?>>> _readReservationsFromFirestore() async {
    final snapshot = await _reservationsCollection.get();
    final rows = snapshot.docs
        .map((doc) => _normalizeReservationMap(Map<String, Object?>.from(doc.data()), docId: doc.id))
        .toList();
    rows.sort((a, b) {
      final aCreatedAt = DateTime.tryParse((a['created_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bCreatedAt = DateTime.tryParse((b['created_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bCreatedAt.compareTo(aCreatedAt);
    });
    return rows;
  }

  Future<void> insertReservation({
    required String userEmail,
    required String routeName,
    required DateTime date,
    required String reservationTime,
    required int people,
    required double total,
    required String status,
    required String equipmentJson,
    String? reservationDetails,
  }) async {
    if (_usePrefsStorage) {
      final rows = await _readReservationsFromPrefs();
      final nextId = await _getAndAdvanceNextReservationId();
      rows.add({
        'id': nextId,
        'user_email': userEmail.trim().toLowerCase(),
        'route_name': routeName,
        'date': date.toIso8601String(),
        'reservation_time': reservationTime,
        'people': people,
        'total': total,
        'status': status,
        'equipment_json': equipmentJson,
        'reservation_details': reservationDetails,
        'rejection_reason': null,
        'rejected_by_email': null,
        'rejected_by_name': null,
        'confirmed_at': null,
        'created_at': DateTime.now().toIso8601String(),
      });
      await _writeReservationsToPrefs(rows);
      return;
    }

    final nextId = await FirestoreIdGenerator.nextId('reservations_next_id');
    await _reservationsCollection.doc(nextId.toString()).set(<String, Object?>{
      'id': nextId,
      'user_email': userEmail.trim().toLowerCase(),
      'route_name': routeName,
      'date': date.toIso8601String(),
      'reservation_time': reservationTime,
      'people': people,
      'total': total,
      'status': status,
      'equipment_json': equipmentJson,
      'reservation_details': reservationDetails,
      'rejection_reason': null,
      'rejected_by_email': null,
      'rejected_by_name': null,
      'confirmed_at': null,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateReservation({
    required String userEmail,
    required int reservationId,
    required String routeName,
    required DateTime date,
    required String reservationTime,
    required int people,
    required double total,
    required String status,
    required String equipmentJson,
    String? reservationDetails,
  }) async {
    if (_usePrefsStorage) {
      final normalizedEmail = userEmail.trim().toLowerCase();
      final rows = await _readReservationsFromPrefs();
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final rowId = (row['id'] as num?)?.toInt();
        final rowEmail = (row['user_email'] as String?)?.trim().toLowerCase();
        if (rowId == reservationId && rowEmail == normalizedEmail) {
          rows[i] = {
            ...row,
            'route_name': routeName,
            'date': date.toIso8601String(),
            'reservation_time': reservationTime,
            'people': people,
            'total': total,
            'status': status,
            'equipment_json': equipmentJson,
            'reservation_details': reservationDetails,
            'rejection_reason': null,
            'rejected_by_email': null,
            'rejected_by_name': null,
            'confirmed_at': null,
          };
          break;
        }
      }
      await _writeReservationsToPrefs(rows);
      return;
    }

    final doc = await _reservationsCollection.doc(reservationId.toString()).get();
    if (!doc.exists) {
      return;
    }

    final data = Map<String, Object?>.from(doc.data()!);
    final storedEmail = (data['user_email'] as String?)?.trim().toLowerCase();
    if (storedEmail != userEmail.trim().toLowerCase()) {
      return;
    }

    await doc.reference.update(<String, Object?>{
      'route_name': routeName,
      'date': date.toIso8601String(),
      'reservation_time': reservationTime,
      'people': people,
      'total': total,
      'status': status,
      'equipment_json': equipmentJson,
      'reservation_details': reservationDetails,
      'rejection_reason': null,
      'rejected_by_email': null,
      'rejected_by_name': null,
      'confirmed_at': null,
    });
  }

  Future<void> deleteReservation({
    required String userEmail,
    required int reservationId,
  }) async {
    if (_usePrefsStorage) {
      final normalizedEmail = userEmail.trim().toLowerCase();
      final rows = await _readReservationsFromPrefs();
      rows.removeWhere((row) {
        final rowId = (row['id'] as num?)?.toInt();
        final rowEmail = (row['user_email'] as String?)?.trim().toLowerCase();
        return rowId == reservationId && rowEmail == normalizedEmail;
      });
      await _writeReservationsToPrefs(rows);
      return;
    }

    final doc = await _reservationsCollection.doc(reservationId.toString()).get();
    if (!doc.exists) {
      return;
    }

    final data = Map<String, Object?>.from(doc.data()!);
    final storedEmail = (data['user_email'] as String?)?.trim().toLowerCase();
    if (storedEmail != userEmail.trim().toLowerCase()) {
      return;
    }

    await doc.reference.delete();
  }

  Future<List<Map<String, Object?>>> getReservationsForUser(String userEmail) async {
    if (_usePrefsStorage) {
      final normalizedEmail = userEmail.trim().toLowerCase();
      final rows = await _readReservationsFromPrefs();
      final filtered = rows.where((row) {
        return (row['user_email'] as String?)?.trim().toLowerCase() ==
            normalizedEmail;
      }).toList();
      filtered.sort((a, b) {
        final aCreatedAt = DateTime.tryParse((a['created_at'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bCreatedAt = DateTime.tryParse((b['created_at'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bCreatedAt.compareTo(aCreatedAt);
      });
      return filtered;
    }

    final normalizedEmail = userEmail.trim().toLowerCase();
    final rows = await _readReservationsFromFirestore();
    return rows.where((row) {
      return (row['user_email'] as String?)?.trim().toLowerCase() ==
          normalizedEmail;
    }).toList();
  }

  Future<List<Map<String, Object?>>> getAllReservations() async {
    if (_usePrefsStorage) {
      final rows = await _readReservationsFromPrefs();
      rows.sort((a, b) {
        final aCreatedAt = DateTime.tryParse((a['created_at'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bCreatedAt = DateTime.tryParse((b['created_at'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bCreatedAt.compareTo(aCreatedAt);
      });
      return rows;
    }

    return _readReservationsFromFirestore();
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String? _dateKeyFromRaw(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return null;
    }
    return _dateKey(parsed);
  }

  Future<bool> hasConfirmedReservationConflict({
    required String routeName,
    required DateTime date,
    required String reservationTime,
    int? excludeReservationId,
  }) async {
    final normalizedRouteName = routeName.trim();
    final dateKey = _dateKey(date);
    final normalizedTime = reservationTime.trim();

    if (_usePrefsStorage) {
      final rows = await _readReservationsFromPrefs();
      for (final row in rows) {
        final rowStatus = (row['status'] as String?)?.trim();
        if (rowStatus != 'confirmed') {
          continue;
        }

        final rowId = (row['id'] as num?)?.toInt();
        if (excludeReservationId != null && rowId == excludeReservationId) {
          continue;
        }

        final rowRouteName = (row['route_name'] as String?)?.trim();
        final rowDateKey = _dateKeyFromRaw(row['date'] as String?);
        final rowTime = (row['reservation_time'] as String?)?.trim();

        if (rowRouteName == normalizedRouteName &&
            rowDateKey == dateKey &&
            rowTime == normalizedTime) {
          return true;
        }
      }
      return false;
    }

    final rows = await _readReservationsFromFirestore();
    for (final row in rows) {
      final statusName = (row['status'] as String?)?.trim();
      if (statusName != 'confirmed') {
        continue;
      }

      final rowId = (row['id'] as num?)?.toInt();
      if (excludeReservationId != null && rowId == excludeReservationId) {
        continue;
      }

      final rowRouteName = (row['route_name'] as String?)?.trim();
      final rowDateKey = _dateKeyFromRaw(row['date'] as String?);
      final rowTime = (row['reservation_time'] as String?)?.trim();

      if (rowRouteName == normalizedRouteName &&
          rowDateKey == dateKey &&
          rowTime == normalizedTime) {
        return true;
      }
    }
    return false;
  }

  Future<void> updateReservationStatusById({
    required int reservationId,
    required String status,
    String? rejectionReason,
    String? rejectedByEmail,
    String? rejectedByName,
  }) async {
    if (_usePrefsStorage) {
      final rows = await _readReservationsFromPrefs();
      for (var i = 0; i < rows.length; i++) {
        final rowId = (rows[i]['id'] as num?)?.toInt();
        if (rowId == reservationId) {
          rows[i] = {
            ...rows[i],
            'status': status,
            'rejection_reason': rejectionReason,
            'rejected_by_email': rejectedByEmail,
            'rejected_by_name': rejectedByName,
            'confirmed_at': status == 'confirmed'
                ? DateTime.now().toIso8601String()
                : null,
          };
          break;
        }
      }
      await _writeReservationsToPrefs(rows);
      return;
    }

    final doc = await _reservationsCollection.doc(reservationId.toString()).get();
    if (!doc.exists) {
      return;
    }

    await doc.reference.update(<String, Object?>{
      'status': status,
      'rejection_reason': rejectionReason,
      'rejected_by_email': rejectedByEmail,
      'rejected_by_name': rejectedByName,
      'confirmed_at': status == 'confirmed'
          ? DateTime.now().toIso8601String()
          : null,
    });
  }
}
