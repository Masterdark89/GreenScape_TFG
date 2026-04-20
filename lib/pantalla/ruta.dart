import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/route_equipment_repository.dart';
import '../data/reservation_repository.dart';
import 'chatCliente.dart';
import 'cliente1.dart';
import 'perfilC.dart';
import 'pago.dart';

class EquipmentPurchaseItem {
  const EquipmentPurchaseItem({
    required this.name,
    required this.price,
  });

  final String name;
  final double price;
}

class RouteDetailData {
  const RouteDetailData({
    required this.name,
    required this.difficulty,
    required this.distance,
    required this.duration,
    required this.elevation,
    required this.description,
    required this.weatherInfo,
    required this.imagePath,
    required this.mapPath,
    required this.pricePerPerson,
    required this.maxPeople,
    required this.requiredEquipment,
    required this.purchasableEquipment,
  });

  final String name;
  final String difficulty;
  final String distance;
  final String duration;
  final String elevation;
  final String description;
  final String weatherInfo;
  final String imagePath;
  final String mapPath;
  final double pricePerPerson;
  final int maxPeople;
  final List<String> requiredEquipment;
  final List<EquipmentPurchaseItem> purchasableEquipment;
}

const Map<String, RouteDetailData> _routeCatalog = {
  'Refugio del Reloj': RouteDetailData(
    name: 'Refugio del Reloj',
    difficulty: 'Moderada',
    distance: '8.76 km',
    duration: '5 h 52 m',
    elevation: '479 m',
    description:
        'Ruta clásica desde Villaluenga del Rosario. El recorrido asciende por senderos de montaña con vistas a la Sierra de Grazalema hasta llegar al Refugio del Reloj. El regreso se realiza por el mismo trazado.',
    weatherInfo:
        'Consulta previsión de viento y lluvia antes de salir. En tramos altos la temperatura baja rápido al atardecer.',
    imagePath: 'assets/images/refugio.jpg',
    mapPath: 'assets/images/mapa_refugio.jpg',
    pricePerPerson: 17.50,
    maxPeople: 8,
    requiredEquipment: [
      'Botas de senderismo',
      '2L de agua',
      'Cortavientos',
      'Frontal o linterna',
      'Manta térmica',
      'Comida energética',
    ],
    purchasableEquipment: [
      EquipmentPurchaseItem(name: 'Bastones de trekking', price: 9.0),
      EquipmentPurchaseItem(name: 'Chubasquero impermeable', price: 11.0),
      EquipmentPurchaseItem(name: 'Frontal LED', price: 7.5),
    ],
  ),
  'Reloj y Simancón': RouteDetailData(
    name: 'Reloj y Simancón',
    difficulty: 'Difícil',
    distance: '12.56 km',
    duration: '7 h',
    elevation: '762 m',
    description:
        'Ruta exigente de alta montaña con paso por zonas rocosas y desnivel continuo. Requiere buena forma física y experiencia previa en senderos técnicos.',
    weatherInfo:
        'En días de niebla o viento fuerte se recomienda aplazar la salida por pérdida de visibilidad en crestas.',
    imagePath: 'assets/images/simancon.jpg',
    mapPath: 'assets/images/simancon_reloj_mapa.jpg',
    pricePerPerson: 21.00,
    maxPeople: 6,
    requiredEquipment: [
      'Botas de caña alta',
      '3L de agua',
      'Ropa térmica',
      'Bastones',
      'Guantes de montaña',
      'Gafas de protección UV',
      'Protección solar alta',
    ],
    purchasableEquipment: [
      EquipmentPurchaseItem(name: 'Guantes térmicos', price: 8.0),
      EquipmentPurchaseItem(name: 'Polainas', price: 7.0),
      EquipmentPurchaseItem(name: 'Poncho técnico', price: 12.0),
    ],
  ),
  'Charca Verde': RouteDetailData(
    name: 'Charca Verde',
    difficulty: 'Fácil',
    distance: '11.9 km',
    duration: '7 h',
    elevation: '669 m',
    description:
        'Recorrido de baja dificultad técnica por senderos amplios y zonas de bosque. Ideal para grupos que buscan una jornada tranquila en naturaleza.',
    weatherInfo:
        'Ruta recomendable en primavera y otoño. Lleva protección solar en días despejados.',
    imagePath: 'assets/images/charca.jpg',
    mapPath: 'assets/images/mapa_charca.jpg',
    pricePerPerson: 14.00,
    maxPeople: 10,
    requiredEquipment: [
      'Calzado cómodo',
      '1.5L de agua',
      'Gorra',
      'Protector solar',
      'Mochila ligera',
      'Snacks',
    ],
    purchasableEquipment: [
      EquipmentPurchaseItem(name: 'Cantimplora 1L', price: 5.0),
      EquipmentPurchaseItem(name: 'Gorra transpirable', price: 6.0),
      EquipmentPurchaseItem(name: 'Crema solar SPF50', price: 4.5),
    ],
  ),
  'Cueva del Gato': RouteDetailData(
    name: 'Cueva del Gato',
    difficulty: 'Moderada',
    distance: '7,3 km',
    duration: '3 h 52 m',
    elevation: '238 m',
    description:
        'La ruta atraviesa dos atractivos núcleos de población y visita dos enclaves de singular belleza (más aún en épocas lluviosas), como son el Nacimiento de Benaoján o de Los Cascajales y la Cueva del Gato. La vegetación del recorrido está representada por especies mediterráneas y de ribera, olivares, prados, huertas y tierras de labor. Se desarrolla en el extremo oriental del Parque Natural de la Sierra de Grazalema, en el término municipal de Benaoján (Málaga).',
    weatherInfo:
        'Precaución tras lluvias: algunos tramos pueden estar resbaladizos por humedad.',
    imagePath: 'assets/images/cueva_gato.jpg',
    mapPath: 'assets/images/mapa_gato.jpg',
    pricePerPerson: 15.50,
    maxPeople: 9,
    requiredEquipment: [
      'Calzado con buen agarre',
      '1.5L de agua',
      'Toalla pequeña',
      'Chaqueta ligera',
      'Ropa de recambio',
      'Bolsa estanca',
    ],
    purchasableEquipment: [
      EquipmentPurchaseItem(name: 'Escarpines', price: 6.5),
      EquipmentPurchaseItem(name: 'Bolsa estanca 5L', price: 5.5),
      EquipmentPurchaseItem(name: 'Toalla microfibra', price: 4.0),
    ],
  ),
  'Pico Mulhacén': RouteDetailData(
    name: 'Pico Mulhacén',
    difficulty: 'Moderada',
    distance: '10,42 km',
    duration: '5 h 32 m',
    elevation: '760 m',
    description:
        'Espectacular ruta, entre el Alto del Chorrillo, el Mulhacén II y el Pico Mulhacén. Nos movemos dentro del Parque Nacional de Sierra Nevada, entrando por la Alpujarra granadina (Capileira).',
    weatherInfo:
        'A gran altitud el tiempo cambia rápido. Lleva capa extra y revisa previsión por horas.',
    imagePath: 'assets/images/mulhacen.jpg',
    mapPath: 'assets/images/mapa_mulhacen.jpg',
    pricePerPerson: 19.00,
    maxPeople: 7,
    requiredEquipment: [
      'Botas de montaña',
      '2.5L de agua',
      'Capa térmica',
      'Gafas de sol',
      'Cortavientos',
      'Guantes',
      'Gorro térmico',
    ],
    purchasableEquipment: [
      EquipmentPurchaseItem(name: 'Forro polar', price: 14.0),
      EquipmentPurchaseItem(name: 'Gorro térmico', price: 6.0),
      EquipmentPurchaseItem(name: 'Mochila 20L', price: 15.0),
    ],
  ),
};

RouteDetailData buildRouteDetailFromRoute(Map<String, dynamic> route) {
  final String name = route['name']?.toString() ?? 'Ruta';
  return _routeCatalog[name] ??
      RouteDetailData(
        name: name,
        difficulty: route['difficulty']?.toString() ?? 'Moderada',
        distance: route['distance']?.toString() ?? '-',
        duration: route['duration']?.toString() ?? '-',
        elevation: route['elevation']?.toString() ?? '-',
        description:
            'Información detallada de la ruta disponible próximamente.',
        weatherInfo:
            'Consulta la previsión meteorológica local antes de iniciar la actividad.',
        imagePath: route['imagePath']?.toString() ?? '',
        mapPath: route['mapPath']?.toString() ?? '',
        pricePerPerson: 17.50,
        maxPeople: 8,
        requiredEquipment: const [
          'Botas de senderismo',
          'Agua',
          'Ropa adecuada',
        ],
        purchasableEquipment: const [
          EquipmentPurchaseItem(name: 'Cantimplora', price: 5.0),
          EquipmentPurchaseItem(name: 'Gorra', price: 6.0),
        ],
      );
}

class RouteDetailScreen extends StatefulWidget {
  const RouteDetailScreen({
    super.key,
    required this.detail,
  });

  final RouteDetailData detail;

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
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

  final int _selectedIndex = 1;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String? _selectedReservationTime;
  int _peopleCount = 2;
  bool _isBooking = false;
  bool _isReserveCooldown = false;
  final TextEditingController _reservationDetailsController = TextEditingController();
  late List<Map<String, dynamic>> _purchaseEquipmentList;
  late List<String> _requiredEquipmentList;
  final RouteEquipmentRepository _routeEquipmentRepository =
      RouteEquipmentRepository.instance;

  static const double _seaLevelAverageTemp = 22.0;
  static const double _tempDropPerMeter = 0.0065;
  static const int _minimumAdvanceDays = 7;

  @override
  void initState() {
    super.initState();
    _selectedDate = _minimumBookingDate;
    _selectedReservationTime = null;
    _requiredEquipmentList = List<String>.from(widget.detail.requiredEquipment);
    _purchaseEquipmentList = widget.detail.purchasableEquipment
      .map((item) => {'name': item.name, 'price': item.price, 'quantity': 0})
        .toList();
    _loadRequiredEquipment();
    _loadRentableEquipment();
  }

  @override
  void dispose() {
    _reservationDetailsController.dispose();
    super.dispose();
  }

  Future<void> _loadRequiredEquipment() async {
    final equipment = await _routeEquipmentRepository.getRequiredEquipment(
      routeName: widget.detail.name,
      fallback: widget.detail.requiredEquipment,
    );

    if (!mounted) return;
    setState(() {
      _requiredEquipmentList = equipment;
    });
  }

  Future<void> _loadRentableEquipment() async {
    final fallback = widget.detail.purchasableEquipment
        .map(
          (item) => RouteRentalEquipment(name: item.name, price: item.price),
        )
        .toList();

    final rentable = await _routeEquipmentRepository.getRentableEquipment(
      routeName: widget.detail.name,
      fallback: fallback,
    );

    if (!mounted) return;
    setState(() {
      _purchaseEquipmentList = rentable
          .map(
            (item) => <String, dynamic>{
              'name': item.name,
              'price': item.price,
              'quantity': 0,
            },
          )
          .toList();
    });
  }

  DateTime get _minimumBookingDate {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(
      const Duration(days: _minimumAdvanceDays),
    );
  }

  double get _selectedEquipmentTotal {
    return _purchaseEquipmentList
        .fold<double>(0, (sum, item) {
      return sum + ((item['price'] as double) * (item['quantity'] as int));
    });
  }

  double get totalPrice =>
      (_peopleCount * widget.detail.pricePerPerson) + _selectedEquipmentTotal;

  double _extractElevationMeters(String elevationText) {
    final RegExp numberPattern = RegExp(r'[0-9]+([\.,][0-9]+)?');
    final Match? match = numberPattern.firstMatch(elevationText);
    if (match == null) {
      return 0;
    }
    final String numeric = match.group(0)!.replaceAll(',', '.');
    return double.tryParse(numeric) ?? 0;
  }

  String get _averageTemperatureAtElevation {
    final double elevationMeters = _extractElevationMeters(widget.detail.elevation);
    final double temp = _seaLevelAverageTemp - (elevationMeters * _tempDropPerMeter);
    return '${temp.clamp(0, 50).toStringAsFixed(1)}°C';
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<Set<String>> _occupiedDateKeysForSelectedTime() async {
    if (_selectedReservationTime == null || _selectedReservationTime!.isEmpty) {
      return <String>{};
    }

    return ReservationRepository.instance.getConfirmedReservationDateKeysForRouteAndTime(
      routeName: widget.detail.name,
      reservationTime: _selectedReservationTime!,
    );
  }

  Future<DateTime?> _firstAvailableDateAfter(DateTime startDate) async {
    final occupiedDateKeys = await _occupiedDateKeysForSelectedTime();
    final DateTime maxDate = DateTime.now().add(const Duration(days: 365));

    for (DateTime date = startDate; !date.isAfter(maxDate); date = date.add(const Duration(days: 1))) {
      if (!occupiedDateKeys.contains(_dateKey(date))) {
        return date;
      }
    }

    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime minDate = _minimumBookingDate;
    if (_selectedReservationTime == null || _selectedReservationTime!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero debes seleccionar la hora.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final occupiedDateKeys = await _occupiedDateKeysForSelectedTime();
    final bool currentDateIsBlocked = occupiedDateKeys.contains(_dateKey(_selectedDate));
    final DateTime? initialDate = currentDateIsBlocked
        ? await _firstAvailableDateAfter(minDate)
        : (_selectedDate.isBefore(minDate) ? minDate : _selectedDate);

    if (initialDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya reservado'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
      helpText: 'Selecciona una fecha disponible',
      selectableDayPredicate: (day) => !occupiedDateKeys.contains(_dateKey(day)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _incrementPeople() {
    if (_peopleCount >= widget.detail.maxPeople) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Máximo ${widget.detail.maxPeople} personas para esta ruta.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _peopleCount++;
    });
  }

  void _decrementPeople() {
    if (_peopleCount > 1) {
      setState(() {
        _peopleCount--;
        _clampEquipmentQuantities();
      });
    }
  }

  void _clampEquipmentQuantities() {
    for (final item in _purchaseEquipmentList) {
      final int quantity = item['quantity'] as int;
      if (quantity > _peopleCount) {
        item['quantity'] = _peopleCount;
      }
      if (quantity < 0) {
        item['quantity'] = 0;
      }
    }
  }

  void _incrementEquipment(int index) {
    final int currentQuantity = _purchaseEquipmentList[index]['quantity'] as int;
    if (currentQuantity < _peopleCount) {
      setState(() {
        _purchaseEquipmentList[index]['quantity'] = currentQuantity + 1;
      });
    }
  }

  void _decrementEquipment(int index) {
    final int currentQuantity = _purchaseEquipmentList[index]['quantity'] as int;
    if (currentQuantity > 0) {
      setState(() {
        _purchaseEquipmentList[index]['quantity'] = currentQuantity - 1;
      });
    }
  }

  Future<void> _startReserveCooldown() async {
    if (!mounted) return;

    setState(() {
      _isReserveCooldown = true;
    });

    await Future.delayed(const Duration(seconds: 5));

    if (!mounted) return;
    setState(() {
      _isReserveCooldown = false;
    });
  }

  Future<void> _bookRoute() async {
    if (_isBooking || _isReserveCooldown) {
      return;
    }

    setState(() {
      _isBooking = true;
    });

    if (_selectedDate.isBefore(_minimumBookingDate)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La reserva debe hacerse con al menos 7 días de antelación.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
      return;
    }

    if (_selectedReservationTime == null || _selectedReservationTime!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes seleccionar una hora para la reserva.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
      return;
    }

    try {
      final Map<String, int> equipmentQuantities = {
        for (final item in _purchaseEquipmentList)
          if ((item['quantity'] as int) > 0)
            item['name'] as String: item['quantity'] as int,
      };

      await ReservationRepository.instance.addReservation(
        ClientReservation(
          routeName: widget.detail.name,
          date: _selectedDate,
          createdAt: DateTime.now(),
          reservationTime: _selectedReservationTime!,
          people: _peopleCount,
          total: totalPrice,
          status: ReservationStatus.pendingConfirmation,
          equipmentQuantities: equipmentQuantities,
          reservationDetails: _reservationDetailsController.text.trim().isEmpty
              ? null
              : _reservationDetailsController.text.trim(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is StateError
                ? e.message
                : 'No se pudo guardar la reserva. Inicia sesión e inténtalo de nuevo.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Reserva realizada con exito!'),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isBooking = false;
      });
    }
    await _startReserveCooldown();
  }

  void _showFullScreenMap() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.asset(
                    widget.detail.mapPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Center(
                      child: Text(
                        'Mapa no disponible',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: Colors.white,
                    tooltip: 'Cerrar mapa',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ClientProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(248, 250, 245, 1),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GreenScape',
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        Text(
                          widget.detail.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _averageTemperatureAtElevation,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _showFullScreenMap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Image.asset(
                        widget.detail.imagePath,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 44,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.fullscreen, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.detail.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('Distancia', widget.detail.distance),
                  _buildStatItem('Desnivel', widget.detail.elevation),
                  _buildStatItem('Duración', widget.detail.duration),
                  _buildStatItem('Dificultad', widget.detail.difficulty),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wb_sunny, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.detail.weatherInfo,
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Lista de equipo obligatorio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              ..._requiredEquipmentList.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reserve su ruta',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Hora de salida:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                hint: const Text('Seleccionar hora'),
                                value: _selectedReservationTime,
                                items: _availableReservationTimes
                                    .map(
                                      (time) => DropdownMenuItem<String>(
                                        value: time,
                                        child: Text(time),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) async {
                                  if (value == null) return;
                                  setState(() {
                                    _selectedReservationTime = value;
                                  });

                                  final occupiedDateKeys = await ReservationRepository.instance
                                      .getConfirmedReservationDateKeysForRouteAndTime(
                                    routeName: widget.detail.name,
                                    reservationTime: value,
                                  );
                                  if (!mounted) return;
                                  if (occupiedDateKeys.contains(_dateKey(_selectedDate))) {
                                    final DateTime? nextAvailable = await _firstAvailableDateAfter(
                                      _minimumBookingDate,
                                    );
                                    if (!mounted) return;
                                    setState(() {
                                      if (nextAvailable != null) {
                                        _selectedDate = nextAvailable;
                                      }
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Ya reservado'),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Día de salida:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${_selectedDate.day} / ${_selectedDate.month} / ${_selectedDate.year}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.calendar_today, size: 16),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _reservationDetailsController,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        labelText: 'Detalles de la reserva',
                        hintText: 'Añade observaciones para el trabajador',
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Las reservas requieren al menos $_minimumAdvanceDays días de antelación.',
                              style: TextStyle(color: Colors.orange.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Número de personas:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _decrementPeople,
                              icon: const Icon(Icons.remove_circle_outline),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                '$_peopleCount',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                            ),
                            IconButton(
                              onPressed: _incrementPeople,
                              icon: const Icon(Icons.add_circle_outline),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Alquiler de equipamiento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_purchaseEquipmentList.length, (index) {
                      final item = _purchaseEquipmentList[index];
                      final int quantity = item['quantity'] as int;
                      final double price = item['price'] as double;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${price.toStringAsFixed(2)}€ por unidad',
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: quantity == 0 ? null : () => _decrementEquipment(index),
                                  icon: const Icon(Icons.remove_circle_outline),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                                Container(
                                  width: 30,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$quantity',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                IconButton(
                                  onPressed: quantity >= _peopleCount ? null : () => _incrementEquipment(index),
                                  icon: const Icon(Icons.add_circle_outline),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
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
                        Text(
                          'Precio por persona: ${widget.detail.pricePerPerson.toStringAsFixed(2)}€',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Alquiler seleccionado:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${_selectedEquipmentTotal.toStringAsFixed(2)}€',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${totalPrice.toStringAsFixed(2)}€',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isBooking || _isReserveCooldown) ? null : _bookRoute,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _isReserveCooldown
                              ? 'Espere 5 segundos...'
                              : (_isBooking ? 'Reservando...' : 'Reservar ahora'),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'El pago se efectuará el dia de la ruta en persona.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}