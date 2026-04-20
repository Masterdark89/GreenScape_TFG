import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../core/app_notification_service.dart';
import 'current_user_session.dart';
import 'inventory_database.dart';
import 'reservation_database.dart';

enum ReservationStatus {
  completed,
  pendingConfirmation,
  confirmed,
  rejected,
}

class ClientReservation {
  const ClientReservation({
    this.id,
    this.userEmail,
    required this.routeName,
    required this.date,
    required this.createdAt,
    this.confirmedAt,
    required this.reservationTime,
    required this.people,
    required this.total,
    required this.status,
    this.equipmentQuantities = const {},
    this.reservationDetails,
    this.rejectionReason,
    this.rejectedByEmail,
    this.rejectedByName,
  });

  final int? id;
  final String? userEmail;
  final String routeName;
  final DateTime date;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final String reservationTime;
  final int people;
  final double total;
  final ReservationStatus status;
  final Map<String, int> equipmentQuantities;
  final String? reservationDetails;
  final String? rejectionReason;
  final String? rejectedByEmail;
  final String? rejectedByName;
}

class ReservationRepository {
  ReservationRepository._();

  static final ReservationRepository instance = ReservationRepository._();

  final ValueNotifier<List<ClientReservation>> reservations =
      ValueNotifier<List<ClientReservation>>(<ClientReservation>[]);

  Future<void> loadCurrentUserReservations() async {
    final String? userEmail = CurrentUserSession.instance.currentUserEmail;

    if (userEmail == null || userEmail.isEmpty) {
      reservations.value = <ClientReservation>[];
      return;
    }

    final List<Map<String, Object?>> rows =
        await ReservationDatabase.instance.getReservationsForUser(userEmail);

    reservations.value = rows
        .map(_reservationFromRow)
        .whereType<ClientReservation>()
        .toList();
  }

  Future<List<ClientReservation>> loadAllReservations() async {
    final List<Map<String, Object?>> rows =
        await ReservationDatabase.instance.getAllReservations();

    return rows
        .map(_reservationFromRow)
        .whereType<ClientReservation>()
        .toList();
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<Set<String>> getConfirmedReservationDateKeysForRouteAndTime({
    required String routeName,
    required String reservationTime,
    int? excludeReservationId,
  }) async {
    final normalizedRoute = routeName.trim();
    final normalizedTime = reservationTime.trim();
    final reservations = await loadAllReservations();

    return reservations
        .where((reservation) {
          if (reservation.status != ReservationStatus.confirmed) {
            return false;
          }
          if (excludeReservationId != null && reservation.id == excludeReservationId) {
            return false;
          }
          return reservation.routeName.trim() == normalizedRoute &&
              reservation.reservationTime.trim() == normalizedTime;
        })
        .map((reservation) => _dateKey(reservation.date))
        .toSet();
  }

  ClientReservation? _reservationFromRow(Map<String, Object?> row) {
    try {
      final id = (row['id'] as num?)?.toInt();
      final routeName = (row['route_name'] as String?)?.trim();
      final rawDate = row['date'] as String?;
      final date = rawDate == null ? null : DateTime.tryParse(rawDate);
      final createdAtRaw = row['created_at'] as String?;
      final createdAt = createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw);
        final confirmedAtRaw = row['confirmed_at'] as String?;
        final confirmedAt =
          confirmedAtRaw == null ? null : DateTime.tryParse(confirmedAtRaw);
      final reservationTime = ((row['reservation_time'] as String?) ?? '08:00').trim();
      final people = (row['people'] as num?)?.toInt();
      final total = (row['total'] as num?)?.toDouble();
      final statusName = (row['status'] as String?)?.trim();

      if (id == null ||
          routeName == null ||
          routeName.isEmpty ||
          date == null ||
          createdAt == null ||
          reservationTime.isEmpty ||
          people == null ||
          total == null) {
        return null;
      }

      return ClientReservation(
        id: id,
        userEmail: row['user_email'] as String?,
        routeName: routeName,
        date: date,
        createdAt: createdAt,
        confirmedAt: confirmedAt,
        reservationTime: reservationTime,
        people: people,
        total: total,
        status: ReservationStatus.values.firstWhere(
          (status) => status.name == statusName,
          orElse: () => ReservationStatus.pendingConfirmation,
        ),
        equipmentQuantities: _decodeEquipmentQuantities(
          row['equipment_json'] as String?,
        ),
        reservationDetails: row['reservation_details'] as String?,
        rejectionReason: row['rejection_reason'] as String?,
        rejectedByEmail: row['rejected_by_email'] as String?,
        rejectedByName: row['rejected_by_name'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> addReservation(ClientReservation reservation) async {
    final String? userEmail = CurrentUserSession.instance.currentUserEmail;

    if (userEmail == null || userEmail.isEmpty) {
      throw StateError('No hay un cliente autenticado para guardar la reserva.');
    }

    final hasConflict = await ReservationDatabase.instance.hasConfirmedReservationConflict(
      routeName: reservation.routeName,
      date: reservation.date,
      reservationTime: reservation.reservationTime,
    );
    if (hasConflict) {
      throw StateError(
        'Esa ruta ya tiene una reserva confirmada para la fecha y hora seleccionadas.',
      );
    }

    await ReservationDatabase.instance.insertReservation(
      userEmail: userEmail,
      routeName: reservation.routeName,
      date: reservation.date,
      reservationTime: reservation.reservationTime,
      people: reservation.people,
      total: reservation.total,
      status: reservation.status.name,
      equipmentJson: _encodeEquipmentQuantities(reservation.equipmentQuantities),
      reservationDetails: reservation.reservationDetails,
    );

    await AppNotificationService.instance.notifyWorkerNewReservation(
      routeName: reservation.routeName,
      routeDate: reservation.date,
      reservationTime: reservation.reservationTime,
    );

    await loadCurrentUserReservations();
  }

  Future<void> updateReservation(ClientReservation reservation) async {
    final String? userEmail = CurrentUserSession.instance.currentUserEmail;

    if (userEmail == null || userEmail.isEmpty) {
      throw StateError('No hay un cliente autenticado para actualizar la reserva.');
    }

    if (reservation.id == null) {
      throw StateError('La reserva no tiene identificador persistente.');
    }

    final hasConflict = await ReservationDatabase.instance.hasConfirmedReservationConflict(
      routeName: reservation.routeName,
      date: reservation.date,
      reservationTime: reservation.reservationTime,
      excludeReservationId: reservation.id,
    );
    if (hasConflict) {
      throw StateError(
        'Esa ruta ya tiene una reserva confirmada para la fecha y hora seleccionadas.',
      );
    }

    await ReservationDatabase.instance.updateReservation(
      userEmail: userEmail,
      reservationId: reservation.id!,
      routeName: reservation.routeName,
      date: reservation.date,
      reservationTime: reservation.reservationTime,
      people: reservation.people,
      total: reservation.total,
      status: reservation.status.name,
      equipmentJson: _encodeEquipmentQuantities(reservation.equipmentQuantities),
      reservationDetails: reservation.reservationDetails,
    );

    await loadCurrentUserReservations();
  }

  Future<void> deleteReservation(ClientReservation reservation) async {
    final String? userEmail = CurrentUserSession.instance.currentUserEmail;

    if (userEmail == null || userEmail.isEmpty) {
      throw StateError('No hay un cliente autenticado para eliminar la reserva.');
    }

    if (reservation.id == null) {
      throw StateError('La reserva no tiene identificador persistente.');
    }

    await ReservationDatabase.instance.deleteReservation(
      userEmail: userEmail,
      reservationId: reservation.id!,
    );

    await loadCurrentUserReservations();
  }

  Future<void> clearLoadedReservations() async {
    reservations.value = <ClientReservation>[];
  }

  Future<void> updateReservationStatusByWorker({
    required ClientReservation reservation,
    required ReservationStatus newStatus,
    String? rejectionReason,
    required String workerEmail,
    required String workerName,
  }) async {
    if (reservation.id == null) {
      throw StateError('La reserva no tiene identificador persistente.');
    }

    final normalizedReason = rejectionReason?.trim();
    if (newStatus == ReservationStatus.rejected &&
        (normalizedReason == null || normalizedReason.isEmpty)) {
      throw StateError('Debes indicar una razón de rechazo.');
    }

    if (newStatus == ReservationStatus.confirmed) {
      final hasConflict =
          await ReservationDatabase.instance.hasConfirmedReservationConflict(
        routeName: reservation.routeName,
        date: reservation.date,
        reservationTime: reservation.reservationTime,
        excludeReservationId: reservation.id,
      );
      if (hasConflict) {
        throw StateError(
          'Fecha no disponible: ya existe otra reserva confirmada para esa ruta, fecha y horario.',
        );
      }
    }

    await ReservationDatabase.instance.updateReservationStatusById(
      reservationId: reservation.id!,
      status: newStatus.name,
      rejectionReason: newStatus == ReservationStatus.rejected
          ? normalizedReason
          : null,
      rejectedByEmail: newStatus == ReservationStatus.rejected
          ? workerEmail.trim().toLowerCase()
          : null,
      rejectedByName: newStatus == ReservationStatus.rejected
          ? workerName.trim()
          : null,
    );

    if (newStatus == ReservationStatus.confirmed &&
        reservation.equipmentQuantities.isNotEmpty) {
      await InventoryDatabase.instance.ensureRouteSelectableItems();
      await InventoryDatabase.instance.applyConfirmedRental(
        reservation.equipmentQuantities,
      );
    }

    if (newStatus == ReservationStatus.completed &&
        reservation.equipmentQuantities.isNotEmpty) {
      await InventoryDatabase.instance.ensureRouteSelectableItems();
      await InventoryDatabase.instance.applyCompletedReturn(
        reservation.equipmentQuantities,
      );
    }

    final clientEmail = reservation.userEmail?.trim().toLowerCase();
    if (clientEmail != null && clientEmail.isNotEmpty) {
      final statusText = newStatus == ReservationStatus.confirmed
          ? 'confirmada'
          : newStatus == ReservationStatus.rejected
              ? 'rechazada'
              : newStatus.name;
      await AppNotificationService.instance.notifyClientRouteStatus(
        clientEmail: clientEmail,
        routeName: reservation.routeName,
        status: statusText,
      );
    }
  }

  String _encodeEquipmentQuantities(Map<String, int> equipmentQuantities) {
    return jsonEncode(equipmentQuantities);
  }

  Map<String, int> _decodeEquipmentQuantities(String? equipmentJson) {
    if (equipmentJson == null || equipmentJson.trim().isEmpty) {
      return <String, int>{};
    }

    final decoded = jsonDecode(equipmentJson);
    if (decoded is! Map) {
      return <String, int>{};
    }

    return decoded.map<String, int>((key, value) {
      return MapEntry(key.toString(), (value as num).toInt());
    });
  }
}
