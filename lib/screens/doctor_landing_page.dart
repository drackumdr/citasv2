import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:citas_v2/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorLandingPage extends StatefulWidget {
  final String doctorId;

  const DoctorLandingPage({super.key, required this.doctorId});

  @override
  State<DoctorLandingPage> createState() => _DoctorLandingPageState();
}

class _DoctorLandingPageState extends State<DoctorLandingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _doctorData;
  String _selectedDay = 'lunes'; // Default selected day
  List<String> _daysOfWeek = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo'
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final docSnapshot =
          await _firestore.collection('usuarios').doc(widget.doctorId).get();

      if (docSnapshot.exists) {
        setState(() {
          _doctorData = docSnapshot.data();
          _isLoading = false;
        });
      } else {
        // Handle doctor not found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Médico no encontrado')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTimeRange(Map<String, dynamic> timeRange) {
    final format = DateFormat('HH:mm');
    final now = DateTime.now();
    final startDt = DateTime(now.year, now.month, now.day,
        timeRange['startHour'], timeRange['startMinute']);
    final endDt = DateTime(now.year, now.month, now.day, timeRange['endHour'],
        timeRange['endMinute']);
    return '${format.format(startDt)} - ${format.format(endDt)}';
  }

  void _showAppointmentBooking() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildAppointmentBookingSheet(),
    );
  }

  Widget _buildAppointmentBookingSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return AppointmentBookingWidget(
          doctorId: widget.doctorId,
          doctorName: _doctorData?['nombre'] ?? 'Médico',
          horario: _doctorData?['horario'] ?? {},
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Doctor information
                        _buildDoctorInfo(),
                        const SizedBox(height: 20),

                        // Availability section
                        _buildAvailabilitySection(),
                        const SizedBox(height: 20),

                        // Gallery section
                        if (_doctorData?['galleryImages'] != null &&
                            (_doctorData?['galleryImages'] as List).isNotEmpty)
                          _buildGallerySection(),
                        const SizedBox(height: 24),

                        // Schedule appointment button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _showAppointmentBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Agendar Cita',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _doctorData?['nombre'] ?? 'Médico',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image with gradient overlay
            _doctorData?['imageUrl'] != null
                ? Image.network(
                    _doctorData!['imageUrl'],
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    'assets/images/doctor_default.jpg',
                    fit: BoxFit.cover,
                  ),
            // Gradient for better text visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.medical_services, color: AppTheme.doctorColor, size: 24),
            const SizedBox(width: 8),
            Text(
              _doctorData?['especialidad'] ?? 'Especialidad no disponible',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // About section
        const Text(
          'Acerca del Médico',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _doctorData?['descripcion'] ??
              'No hay información disponible sobre este médico.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),

        // Contact information
        if (_doctorData?['telefono'] != null)
          ListTile(
            leading: Icon(Icons.phone, color: AppTheme.primaryColor),
            title: const Text('Teléfono'),
            subtitle: Text(_doctorData?['telefono']),
            contentPadding: EdgeInsets.zero,
          ),

        if (_doctorData?['email'] != null)
          ListTile(
            leading: Icon(Icons.email, color: AppTheme.primaryColor),
            title: const Text('Email'),
            subtitle: Text(_doctorData?['email']),
            contentPadding: EdgeInsets.zero,
          ),

        if (_doctorData?['direccion'] != null)
          ListTile(
            leading: Icon(Icons.location_on, color: AppTheme.primaryColor),
            title: const Text('Dirección'),
            subtitle: Text(_doctorData?['direccion']),
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    final horario = _doctorData?['horario'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Horario de Atención',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Days of week selector
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _daysOfWeek.length,
            itemBuilder: (context, index) {
              final day = _daysOfWeek[index];
              final isSelected = day == _selectedDay;
              final hasSlots =
                  horario[day] != null && (horario[day] as List).isNotEmpty;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(day.substring(0, 3).toUpperCase()),
                  selected: isSelected,
                  selectedColor: hasSlots ? AppTheme.primaryColor : Colors.grey,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black54,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: hasSlots
                      ? (selected) {
                          if (selected) {
                            setState(() {
                              _selectedDay = day;
                            });
                          }
                        }
                      : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Time slots for selected day
        if (horario[_selectedDay] != null &&
            (horario[_selectedDay] as List).isNotEmpty)
          Column(
            children: (horario[_selectedDay] as List)
                .map<Widget>((slot) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.access_time,
                                color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimeRange(slot),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  const Text('No hay horarios disponibles para este día'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGallerySection() {
    final galleryImages =
        List<String>.from(_doctorData?['galleryImages'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Galería',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: galleryImages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: () {
                    // Show full-screen image view
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FullScreenImage(imageUrl: galleryImages[index]),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      galleryImages[index],
                      width: 160,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Full screen image viewer
class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}

// Widget to book appointments
class AppointmentBookingWidget extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final Map<String, dynamic> horario;

  const AppointmentBookingWidget({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.horario,
  });

  @override
  State<AppointmentBookingWidget> createState() =>
      _AppointmentBookingWidgetState();
}

class _AppointmentBookingWidgetState extends State<AppointmentBookingWidget> {
  final TextEditingController _reasonController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedDay;
  Map<String, dynamic>? _selectedTimeSlot;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isBooking = false;

  List<String> _spanishDays = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo'
  ];

  List<String> _englishDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;

        // Get the day of week in English
        String englishDay = DateFormat('EEEE').format(picked);

        // Convert English day name to Spanish
        int index = _englishDays.indexOf(englishDay);
        if (index != -1) {
          _selectedDay = _spanishDays[index];
        }

        // Reset time slot when date changes
        _selectedTimeSlot = null;
      });
    }
  }

  String _formatTimeRange(Map<String, dynamic> timeRange) {
    final format = DateFormat('HH:mm');
    final now = DateTime.now();
    final startDt = DateTime(now.year, now.month, now.day,
        timeRange['startHour'], timeRange['startMinute']);
    final endDt = DateTime(now.year, now.month, now.day, timeRange['endHour'],
        timeRange['endMinute']);
    return '${format.format(startDt)} - ${format.format(endDt)}';
  }

  Future<void> _bookAppointment() async {
    if (_selectedDate == null ||
        _selectedTimeSlot == null ||
        _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Get patient information
      final patientDoc = await _firestore
          .collection('usuarios')
          .where('email', isEqualTo: user.email)
          .get();

      if (patientDoc.docs.isEmpty) {
        throw Exception('Información del paciente no encontrada');
      }

      final patientData = patientDoc.docs.first.data();

      // Create appointment date with time from selected time slot
      final appointmentDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTimeSlot!['startHour'],
        _selectedTimeSlot!['startMinute'],
      );

      // Create appointment end time
      final appointmentEndTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTimeSlot!['endHour'],
        _selectedTimeSlot!['endMinute'],
      );

      // Check for existing appointments
      final existingAppointments = await _firestore
          .collection('citas')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('fecha', isEqualTo: Timestamp.fromDate(appointmentDate))
          .get();

      if (existingAppointments.docs.isNotEmpty) {
        throw Exception('Ya existe una cita en este horario');
      }

      // Create appointment
      await _firestore.collection('citas').add({
        'doctorId': widget.doctorId,
        'doctorNombre': widget.doctorName,
        'pacienteId': patientDoc.docs.first.id,
        'pacienteNombre': patientData['nombre'],
        'pacienteEmail': user.email,
        'fecha': Timestamp.fromDate(appointmentDate),
        'fechaFin': Timestamp.fromDate(appointmentEndTime),
        'motivo': _reasonController.text.trim(),
        'estado': 'pendiente',
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita agendada correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Close the bottom sheet
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isBooking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
        top: 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Agendar Cita',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Doctor name
          Text(
            'Doctor: ${widget.doctorName}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // Date selector
          ListTile(
            title: const Text('Fecha de la cita'),
            subtitle: Text(
              _selectedDate != null
                  ? DateFormat('EEEE, d MMMM yyyy', 'es').format(_selectedDate!)
                  : 'Selecciona una fecha',
            ),
            leading: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
            onTap: () => _selectDate(context),
            tileColor: Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),

          // Time slot selection
          if (_selectedDate != null && _selectedDay != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Horarios disponibles:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (widget.horario[_selectedDay] != null &&
                    (widget.horario[_selectedDay] as List).isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: (widget.horario[_selectedDay] as List).length,
                      itemBuilder: (context, index) {
                        final timeSlot =
                            (widget.horario[_selectedDay] as List)[index];
                        final isSelected = _selectedTimeSlot == timeSlot;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(_formatTimeRange(timeSlot)),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryColor,
                            backgroundColor: Colors.grey[200],
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _selectedTimeSlot = selected ? timeSlot : null;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  )
                else
                  const Text(
                    'No hay horarios disponibles para este día',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),

          const SizedBox(height: 16),

          // Reason for appointment
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Motivo de la cita',
              hintText: 'Describa brevemente el motivo de su consulta',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Book appointment button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isBooking ? null : _bookAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                disabledBackgroundColor: Colors.grey,
              ),
              child: _isBooking
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Confirmar Cita',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
