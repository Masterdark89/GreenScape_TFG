import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/app_notification_service.dart';
import 'data/firebase_data_seeder.dart';
import 'data/current_user_session.dart';
import 'data/reservation_repository.dart';
import 'pantalla/inventario.dart';
import 'pantalla/inicio.dart';
import 'pantalla/cliente1.dart';
import 'pantalla/trabajador1.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await FirebaseDataSeeder.instance.seedAll();
  } catch (error) {
    debugPrint('No se pudo sembrar Firestore: $error');
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  static const bool _startInInventory = bool.fromEnvironment('START_INVENTORY');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'ES'),
      supportedLocales: const [Locale('es', 'ES')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        textTheme: GoogleFonts.manropeTextTheme(),
      ),
      home: _startInInventory ? const InventoryScreen() : const _StartupGate(),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  late final Future<void> _restoreSessionFuture;

  Future<void> _restoreSessionAndData() async {
    await CurrentUserSession.instance.restore();
    final currentEmail = CurrentUserSession.instance.currentUserEmail;
    if (currentEmail == null ||
        currentEmail.isEmpty ||
        currentEmail == 'trabajador@gmail.com') {
      await ReservationRepository.instance.clearLoadedReservations();
      await AppNotificationService.instance
          .processPendingNotificationsForCurrentUser();
      return;
    }
    await ReservationRepository.instance.loadCurrentUserReservations();
    await AppNotificationService.instance.processPendingNotificationsForCurrentUser(
      reservations: ReservationRepository.instance.reservations.value,
    );
  }

  @override
  void initState() {
    super.initState();
    _restoreSessionFuture = _restoreSessionAndData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _restoreSessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final currentEmail = CurrentUserSession.instance.currentUserEmail;
        if (currentEmail == null || currentEmail.isEmpty) {
          return const LoginScreen();
        }

        if (currentEmail == 'trabajador@gmail.com') {
          return const WorkerMainScreen();
        }

        return const MainScreen();
      },
    );
  }
}
