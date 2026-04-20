import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_notification_service.dart';
import '../data/current_user_session.dart';
import '../data/reservation_repository.dart';
import '../data/user_database.dart';
import '../data/user_preferences_store.dart';
import 'cliente1.dart';
import 'pago.dart';
import 'chatCliente.dart';
import 'inicio.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  static const int _profileEditCooldownDays = 15;

  int _selectedIndex = 3;
  bool _notificationsEnabled = true;
  bool _routeRemindersEnabled = true;
  bool _isAvatarHovered = false;
  bool _isLoadingProfile = true;
  Uint8List? _profileImageBytes;
  String _profileName = 'Usuario Cliente';
  String _profileEmail = 'cliente@gmail.com';
  String _profilePhone = '-';
  String _profileCity = '-';

  String? get _currentUserEmail => CurrentUserSession.instance.currentUserEmail;

  int _remainingCooldownDays(DateTime lastUpdate) {
    final cooldown = Duration(days: _profileEditCooldownDays);
    final elapsed = DateTime.now().difference(lastUpdate);
    final remaining = cooldown - elapsed;
    if (remaining <= Duration.zero) {
      return 0;
    }
    return (remaining.inHours / 24).ceil();
  }

  String _fieldLabel(String field) {
    switch (field) {
      case 'name':
        return 'nombre';
      case 'phone':
        return 'teléfono';
      case 'city':
        return 'ciudad';
      default:
        return field;
    }
  }

  Future<void> _openEditProfileDialog() async {
    final currentEmail = _currentUserEmail;
    if (currentEmail == null || currentEmail.isEmpty) {
      return;
    }

    final nameController = TextEditingController(text: _profileName);
    final phoneController = TextEditingController(text: _profilePhone == '-' ? '' : _profilePhone);
    final cityController = TextEditingController(text: _profileCity == '-' ? '' : _profileCity);

    final Map<String, String>? submitted = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Editar perfil'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(labelText: 'Ciudad'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop({
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'city': cityController.text.trim(),
                });
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    cityController.dispose();

    if (submitted == null) {
      return;
    }

    final updates = <String, String>{};
    if ((submitted['name'] ?? '').isNotEmpty && submitted['name'] != _profileName) {
      updates['name'] = submitted['name']!;
    }
    if ((submitted['phone'] ?? '') != (_profilePhone == '-' ? '' : _profilePhone)) {
      updates['phone'] = submitted['phone']!;
    }
    if ((submitted['city'] ?? '') != (_profileCity == '-' ? '' : _profileCity)) {
      updates['city'] = submitted['city']!;
    }

    if (updates.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cambios para guardar.')),
      );
      return;
    }

    final blockedFields = <String, int>{};
    for (final field in updates.keys) {
      final lastUpdated = await UserPreferencesStore.instance.getProfileFieldLastUpdatedAt(
        userEmail: currentEmail,
        field: field,
      );
      if (lastUpdated == null) {
        continue;
      }
      final remainingDays = _remainingCooldownDays(lastUpdated);
      if (remainingDays > 0) {
        blockedFields[field] = remainingDays;
      }
    }

    if (blockedFields.isNotEmpty) {
      final details = blockedFields.entries
          .map((entry) => '${_fieldLabel(entry.key)} (${entry.value} días)')
          .join(', ');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aún no puedes editar: $details.'),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    try {
      await UserDatabase.instance.updateUserProfile(
        email: currentEmail,
        name: updates['name'],
        phone: updates['phone'],
        city: updates['city'],
      );

      final changedAt = DateTime.now();
      for (final field in updates.keys) {
        await UserPreferencesStore.instance.saveProfileFieldLastUpdatedAt(
          userEmail: currentEmail,
          field: field,
          changedAt: changedAt,
        );
      }

      await _loadProfileData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar el perfil: $e'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final String? currentEmail = CurrentUserSession.instance.currentUserEmail;
    if (currentEmail == null || currentEmail.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
      });
      return;
    }

    await ReservationRepository.instance.loadCurrentUserReservations();
    final Map<String, Object?>? userData =
        await UserDatabase.instance.getUserByEmail(currentEmail);

    if (!mounted) return;
    setState(() {
      _profileEmail = currentEmail;
      _profileName = (userData?['name'] as String?)?.trim().isNotEmpty == true
          ? (userData!['name'] as String)
          : 'Usuario Cliente';
      _profilePhone = (userData?['phone'] as String?)?.trim().isNotEmpty == true
          ? (userData!['phone'] as String)
          : '-';
      _profileCity = (userData?['city'] as String?)?.trim().isNotEmpty == true
          ? (userData!['city'] as String)
          : '-';
      _isLoadingProfile = false;
    });

    final profileImage = await UserPreferencesStore.instance.getProfileImageBytes(
      userEmail: currentEmail,
    );
    final notifications = await UserPreferencesStore.instance.getNotificationsEnabled(
      userEmail: currentEmail,
    );
    final routeReminders = await UserPreferencesStore.instance.getRouteRemindersEnabled(
      userEmail: currentEmail,
    );

    if (!mounted) return;
    setState(() {
      _profileImageBytes = profileImage != null ? Uint8List.fromList(profileImage) : null;
      _notificationsEnabled = notifications ?? _notificationsEnabled;
      _routeRemindersEnabled = routeReminders ?? _routeRemindersEnabled;
    });
  }

  ClientReservation? _latestPendingOrConfirmed(
    List<ClientReservation> reservations,
  ) {
    for (final reservation in reservations) {
      if (reservation.status == ReservationStatus.pendingConfirmation ||
          reservation.status == ReservationStatus.confirmed) {
        return reservation;
      }
    }
    return null;
  }

  String _formatReservationDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _reservationStatusLabel(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pendingConfirmation:
        return 'Por confirmar';
      case ReservationStatus.confirmed:
        return 'Confirmada';
      case ReservationStatus.rejected:
        return 'Rechazada';
      case ReservationStatus.completed:
        return 'Realizada';
    }
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) {
      return;
    }

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CheckoutScreen()),
      );
      return;
    }

    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
      return;
    }

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _pickProfileImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final bytes = result.files.single.bytes;
    if (bytes == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final currentEmail = _currentUserEmail;
    if (currentEmail != null && currentEmail.isNotEmpty) {
      await UserPreferencesStore.instance.saveProfileImageBytes(
        userEmail: currentEmail,
        bytes: bytes,
      );
    }

    setState(() {
      _profileImageBytes = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(248, 250, 245, 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GreenScape',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Perfil del cliente',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          _isAvatarHovered = true;
                        });
                      },
                      onExit: (_) {
                        setState(() {
                          _isAvatarHovered = false;
                        });
                      },
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _pickProfileImage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                shape: BoxShape.circle,
                                image: _profileImageBytes != null
                                    ? DecorationImage(
                                        image: MemoryImage(_profileImageBytes!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _profileImageBytes == null
                                  ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.green.shade700,
                                    )
                                  : null,
                            ),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: _isAvatarHovered ? 1 : 0,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.upload,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Subir imagen',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _profileName,
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _profileEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 32),

              // Información personal
              Text(
                'Información Personal',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _isLoadingProfile ? null : _openEditProfileDialog,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar perfil'),
                ),
              ),
              const SizedBox(height: 12),
              _buildPersonalInfoContainer(),
              const SizedBox(height: 24),

              // Ultima reserva
              Text(
                'Ultima reserva',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              _buildLastReservationSection(),
              const SizedBox(height: 24),

              // Preferencias
              Text(
                'Preferencias',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              _buildSwitchOption(
                label: 'Notificaciones',
                value: _notificationsEnabled,
                onChanged: (newValue) async {
                  final currentEmail = _currentUserEmail;
                  if (currentEmail != null && currentEmail.isNotEmpty) {
                    await UserPreferencesStore.instance.saveNotificationsEnabled(
                      userEmail: currentEmail,
                      enabled: newValue,
                    );
                    if (newValue) {
                      await AppNotificationService.instance
                          .processPendingNotificationsForCurrentUser(
                        reservations: ReservationRepository.instance.reservations.value,
                      );
                    }
                  }
                  if (!mounted) return;
                  setState(() {
                    _notificationsEnabled = newValue;
                  });
                },
              ),
              _buildSwitchOption(
                label: 'Recordatorios de ruta',
                value: _routeRemindersEnabled,
                onChanged: (newValue) async {
                  final currentEmail = _currentUserEmail;
                  if (currentEmail != null && currentEmail.isNotEmpty) {
                    await UserPreferencesStore.instance.saveRouteRemindersEnabled(
                      userEmail: currentEmail,
                      enabled: newValue,
                    );
                    if (newValue) {
                      await AppNotificationService.instance
                          .processPendingNotificationsForCurrentUser(
                        reservations: ReservationRepository.instance.reservations.value,
                      );
                    }
                  }
                  if (!mounted) return;
                  setState(() {
                    _routeRemindersEnabled = newValue;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Botones de acción
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await CurrentUserSession.instance.clear();
                    await ReservationRepository.instance.clearLoadedReservations();
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade700),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cerrar Sesión'),
                ),
              ),
            ],
          ),
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
            icon: Icon(Icons.calendar_today),
            label: 'Reservas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explorar',
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

  Widget _buildPersonalInfoContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildInfoRow('Nombre', _profileName),
          Divider(color: Colors.grey.shade200, height: 20),
          _buildInfoRow('Teléfono', _profilePhone),
          Divider(color: Colors.grey.shade200, height: 20),
          _buildInfoRow('Ciudad', _profileCity),
        ],
      ),
    );
  }

  Widget _buildLastReservationSection() {
    if (_isLoadingProfile) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ValueListenableBuilder<List<ClientReservation>>(
      valueListenable: ReservationRepository.instance.reservations,
      builder: (context, reservations, _) {
        final ClientReservation? lastReservation =
            _latestPendingOrConfirmed(reservations);

        if (lastReservation == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'Aún no hay reservas por confirmar o confirmadas.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          );
        }

        return _buildReservationCard(
          routeName: lastReservation.routeName,
          date: _formatReservationDate(lastReservation.date),
          people: '${lastReservation.people} personas',
          status: _reservationStatusLabel(lastReservation.status),
          total: '${lastReservation.total.toStringAsFixed(2)}€',
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildReservationCard(
      {
        required String routeName,
        required String date,
        required String people,
        required String status,
        required String total,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              routeName,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  people,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.verified_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  status,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.euro, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  total,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchOption({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.green.shade700,
          ),
        ],
      ),
    );
  }
}
