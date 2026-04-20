import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/current_user_session.dart';
import '../data/reservation_repository.dart';
import '../data/user_preferences_store.dart';

class AppNotificationService {
  AppNotificationService._();

  static final AppNotificationService instance = AppNotificationService._();
  static const String workerEmail = 'trabajador@gmail.com';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  int _nextId = 1;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> enqueueNotificationForUser({
    required String userEmail,
    required String title,
    required String body,
    required String kind,
  }) async {
    await UserPreferencesStore.instance.addPendingNotification(
      userEmail: userEmail,
      title: title,
      body: body,
      kind: kind,
    );
  }

  Future<void> notifyWorkerNewReservation({
    required String routeName,
    required DateTime routeDate,
    required String reservationTime,
  }) async {
    final dateText =
        '${routeDate.day.toString().padLeft(2, '0')}/${routeDate.month.toString().padLeft(2, '0')}/${routeDate.year}';
    await enqueueNotificationForUser(
      userEmail: workerEmail,
      title: 'Nueva solicitud de ruta',
      body: '$routeName · $dateText · $reservationTime',
      kind: 'worker_new_reservation',
    );
  }

  Future<void> notifyClientRouteStatus({
    required String clientEmail,
    required String routeName,
    required String status,
  }) async {
    await enqueueNotificationForUser(
      userEmail: clientEmail,
      title: 'Actualizacion de tu reserva',
      body: '$routeName ha sido $status.',
      kind: 'client_route_status',
    );
  }

  Future<void> notifyMessageReceived({
    required String recipientEmail,
    required String senderName,
    required String preview,
  }) async {
    await enqueueNotificationForUser(
      userEmail: recipientEmail,
      title: 'Nuevo mensaje de $senderName',
      body: preview,
      kind: 'chat_message',
    );
  }

  Future<void> queueDayBeforeRouteRemindersForUser({
    required String userEmail,
    required List<ClientReservation> reservations,
  }) async {
    final remindersEnabled =
        await UserPreferencesStore.instance.getRouteRemindersEnabled(
      userEmail: userEmail,
    );
    if (remindersEnabled == false) {
      return;
    }

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));

    for (final reservation in reservations) {
      if (reservation.status != ReservationStatus.confirmed ||
          reservation.userEmail?.trim().toLowerCase() !=
              userEmail.trim().toLowerCase()) {
        continue;
      }

      final routeDay = DateTime(
        reservation.date.year,
        reservation.date.month,
        reservation.date.day,
      );
      if (routeDay != tomorrow) {
        continue;
      }

      final reservationId = reservation.id;
      if (reservationId == null) {
        continue;
      }

      final flag =
          'route_reminder_${reservationId}_${routeDay.toIso8601String()}';
      final alreadyQueued = await UserPreferencesStore.instance.getDeliveryFlag(
        userEmail: userEmail,
        flag: flag,
      );
      if (alreadyQueued) {
        continue;
      }

      final dateText =
          '${reservation.date.day.toString().padLeft(2, '0')}/${reservation.date.month.toString().padLeft(2, '0')}/${reservation.date.year}';
      await enqueueNotificationForUser(
        userEmail: userEmail,
        title: 'Recordatorio de ruta',
        body:
            'Manana tienes ${reservation.routeName} a las ${reservation.reservationTime} ($dateText).',
        kind: 'route_reminder',
      );
      await UserPreferencesStore.instance.setDeliveryFlag(
        userEmail: userEmail,
        flag: flag,
        value: true,
      );
    }
  }

  Future<void> processPendingNotificationsForCurrentUser({
    List<ClientReservation> reservations = const <ClientReservation>[],
  }) async {
    final currentEmail = CurrentUserSession.instance.currentUserEmail;
    if (currentEmail == null || currentEmail.isEmpty) {
      return;
    }

    await initialize();

    if (currentEmail != workerEmail) {
      await queueDayBeforeRouteRemindersForUser(
        userEmail: currentEmail,
        reservations: reservations,
      );
    }

    final notificationsEnabled =
        await UserPreferencesStore.instance.getNotificationsEnabled(
      userEmail: currentEmail,
    );
    final remindersEnabled =
        await UserPreferencesStore.instance.getRouteRemindersEnabled(
      userEmail: currentEmail,
    );

    final pending = await UserPreferencesStore.instance.getPendingNotifications(
      userEmail: currentEmail,
    );

    if (pending.isEmpty) {
      return;
    }

    final stillPending = <Map<String, String>>[];
    for (final entry in pending) {
      final kind = (entry['kind'] ?? '').trim();
      final isReminder = kind == 'route_reminder';
      final canShow = currentEmail == workerEmail
          ? true
          : isReminder
              ? remindersEnabled != false
              : notificationsEnabled != false;

      if (!canShow) {
        stillPending.add(entry);
        continue;
      }

      if (!kIsWeb) {
        await _showNotification(
          title: entry['title'] ?? 'GreenScape',
          body: entry['body'] ?? '',
        );
      }
    }

    await UserPreferencesStore.instance.savePendingNotifications(
      userEmail: currentEmail,
      notifications: stillPending,
    );
  }

  Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'greenscape_updates',
      'Actualizaciones GreenScape',
      channelDescription: 'Notificaciones de reservas, rutas y mensajes.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(_nextId++, title, body, details);
  }
}
