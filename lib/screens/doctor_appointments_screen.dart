import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:citas_v2/theme/app_theme.dart';
import 'package:citas_v2/screens/appointment_detail_screen.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Próximas'),
            Tab(text: 'Pendientes'),
            Tab(text: 'Completadas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentList('upcoming'),
          _buildAppointmentList('pendiente'),
          _buildAppointmentList('completada'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateAppointmentDialog();
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppointmentList(String filter) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('No has iniciado sesión'));
    }

    Query query = FirebaseFirestore.instance.collection('citas');

    // First, we need to get the doctor's ID using their email
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (userSnapshot.hasError ||
            !userSnapshot.hasData ||
            userSnapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('No se encontró información del médico'));
        }

        final doctorId = userSnapshot.data!.docs[0].id;

        // Now query appointments for this doctor
        query = query.where('doctorId', isEqualTo: doctorId);

        switch (filter) {
          case 'upcoming':
            query = query
                .where('fecha', isGreaterThanOrEqualTo: Timestamp.now())
                .orderBy('fecha', descending: false);
            break;
          case 'pendiente':
            query = query
                .where('estado', isEqualTo: 'pendiente')
                .orderBy('fecha', descending: false);
            break;
          case 'completada':
            query = query
                .where('estado', isEqualTo: 'completada')
                .orderBy('fecha', descending: true);
            break;
          default:
            query = query.orderBy('fecha', descending: false);
        }

        return StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      filter == 'upcoming'
                          ? 'No tienes citas próximas'
                          : filter == 'pendiente'
                              ? 'No tienes citas pendientes'
                              : 'No tienes citas completadas',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final appointment = docs[index].data() as Map<String, dynamic>;
                final appointmentId = docs[index].id;

                return AppointmentCard(
                  appointmentId: appointmentId,
                  appointment: appointment,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentDetailScreen(
                          appointmentId: appointmentId,
                          isDoctor: true,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCreateAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateAppointmentDialog(),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final String appointmentId;
  final Map<String, dynamic> appointment;
  final VoidCallback onTap;

  const AppointmentCard({
    super.key,
    required this.appointmentId,
    required this.appointment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateTime = (appointment['fecha'] as Timestamp).toDate();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    final date = dateFormat.format(dateTime);
    final time = timeFormat.format(dateTime);

    Color statusColor;
    IconData statusIcon;
    String statusText = appointment['estado'] ?? 'pendiente';

    switch (statusText) {
      case 'completada':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelada':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'pendiente':
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor:
                        AppTheme.primaryColor.withAlpha((0.1 * 255).toInt()),
                    child: Icon(
                      Icons.person,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment['pacienteNombre'] ?? 'Paciente',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appointment['pacienteEmail'] ?? 'No email',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      statusText.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: statusColor,
                    avatar: Icon(
                      statusIcon,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoItem(
                    Icons.calendar_today,
                    'Fecha',
                    date,
                    AppTheme.primaryColor,
                  ),
                  _infoItem(
                    Icons.access_time,
                    'Hora',
                    time,
                    Colors.blue,
                  ),
                ],
              ),
              if (appointment['motivo'] != null &&
                  appointment['motivo'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Motivo:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  appointment['motivo'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class CreateAppointmentDialog extends StatefulWidget {
  const CreateAppointmentDialog({super.key});

  @override
  State<CreateAppointmentDialog> createState() =>
      _CreateAppointmentDialogState();
}

class _CreateAppointmentDialogState extends State<CreateAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _patientEmailController = TextEditingController();
  final _motiveController = TextEditingController();
  bool _isLoading = false;
  List<TimeOfDay> _availableTimeSlots = [];

  @override
  void dispose() {
    _patientEmailController.dispose();
    _motiveController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _generateAvailableTimeSlots();
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _generateAvailableTimeSlots() async {
    if (_selectedDate == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doctorQuerySnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (doctorQuerySnapshot.docs.isEmpty) return;

    final doctorDoc = doctorQuerySnapshot.docs.first;
    final doctorData = doctorDoc.data();
    final availability = doctorData['horario'] as Map<String, dynamic>?;
    final appointmentDuration = doctorData['appointmentDuration'] as int?;

    if (availability == null || appointmentDuration == null) return;

    final dayOfWeek =
        DateFormat('EEEE', 'es').format(_selectedDate!).toLowerCase();
    final timeRanges = availability[dayOfWeek] as List<dynamic>?;

    if (timeRanges == null || timeRanges.isEmpty) return;

    final List<TimeOfDay> availableSlots = [];

    for (var range in timeRanges) {
      final startHour = range['startHour'] as int;
      final startMinute = range['startMinute'] as int;
      final endHour = range['endHour'] as int;
      final endMinute = range['endMinute'] as int;

      DateTime startTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        startHour,
        startMinute,
      );

      DateTime endTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        endHour,
        endMinute,
      );

      while (startTime.isBefore(endTime)) {
        availableSlots.add(TimeOfDay.fromDateTime(startTime));
        startTime = startTime.add(Duration(minutes: appointmentDuration));
      }
    }

    setState(() {
      _availableTimeSlots = availableSlots;
    });
  }

  Future<void> _createAppointment() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedTime == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current doctor's info
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No has iniciado sesión');

      final doctorQuerySnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (doctorQuerySnapshot.docs.isEmpty) {
        throw Exception('No se encontró información del médico');
      }

      final doctorDoc = doctorQuerySnapshot.docs.first;
      final doctorId = doctorDoc.id;
      final doctorData = doctorDoc.data();

      // Find the patient using the email
      final patientQuerySnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: _patientEmailController.text.trim())
          .limit(1)
          .get();

      if (patientQuerySnapshot.docs.isEmpty) {
        throw Exception(
            'No se encontró ningún paciente con ese correo electrónico');
      }

      final patientDoc = patientQuerySnapshot.docs.first;
      final patientId = patientDoc.id;
      final patientData = patientDoc.data();

      // Create appointment date
      final appointmentDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Create appointment end time (assuming 30 min duration)
      final appointmentEndTime =
          appointmentDate.add(const Duration(minutes: 30));

      // Check for conflicts
      final conflictingAppointmentsQuery = await FirebaseFirestore.instance
          .collection('citas')
          .where('doctorId', isEqualTo: doctorId)
          .where('fecha', isEqualTo: Timestamp.fromDate(appointmentDate))
          .get();

      if (conflictingAppointmentsQuery.docs.isNotEmpty) {
        throw Exception('Ya existe una cita agendada para esta fecha y hora');
      }

      // Create new appointment
      await FirebaseFirestore.instance.collection('citas').add({
        'doctorId': doctorId,
        'doctorNombre': doctorData['nombre'] ?? user.displayName,
        'pacienteId': patientId,
        'pacienteNombre': patientData['nombre'] ?? 'Paciente',
        'pacienteEmail': _patientEmailController.text.trim(),
        'fecha': Timestamp.fromDate(appointmentDate),
        'fechaFin': Timestamp.fromDate(appointmentEndTime),
        'motivo': _motiveController.text.trim(),
        'estado': 'pendiente',
        'fechaCreacion': FieldValue.serverTimestamp(),
        'creadoPor': 'medico',
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita creada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear Nueva Cita'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _patientEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email del Paciente',
                  hintText: 'Ingrese el email del paciente',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el email del paciente';
                  }
                  if (!value.contains('@')) {
                    return 'Ingrese un email válido';
                  }
                  return null;
                },
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _selectedDate == null
                      ? 'Seleccionar fecha'
                      : 'Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                ),
                leading: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              ListTile(
                title: Text(
                  _selectedTime == null
                      ? 'Seleccionar hora'
                      : 'Hora: ${_selectedTime!.format(context)}',
                ),
                leading: const Icon(Icons.access_time),
                onTap: () => _selectTime(context),
              ),
              const SizedBox(height: 16),
              if (_availableTimeSlots.isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _availableTimeSlots.map((timeSlot) {
                    return ChoiceChip(
                      label: Text(timeSlot.format(context)),
                      selected: _selectedTime == timeSlot,
                      onSelected: (selected) {
                        setState(() {
                          _selectedTime = selected ? timeSlot : null;
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motiveController,
                decoration: const InputDecoration(
                  labelText: 'Motivo de la cita',
                  hintText: 'Describa brevemente el motivo',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createAppointment,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear Cita'),
        ),
      ],
    );
  }
}
