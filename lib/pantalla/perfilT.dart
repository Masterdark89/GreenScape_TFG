import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/user_database.dart';
import '../data/current_user_session.dart';
import '../data/reservation_repository.dart';
import '../data/user_preferences_store.dart';
import 'trabajador1.dart';
import 'inventario.dart';
import 'chatTrabajador.dart';
import 'inicio.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  static const int _profileEditCooldownDays = 15;

  int _selectedIndex = 3;
  bool _isAvatarHovered = false;
  bool _isLoadingProfile = true;
  Uint8List? _profileImageBytes;
  String _profileName = 'Usuario Trabajador';
  String _profileEmail = 'trabajador@gmail.com';
  String _profilePhone = '+34 645 987 321';
  String _profileCity = 'Sevilla';

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
    final phoneController = TextEditingController(text: _profilePhone);
    final cityController = TextEditingController(text: _profileCity);

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
    if ((submitted['phone'] ?? '') != _profilePhone) {
      updates['phone'] = submitted['phone']!;
    }
    if ((submitted['city'] ?? '') != _profileCity) {
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

    final Map<String, Object?>? userData =
        await UserDatabase.instance.getUserByEmail(currentEmail);

    if (!mounted) return;
    setState(() {
      _profileEmail = currentEmail;
      _profileName = (userData?['name'] as String?)?.trim().isNotEmpty == true
          ? (userData!['name'] as String)
          : 'Usuario Trabajador';
      _profilePhone = (userData?['phone'] as String?)?.trim().isNotEmpty == true
          ? (userData!['phone'] as String)
          : '+34 645 987 321';
      _profileCity = (userData?['city'] as String?)?.trim().isNotEmpty == true
          ? (userData!['city'] as String)
          : 'Sevilla';
      _isLoadingProfile = false;
    });

    final profileImage = await UserPreferencesStore.instance.getProfileImageBytes(
      userEmail: currentEmail,
    );

    if (!mounted) return;
    setState(() {
      _profileImageBytes = profileImage != null ? Uint8List.fromList(profileImage) : null;
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

    final currentEmail = _currentUserEmail;
    if (currentEmail != null && currentEmail.isNotEmpty) {
      await UserPreferencesStore.instance.saveProfileImageBytes(
        userEmail: currentEmail,
        bytes: bytes,
      );
    }

    if (!mounted) return;
    setState(() {
      _profileImageBytes = bytes;
    });
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) {
      return;
    }

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const InventoryScreen()),
      );
      return;
    }

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorkerMainScreen()),
      );
      return;
    }

    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorkerChatScreen()),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
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
              // Header
              Text(
                'GreenScape',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 20),

              // Título
              Text(
                'Mi Perfil',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 24),

              // Foto y nombre (Avatar)
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
              _isLoadingProfile
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _buildPersonalInfoContainer(),
              const SizedBox(height: 24),

              // Estadísticas de trabajo
              Text(
                'Estadísticas',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard('Rutas', '127'),
                  const SizedBox(width: 12),
                  _buildStatCard('Clientes', '542'),
                ],
              ),
              const SizedBox(height: 24),

              // Certificaciones
              Text(
                'Certificaciones',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              _buildCertificationCard('Primeros Auxilios', 'Vigente', Colors.green),
              _buildCertificationCard('Rescate en Montaña', 'Vigente', Colors.green),
              _buildCertificationCard('Monitor de Escalada', 'Vence en 180 días', Colors.orange),
              const SizedBox(height: 24),

              // Disponibilidad
              Text(
                'Disponibilidad',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              _buildAvailabilityDay('Lunes - Viernes', 'Disponible'),
              _buildAvailabilityDay('Sábado - Domingo', 'Disponible'),
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
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Reservas',
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
          _buildInfoRow('Puesto', 'Guía de Montaña'),
          Divider(color: Colors.grey.shade200, height: 20),
          _buildInfoRow('Ciudad', _profileCity),
        ],
      ),
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

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationCard(String name, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(fontSize: 12, color: statusColor),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle,
                size: 18,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityDay(String days, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              days,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
