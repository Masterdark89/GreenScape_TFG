import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/chat_database.dart';
import '../data/current_user_session.dart';
import '../data/reservation_repository.dart';
import '../data/user_database.dart';
import 'ruta.dart';
import 'chatCliente.dart';
import 'cliente1.dart';
import 'perfilC.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const List<String> _availableReservationTimes = <String>[
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
  ];

  int _selectedIndex = 0;
  ReservationStatus _activeFilter = ReservationStatus.pendingConfirmation;
  bool _isLoadingReservations = true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    try {
      await ReservationRepository.instance.loadCurrentUserReservations();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReservations = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _filterLabel(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.completed:
        return 'Rutas Realizadas';
      case ReservationStatus.pendingConfirmation:
        return 'Rutas en espera de Confirmación';
      case ReservationStatus.confirmed:
        return 'Rutas Confirmadas';
      case ReservationStatus.rejected:
        return 'Rutas Confirmadas';
    }
  }

  String _reservationStatusLabel(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pendingConfirmation:
        return 'Por confirmar';
      case ReservationStatus.confirmed:
        return 'Aprobada';
      case ReservationStatus.rejected:
        return 'Rechazada';
      case ReservationStatus.completed:
        return 'Realizada';
    }
  }

  List<ClientReservation> _applyFilter(List<ClientReservation> reservations) {
    if (_activeFilter == ReservationStatus.confirmed) {
      return reservations
          .where((reservation) =>
              reservation.status == ReservationStatus.confirmed ||
              reservation.status == ReservationStatus.rejected)
          .toList();
    }

    return reservations
        .where((reservation) => reservation.status == _activeFilter)
        .toList();
  }

  bool _showEmptyActionButton(List<ClientReservation> allReservations) {
    if (_activeFilter == ReservationStatus.completed) {
      return false;
    }

    if (_activeFilter == ReservationStatus.confirmed) {
      return !allReservations.any(
        (reservation) => reservation.status == ReservationStatus.pendingConfirmation,
      );
    }

    return true;
  }

  String _emptyMessage(List<ClientReservation> allReservations) {
    if (_activeFilter == ReservationStatus.completed) {
      return 'Aún no hay rutas';
    }

    if (_activeFilter == ReservationStatus.confirmed &&
        allReservations.any(
          (reservation) => reservation.status == ReservationStatus.pendingConfirmation,
        )) {
      return 'Reservas en observación';
    }

    return 'No hay reservas aún, ¡reserva ahora!';
  }

  void _goToExplore() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  double _calculateReservationTotal(
    RouteDetailData detail,
    int people,
    Map<String, int> equipmentQuantities,
  ) {
    double equipmentTotal = 0;
    for (final item in detail.purchasableEquipment) {
      final int quantity = equipmentQuantities[item.name] ?? 0;
      equipmentTotal += item.price * quantity;
    }
    return (people * detail.pricePerPerson) + equipmentTotal;
  }

  String _equipmentSummary(ClientReservation reservation) {
    if (reservation.equipmentQuantities.isEmpty) {
      return 'Sin equipamiento alquilado';
    }

    return reservation.equipmentQuantities.entries
        .map((entry) => '${entry.key} x${entry.value}')
        .join(' · ');
  }

  String? _reservationDetailsText(ClientReservation reservation) {
    final details = reservation.reservationDetails?.trim();
    if (details == null || details.isEmpty) {
      return null;
    }

    return details;
  }

  Future<void> _showRejectionReason(ClientReservation reservation) async {
    final reason = reservation.rejectionReason?.trim();
    if (reason == null || reason.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta reserva no tiene una razón registrada.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Razón de rechazo'),
          content: Text(reason),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startChatWithWorkerForReservation(ClientReservation reservation) async {
    final clientEmail = CurrentUserSession.instance.currentUserEmail;
    if (clientEmail == null || clientEmail.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión primero.')),
      );
      return;
    }

    final clientData = await UserDatabase.instance.getUserByEmail(clientEmail);
    final clientName =
        ((clientData?['name'] as String?)?.trim().isNotEmpty ?? false)
            ? (clientData!['name'] as String)
            : 'Cliente';

    final workerEmail =
        (reservation.rejectedByEmail?.trim().isNotEmpty ?? false)
            ? reservation.rejectedByEmail!.trim().toLowerCase()
            : ChatDatabase.supportWorkerEmail;
    final workerName =
        (reservation.rejectedByName?.trim().isNotEmpty ?? false)
            ? reservation.rejectedByName!.trim()
            : ChatDatabase.supportWorkerName;

    final conversationId = await ChatDatabase.instance.getOrCreateConversation(
      clientEmail: clientEmail,
      clientName: clientName,
      workerEmail: workerEmail,
      workerName: workerName,
    );

    final conversations = await ChatDatabase.instance.getConversationsForUser(clientEmail);
    if (conversations.isEmpty) {
      return;
    }

    final conversation = conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => conversations.first,
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientIndividualChatScreen(conversation: conversation),
      ),
    ).then((_) {
      if (!mounted) return;
      setState(() {
        _selectedIndex = 0;
      });
    });
  }

  Future<void> _openEditReservationDialog(ClientReservation reservation) async {
    if (reservation.status != ReservationStatus.pendingConfirmation) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo se pueden editar reservas pendientes de confirmación.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final RouteDetailData detail = buildRouteDetailFromRoute({
      'name': reservation.routeName,
    });

    int peopleCount = reservation.people;
    String selectedReservationTime = reservation.reservationTime;
    final TextEditingController detailsController = TextEditingController(
      text: reservation.reservationDetails ?? '',
    );
    final Map<String, int> equipmentQuantities = {
      for (final item in detail.purchasableEquipment)
        item.name: reservation.equipmentQuantities[item.name] ?? 0,
    };

    void clampEquipment() {
      for (final item in detail.purchasableEquipment) {
        final int current = equipmentQuantities[item.name] ?? 0;
        equipmentQuantities[item.name] = current.clamp(0, peopleCount);
      }
    }

    clampEquipment();

    final ClientReservation? updatedReservation = await showDialog<ClientReservation>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double updatedTotal = _calculateReservationTotal(
              detail,
              peopleCount,
              equipmentQuantities,
            );

            return AlertDialog(
              title: Text('Editar reserva', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.routeName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Personas', style: TextStyle(fontWeight: FontWeight.w500)),
                          Row(
                            children: [
                              IconButton(
                                onPressed: peopleCount <= 1
                                    ? null
                                    : () {
                                        setDialogState(() {
                                          peopleCount--;
                                          clampEquipment();
                                        });
                                      },
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('$peopleCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                              IconButton(
                                onPressed: peopleCount >= detail.maxPeople
                                    ? null
                                    : () {
                                        setDialogState(() {
                                          peopleCount++;
                                          clampEquipment();
                                        });
                                      },
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Hora de salida', style: TextStyle(fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _availableReservationTimes.contains(selectedReservationTime)
                                    ? selectedReservationTime
                                    : _availableReservationTimes.first,
                                items: _availableReservationTimes
                                    .map(
                                      (time) => DropdownMenuItem<String>(
                                        value: time,
                                        child: Text(time),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setDialogState(() {
                                    selectedReservationTime = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: detailsController,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          labelText: 'Detalles de la reserva',
                          hintText: 'Añade observaciones para el trabajador',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Equipamiento de alquiler',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(detail.purchasableEquipment.length, (index) {
                        final item = detail.purchasableEquipment[index];
                        final int quantity = equipmentQuantities[item.name] ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.price.toStringAsFixed(2)}€ por unidad',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: quantity <= 0
                                        ? null
                                        : () {
                                            setDialogState(() {
                                              equipmentQuantities[item.name] = quantity - 1;
                                            });
                                          },
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                  Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  IconButton(
                                    onPressed: quantity >= peopleCount
                                        ? null
                                        : () {
                                            setDialogState(() {
                                              equipmentQuantities[item.name] = quantity + 1;
                                            });
                                          },
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total actualizado', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('${updatedTotal.toStringAsFixed(2)}€', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(
                      ClientReservation(
                        id: reservation.id,
                        routeName: reservation.routeName,
                        date: reservation.date,
                        createdAt: reservation.createdAt,
                        reservationTime: selectedReservationTime,
                        people: peopleCount,
                        total: updatedTotal,
                        status: reservation.status,
                        equipmentQuantities: Map<String, int>.from(equipmentQuantities),
                        reservationDetails: detailsController.text.trim().isEmpty
                            ? null
                            : detailsController.text.trim(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    detailsController.dispose();

    if (updatedReservation == null) {
      return;
    }

    try {
      await ReservationRepository.instance.updateReservation(updatedReservation);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La reserva ha sido actualizada.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar la reserva: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _confirmCancelReservation(ClientReservation reservation) async {
    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancelar reserva'),
          content: const Text(
            '¿Seguro que quieres cancelar esta reserva? Esta acción eliminará la reserva de forma permanente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sí, cancelar'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true) {
      return;
    }

    try {
      await ReservationRepository.instance.deleteReservation(reservation);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La reserva ha sido cancelada.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cancelar la reserva: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) {
      return;
    }

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
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

    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ClientProfileScreen()),
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
        child: Padding(
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
              const SizedBox(height: 20),
              Text(
                'Mis reservas',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildFilterButton(ReservationStatus.completed),
                  const SizedBox(width: 8),
                  _buildFilterButton(ReservationStatus.pendingConfirmation),
                  const SizedBox(width: 8),
                  _buildFilterButton(ReservationStatus.confirmed),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoadingReservations
                    ? const Center(child: CircularProgressIndicator())
                    : ValueListenableBuilder<List<ClientReservation>>(
                  valueListenable: ReservationRepository.instance.reservations,
                  builder: (context, reservations, _) {
                    final List<ClientReservation> filtered =
                        _applyFilter(reservations);

                    if (filtered.isEmpty) {
                      final String emptyMessage = _emptyMessage(reservations);
                      final bool showActionButton =
                          _showEmptyActionButton(reservations);

                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              emptyMessage,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (showActionButton) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _goToExplore,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Reserva ahora'),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ClientReservation reservation = filtered[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      reservation.routeName,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade900,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: reservation.status == ReservationStatus.rejected
                                          ? Colors.red.shade50
                                          : Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _reservationStatusLabel(reservation.status),
                                      style: TextStyle(
                                        color: reservation.status == ReservationStatus.rejected
                                            ? Colors.red.shade700
                                            : Colors.green.shade800,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Fecha: ${_formatDate(reservation.date)}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Hora: ${reservation.reservationTime}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Personas: ${reservation.people}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Total: ${reservation.total.toStringAsFixed(2)}€',
                                style: TextStyle(
                                  color: Colors.grey.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Alquiler: ${_equipmentSummary(reservation)}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_reservationDetailsText(reservation) != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Detalles: ${_reservationDetailsText(reservation)}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              if (reservation.status == ReservationStatus.rejected)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _showRejectionReason(reservation),
                                      icon: const Icon(Icons.info_outline),
                                      label: const Text('Razón de rechazo'),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _startChatWithWorkerForReservation(reservation),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade700,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.chat_bubble_outline),
                                      label: const Text('Hablar con trabajador'),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton.icon(
                                      onPressed:
                                          reservation.status ==
                                                  ReservationStatus.pendingConfirmation
                                              ? () => _openEditReservationDialog(reservation)
                                              : null,
                                      icon: const Icon(Icons.edit_outlined),
                                      label: const Text('Editar'),
                                    ),
                                    if (reservation.status == ReservationStatus.pendingConfirmation)
                                      ElevatedButton.icon(
                                        onPressed: () => _confirmCancelReservation(reservation),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade700,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        icon: const Icon(Icons.cancel_outlined, size: 18),
                                        label: const Text('Cancelar'),
                                      )
                                    else
                                      const SizedBox.shrink(),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
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
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Reservas'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explorar'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(ReservationStatus status) {
    final bool isActive = _activeFilter == status;

    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _activeFilter = status;
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive ? Colors.green.shade700 : Colors.white,
          foregroundColor: isActive ? Colors.white : Colors.grey.shade800,
          side: BorderSide(
            color: isActive ? Colors.green.shade700 : Colors.grey.shade300,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Text(
          _filterLabel(status),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}