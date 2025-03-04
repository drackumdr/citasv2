import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:citas_v2/theme/app_theme.dart';
import 'package:citas_v2/screens/appointment_detail_screen.dart';
import 'package:citas_v2/screens/doctors_list_screen.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen>
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
            Tab(text: 'Pasadas'),
            Tab(text: 'Canceladas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentList('upcoming'),
          _buildAppointmentList('past'),
          _buildAppointmentList('cancelada'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DoctorsListScreen()),
          );
        },
        label: const Text('Agendar cita'),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildAppointmentList(String filter) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('No has iniciado sesión'));
    }

    Query query = FirebaseFirestore.instance.collection('citas');

    // First, we need to get the patient's ID using their email
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
              child: Text('No se encontró información del paciente'));
        }

        final patientId = userSnapshot.data!.docs[0].id;

        // Now query appointments for this patient
        query = query.where('pacienteId', isEqualTo: patientId);

        switch (filter) {
          case 'upcoming':
            query = query
                .where('fecha', isGreaterThanOrEqualTo: Timestamp.now())
                .where('estado', isNotEqualTo: 'cancelada')
                .orderBy('fecha', descending: false);
            break;
          case 'past':
            query = query
                .where('fecha', isLessThan: Timestamp.now())
                .where('estado', isNotEqualTo: 'cancelada')
                .orderBy('fecha', descending: true);
            break;
          case 'cancelada':
            query = query
                .where('estado', isEqualTo: 'cancelada')
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
              print('Error: ${snapshot.error}');
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return _buildEmptyState(filter);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final appointment = docs[index].data() as Map<String, dynamic>;
                final appointmentId = docs[index].id;

                return _buildAppointmentCard(appointmentId, appointment);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String filter) {
    String message = '';
    String buttonText = '';

    switch (filter) {
      case 'upcoming':
        message = 'No tienes citas próximas';
        buttonText = 'Agendar una cita';
        break;
      case 'past':
        message = 'No tienes citas pasadas';
        buttonText = 'Ver médicos disponibles';
        break;
      case 'cancelada':
        message = 'No tienes citas canceladas';
        buttonText = 'Ver médicos disponibles';
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_month,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DoctorsListScreen()),
              );
            },
            icon: const Icon(Icons.search),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(
      String appointmentId, Map<String, dynamic> appointment) {
    final dateTime = (appointment['fecha'] as Timestamp).toDate();
    final date = DateFormat('EEEE d MMM, yyyy', 'es').format(dateTime);
    final time = DateFormat('HH:mm').format(dateTime);

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

    bool isPast = dateTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentDetailScreen(
                appointmentId: appointmentId,
                isDoctor: false,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: statusColor.withAlpha((0.2 * 255).toInt()),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    statusText.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    date,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            AppTheme.doctorColor.withAlpha((0.2 * 255).toInt()),
                        child: Icon(
                          Icons.medical_services,
                          color: AppTheme.doctorColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. ${appointment['doctorNombre'] ?? 'Médico'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (appointment['especialidad'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                appointment['especialidad'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha((0.1 * 255).toInt()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          time,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (appointment['motivo'] != null &&
                      appointment['motivo'].toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Motivo de la cita:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment['motivo'],
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Action buttons
                  if (!isPast &&
                      statusText != 'cancelada' &&
                      statusText != 'completada')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _cancelAppointment(appointmentId),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Cancelar cita'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Cita'),
        content: const Text('¿Estás seguro que deseas cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, mantener cita'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('citas')
          .doc(appointmentId)
          .update({
        'estado': 'cancelada',
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'canceladoPor': 'paciente',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita cancelada exitosamente'),
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
    }
  }
}
