import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/runtime_flags.dart';
import 'firestore_id_generator.dart';

class UserDatabase {
  UserDatabase._();

  static final UserDatabase instance = UserDatabase._();

  static const String _collectionName = 'users';
  static const String _usersPrefsKey = 'db.users.rows';
  static const String _usersNextIdPrefsKey = 'db.users.next_id';

  bool get _usePrefsStorage => isFlutterTestRuntime;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<List<Map<String, Object?>>> _readUsersFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersPrefsKey);
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

  Future<void> _writeUsersToPrefs(List<Map<String, Object?>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersPrefsKey, jsonEncode(users));
  }

  Future<int> _getAndAdvanceNextUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_usersNextIdPrefsKey) ?? 1;
    await prefs.setInt(_usersNextIdPrefsKey, current + 1);
    return current;
  }

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(_collectionName);

  Map<String, Object?> _normalizeUserMap(
    Map<String, Object?> data, {
    String? docId,
  }) {
    return {
      ...data,
      'id': (data['id'] as num?)?.toInt() ?? int.tryParse(docId ?? '') ?? 0,
    };
  }

  Future<List<Map<String, Object?>>> _readUsersFromFirestore() async {
    final snapshot = await _usersCollection.orderBy('created_at', descending: true).get();
    return snapshot.docs
        .map((doc) => _normalizeUserMap(Map<String, Object?>.from(doc.data()), docId: doc.id))
        .toList();
  }

  Future<bool> userExists(String email) async {
    if (_usePrefsStorage) {
      final normalizedEmail = email.trim().toLowerCase();
      final users = await _readUsersFromPrefs();
      return users.any((row) {
        return (row['email'] as String?)?.trim().toLowerCase() ==
            normalizedEmail;
      });
    }

    final snapshot = await _usersCollection
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String city,
    required String phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (_usePrefsStorage) {
      final users = await _readUsersFromPrefs();
      final alreadyExists = users.any((row) {
        return (row['email'] as String?)?.trim().toLowerCase() ==
            normalizedEmail;
      });
      if (alreadyExists) {
        throw StateError('Ya existe un usuario con ese correo.');
      }

      final nextId = await _getAndAdvanceNextUserId();
      users.add({
        'id': nextId,
        'name': name.trim(),
        'email': normalizedEmail,
        'password': password,
        'city': city.trim(),
        'phone': phone.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });
      await _writeUsersToPrefs(users);
      return;
    }

    if (await userExists(normalizedEmail)) {
      throw StateError('Ya existe un usuario con ese correo.');
    }

    final nextId = await FirestoreIdGenerator.nextId('users_next_id');
    await _usersCollection.doc(nextId.toString()).set(<String, Object?>{
      'id': nextId,
      'name': name.trim(),
      'email': normalizedEmail,
      'password': password,
      'city': city.trim(),
      'phone': phone.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> validateCredentials({
    required String email,
    required String password,
  }) async {
    if (_usePrefsStorage) {
      final normalizedEmail = email.trim().toLowerCase();
      final users = await _readUsersFromPrefs();
      return users.any((row) {
        return (row['email'] as String?)?.trim().toLowerCase() ==
                normalizedEmail &&
            (row['password'] as String?) == password;
      });
    }

    final snapshot = await _usersCollection
        .where('email', isEqualTo: email.trim().toLowerCase())
        .where('password', isEqualTo: password)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<Map<String, Object?>?> getUserByEmail(String email) async {
    if (_usePrefsStorage) {
      final normalizedEmail = email.trim().toLowerCase();
      final users = await _readUsersFromPrefs();
      for (final row in users) {
        if ((row['email'] as String?)?.trim().toLowerCase() ==
            normalizedEmail) {
          return row;
        }
      }
      return null;
    }

    final snapshot = await _usersCollection
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return _normalizeUserMap(
      Map<String, Object?>.from(snapshot.docs.first.data()),
      docId: snapshot.docs.first.id,
    );
  }

  Future<List<Map<String, Object?>>> getAllUsers() async {
    if (_usePrefsStorage) {
      final users = await _readUsersFromPrefs();
      return users;
    }

    return _readUsersFromFirestore();
  }

  Future<void> updateUserProfile({
    required String email,
    String? name,
    String? city,
    String? phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final values = <String, Object?>{};

    if (name != null) {
      values['name'] = name.trim();
    }
    if (city != null) {
      values['city'] = city.trim();
    }
    if (phone != null) {
      values['phone'] = phone.trim();
    }

    if (values.isEmpty) {
      return;
    }

    if (_usePrefsStorage) {
      final users = await _readUsersFromPrefs();
      var updated = false;
      for (var i = 0; i < users.length; i++) {
        final userEmail = (users[i]['email'] as String?)?.trim().toLowerCase();
        if (userEmail == normalizedEmail) {
          users[i] = {
            ...users[i],
            ...values,
          };
          updated = true;
          break;
        }
      }

      if (!updated) {
        final nextId = await _getAndAdvanceNextUserId();
        users.add({
          'id': nextId,
          'name': (values['name'] as String?) ?? 'Usuario',
          'email': normalizedEmail,
          'password': 'password',
          'city': (values['city'] as String?) ?? '-',
          'phone': (values['phone'] as String?) ?? '-',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      await _writeUsersToPrefs(users);
      return;
    }

    final snapshot = await _usersCollection
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update(values);
      return;
    }

    final nextId = await FirestoreIdGenerator.nextId('users_next_id');
    await _usersCollection.doc(nextId.toString()).set(<String, Object?>{
      'id': nextId,
      'name': (values['name'] as String?) ?? 'Usuario',
      'email': normalizedEmail,
      'password': 'password',
      'city': (values['city'] as String?) ?? '-',
      'phone': (values['phone'] as String?) ?? '-',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}