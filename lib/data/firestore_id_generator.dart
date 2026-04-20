import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreIdGenerator {
  FirestoreIdGenerator._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<int> nextId(String key) async {
    final counterRef = _firestore.collection('metadata').doc('counters');

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      final current = (snapshot.data()?[key] as num?)?.toInt() ?? 1;
      transaction.set(
        counterRef,
        <String, Object?>{key: current + 1},
        SetOptions(merge: true),
      );
      return current;
    });
  }
}