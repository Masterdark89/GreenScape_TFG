import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/current_user_session.dart';
import '../data/inventory_database.dart';
import '../models/inventory_item.dart';
import '../data/reservation_repository.dart';
import '../data/user_database.dart';
import 'chatTrabajador.dart';
import 'inventario.dart';
import 'perfilT.dart';

class WorkerMainScreen extends StatefulWidget {
  const WorkerMainScreen({super.key});

  @override
  State<WorkerMainScreen> createState() => _WorkerMainScreenState();
}

class _WorkerMainScreenState extends State<WorkerMainScreen> {
  int _selectedIndex = 1;
  String? _workerEmailSnapshot;
  bool _isLoadingReservations = true;
  bool _isLoadingInventory = true;
  List<ClientReservation> _allReservations = <ClientReservation>[];
  final InventoryDatabase _inventoryDatabase = InventoryDatabase.instance;
  List<InventoryItem> _inventoryItems = <InventoryItem>[];

  @override
  void initState() {
    super.initState();
    _workerEmailSnapshot = CurrentUserSession.instance.currentUserEmail;
    _loadReservations();
    _loadInventory();
  }

  Future<void> _ensureWorkerSessionConsistency() async {
    final snapshot = _workerEmailSnapshot;
    if (snapshot == null || snapshot.isEmpty) {
      return;
    }

    final current = CurrentUserSession.instance.currentUserEmail;
    if (current == snapshot) {
      return;
    }

    await CurrentUserSession.instance.setCurrentUserEmail(snapshot);
  }

  Future<void> _loadReservations() async {
    try {
      final reservations = await ReservationRepository.instance.loadAllReservations();
      if (!mounted) return;
      setState(() {
        _allReservations = reservations;
        _isLoadingReservations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allReservations = <ClientReservation>[];
        _isLoadingReservations = false;
      });
    }
  }

  Future<void> _loadInventory() async {
    try {
      await _inventoryDatabase.ensureRouteSelectableItems();
      final items = await _inventoryDatabase.getAllItems();
      if (!mounted) return;
      setState(() {
        _inventoryItems = items;
        _isLoadingInventory = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _inventoryItems = <InventoryItem>[];
        _isLoadingInventory = false;
      });
    }
  }

  List<ClientReservation> get _pendingReservations {
    return _allReservations
        .where((reservation) => reservation.status == ReservationStatus.pendingConfirmation)
        .toList();
  }

  List<ClientReservation> get _confirmedReservationsPendingToDo {
    return _allReservations
        .where((reservation) => reservation.status == ReservationStatus.confirmed)
        .toList();
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int get _todayReservationsCount {
    final DateTime now = DateTime.now();
    return _allReservations.where((reservation) {
      if (reservation.status != ReservationStatus.confirmed) {
        return false;
      }
      final confirmedAt = reservation.confirmedAt;
      if (confirmedAt == null) {
        return false;
      }
      return _isSameDate(confirmedAt, now);
    }).length;
  }

  List<InventoryItem> get _inventoryShortages {
    return _inventoryItems
      .where(
        (item) =>
        item.currentUnits <= 0 ||
        item.stockStatusDisplay.toUpperCase() == 'BAJO STOCK' ||
        item.stockStatusDisplay.toUpperCase() == 'SIN STOCK',
      )
        .toList();
  }

  int get _pendingConfirmationCount {
    return _pendingReservations.length;
  }

  String get _pendingConfirmationSubtitle {
    if (_pendingReservations.isEmpty) {
      return 'Sin reservas pendientes por confirmar';
    }

    final names = _pendingReservations.take(2).map((item) => item.routeName).join(', ');
    return 'Pendientes: $names';
  }

  String get _inventoryShortageSubtitle {
    if (_inventoryShortages.isEmpty) {
      return 'Sin faltas de inventario';
    }

    final names = _inventoryShortages.take(2).map((item) => item.name).join(', ');
    return 'Bajo stock / 0 stock: $names';
  }

  String _formatReservationDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatDateTime(DateTime value) {
    final date = _formatReservationDate(value);
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$date $hour:$minute';
  }

  String _formatEquipmentLine(MapEntry<String, int> entry) {
    final quantity = entry.value;
    return '${entry.key} x$quantity';
  }

  Future<String> _resolveReservationUserName(String? email) async {
    final normalizedEmail = email?.trim();
    if (normalizedEmail == null || normalizedEmail.isEmpty) {
      return 'Cliente sin nombre';
    }

    final userData = await UserDatabase.instance.getUserByEmail(normalizedEmail);
    final name = (userData?['name'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      return 'Cliente sin nombre';
    }

    return name;
  }

  Future<void> _showReservationDetails(ClientReservation reservation) async {
    final entries = reservation.equipmentQuantities.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final userName = await _resolveReservationUserName(reservation.userEmail);
    final userEmail = reservation.userEmail ?? 'Cliente sin correo';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        reservation.routeName,
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reservation.status == ReservationStatus.pendingConfirmation
                            ? 'Solicitud pendiente de confirmar'
                            : reservation.status == ReservationStatus.confirmed
                                ? 'Solicitud confirmada'
                                : reservation.status == ReservationStatus.completed
                                    ? 'Ruta realizada'
                                    : 'Solicitud rechazada',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildDetailRow('Cliente', userName),
                      _buildDetailRow('Correo', userEmail),
                      _buildDetailRow('Fecha de ruta', _formatReservationDate(reservation.date)),
                      _buildDetailRow('Hora', reservation.reservationTime),
                      _buildDetailRow('Personas', '${reservation.people}'),
                      _buildDetailRow('Solicitada', _formatDateTime(reservation.createdAt)),
                      if (reservation.reservationDetails != null &&
                          reservation.reservationDetails!.trim().isNotEmpty)
                        _buildDetailRow('Detalles', reservation.reservationDetails!.trim()),
                      if (reservation.confirmedAt != null)
                        _buildDetailRow('Confirmada', _formatDateTime(reservation.confirmedAt!)),
                      const SizedBox(height: 18),
                      Text(
                        'Material a alquilar',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (entries.isEmpty)
                        Text(
                          'No se ha incluido material de alquiler en esta solicitud.',
                          style: TextStyle(color: Colors.grey.shade700),
                        )
                      else
                        ...entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                _formatEquipmentLine(entry),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _slotKey(ClientReservation reservation) {
    final route = reservation.routeName.trim().toLowerCase();
    final date =
        '${reservation.date.year.toString().padLeft(4, '0')}-${reservation.date.month.toString().padLeft(2, '0')}-${reservation.date.day.toString().padLeft(2, '0')}';
    final time = reservation.reservationTime.trim();
    return '$route|$date|$time';
  }

  Future<void> _updateReservationStatus(
    ClientReservation reservation,
    ReservationStatus newStatus,
    String? rejectionReason,
  ) async {
    await _ensureWorkerSessionConsistency();
    final workerEmail = CurrentUserSession.instance.currentUserEmail;
    if (workerEmail == null || workerEmail.isEmpty) {
      throw StateError('No hay trabajador autenticado.');
    }

    final workerData = await UserDatabase.instance.getUserByEmail(workerEmail);
    final workerName =
        ((workerData?['name'] as String?)?.trim().isNotEmpty ?? false)
            ? (workerData!['name'] as String)
            : 'Trabajador';

    await ReservationRepository.instance.updateReservationStatusByWorker(
      reservation: reservation,
      newStatus: newStatus,
      rejectionReason: rejectionReason,
      workerEmail: workerEmail,
      workerName: workerName,
    );
    await _ensureWorkerSessionConsistency();
    await _loadReservations();
    await _loadInventory();
  }

  Future<void> _confirmReservation(ClientReservation reservation) async {
    try {
      await _updateReservationStatus(reservation, ReservationStatus.confirmed, null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva confirmada.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo confirmar la reserva: $e')),
      );
    }
  }

  Future<void> _completeReservation(ClientReservation reservation) async {
    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Marcar como completada'),
          content: const Text(
            '¿Quieres marcar esta ruta como completada? Se devolverá el material al inventario.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );

    if (shouldComplete != true) {
      return;
    }

    try {
      await _updateReservationStatus(reservation, ReservationStatus.completed, null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta marcada como realizada. Material devuelto al inventario.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo marcar como realizada: $e')),
      );
    }
  }

  Future<void> _rejectReservation(ClientReservation reservation) async {
    final reasonController = TextEditingController();
    final String? reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Razón de rechazo'),
          content: TextField(
            controller: reasonController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Escribe la razón del rechazo',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = reasonController.text.trim();
                if (value.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Debes indicar una razón para rechazar.'),
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(value);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    );
    reasonController.dispose();

    if (reason == null || reason.trim().isEmpty) {
      return;
    }

    try {
      await _updateReservationStatus(
        reservation,
        ReservationStatus.rejected,
        reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva rechazada.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo rechazar la reserva: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
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

    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorkerChatScreen()),
      );
      return;
    }

    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WorkerProfileScreen()),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final confirmedSlotKeys = _confirmedReservationsPendingToDo
        .map(_slotKey)
        .toSet();

    return Scaffold(
      backgroundColor: const Color.fromRGBO(248, 250, 245, 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                'GreenScape',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 20),

              // Tarjetas de métricas (reservas, pendientes, faltas)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'RESERVAS DEL DIA DE HOY',
                      value: _isLoadingReservations
                          ? '--'
                          : _todayReservationsCount.toString().padLeft(2, '0'),
                      backgroundColor: Colors.green.shade50,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'RESERVAS PENDIENTES POR CONFIRMAR',
                      value: _isLoadingReservations
                          ? '--'
                          : _pendingConfirmationCount.toString().padLeft(2, '0'),
                      subtitle: _isLoadingReservations
                          ? 'Cargando reservas...'
                          : _pendingConfirmationSubtitle,
                      backgroundColor: Colors.orange.shade50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMetricCard(
                title: 'FALTAS DE INVENTARIO',
                value: _isLoadingInventory
                    ? '--'
                    : _inventoryShortages.length.toString().padLeft(2, '0'),
                subtitle: _isLoadingInventory
                    ? 'Cargando faltas...'
                    : _inventoryShortageSubtitle,
                backgroundColor: Colors.red.shade50,
                fullWidth: true,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InventoryScreen(initialStockFilter: 'BAJO STOCK'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Rutas pendientes de realizar (confirmadas)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rutas pendientes de realizar',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Lista de rutas confirmadas pendientes de realizar
              if (_isLoadingReservations)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_confirmedReservationsPendingToDo.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    'No hay rutas confirmadas pendientes de realizar.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _confirmedReservationsPendingToDo.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final reservation = _confirmedReservationsPendingToDo[index];
                    return _buildRouteCard(
                      reservation: reservation,
                      showActions: false,
                      showCompleteAction: true,
                    );
                  },
                ),
              const SizedBox(height: 24),

              // Rutas pendientes por confirmar
              Text(
                'Rutas pendientes por confirmar',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoadingReservations)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_pendingReservations.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    'No hay rutas pendientes por confirmar.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pendingReservations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final reservation = _pendingReservations[index];
                    final isUnavailableSlot =
                        confirmedSlotKeys.contains(_slotKey(reservation));
                    return _buildRouteCard(
                      reservation: reservation,
                      showActions: true,
                      isUnavailableSlot: isUnavailableSlot,
                    );
                  },
                ),
              const SizedBox(height: 24),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    String? subtitle,
    Color? backgroundColor,
    bool fullWidth = false,
    VoidCallback? onTap,
  }) {
    final card = Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: card,
    );
  }

  Widget _buildRouteCard({
    required ClientReservation reservation,
    required bool showActions,
    bool isUnavailableSlot = false,
    bool showCompleteAction = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnavailableSlot ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnavailableSlot ? Colors.orange.shade300 : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reservation.routeName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reservation.userEmail ?? 'Cliente sin correo',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fecha de ruta: ${_formatReservationDate(reservation.date)} · ${reservation.reservationTime} · ${reservation.people} personas',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Solicitada: ${_formatDateTime(reservation.createdAt)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          if (reservation.reservationDetails != null &&
              reservation.reservationDetails!.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Detalles: ${reservation.reservationDetails!.trim()}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          if (isUnavailableSlot) ...[
            const SizedBox(height: 6),
            Text(
              'Fecha no disponible',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade800,
              ),
            ),
          ],
          if (showActions) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _showReservationDetails(reservation),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Ver más'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blueGrey.shade700,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () => _rejectReservation(reservation),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rechazar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                      ),
                    ),
                    if (!isUnavailableSlot) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _confirmReservation(reservation),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Confirmar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
          if (showCompleteAction) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _showReservationDetails(reservation),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Ver más'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blueGrey.shade700,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _completeReservation(reservation),
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: const Text('Marcar realizada'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

}
