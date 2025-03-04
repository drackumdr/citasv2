import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:citas_v2/theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart'; // Add this import

class AppointmentDetailScreen extends StatefulWidget {
  final String appointmentId;
  final bool isDoctor;

  const AppointmentDetailScreen({
    super.key,
    required this.appointmentId,
    this.isDoctor = false,
  });

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize date formatting for Spanish locale
    initializeDateFormatting('es');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Cita'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('citas')
            .doc(widget.appointmentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No se encontró la cita'));
          }

          final appointment = snapshot.data!.data() as Map<String, dynamic>;

          // Check if the selected time slot is already booked
          if (appointment['estado'] == 'conflict') {
            return Center(
              child: Text(
                'El horario seleccionado ya está reservado. Por favor, elija otro horario.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppointmentStatusCard(appointment),
                const SizedBox(height: 16),
                _buildAppointmentDetailsCard(appointment),
                const SizedBox(height: 16),
                if (widget.isDoctor) _buildActionButtons(appointment),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppointmentStatusCard(Map<String, dynamic> appointment) {
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
                Text(
                  statusText.toUpperCase(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cita ${statusText == 'completada' ? 'realizada' : statusText == 'cancelada' ? 'cancelada' : 'agendada para'} el ${DateFormat('dd/MM/yyyy').format((appointment['fecha'] as Timestamp).toDate())}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentDetailsCard(Map<String, dynamic> appointment) {
    final dateTime = (appointment['fecha'] as Timestamp).toDate();
    final endTime = appointment['fechaFin'] != null
        ? (appointment['fechaFin'] as Timestamp).toDate()
        : dateTime.add(const Duration(
            minutes: 30)); // Default 30 minutes if end time not specified

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalles de la Cita',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailItem(
                'Paciente', appointment['pacienteNombre'] ?? 'No disponible'),
            _buildDetailItem('Email del Paciente',
                appointment['pacienteEmail'] ?? 'No disponible'),
            _buildDetailItem(
                'Médico', appointment['doctorNombre'] ?? 'No disponible'),
            _buildDetailItem(
              'Fecha y Hora',
              DateFormat('dd/MM/yyyy HH:mm').format(dateTime),
              icon: Icons.calendar_today,
            ),
            _buildDetailItem(
              'Duración',
              '${_calculateDuration(dateTime, endTime)} minutos',
              icon: Icons.timer,
            ),
            _buildDetailItem(
              'Motivo',
              appointment['motivo'] ?? 'No especificado',
              icon: Icons.description,
            ),
            if (appointment['notas'] != null &&
                appointment['notas'].toString().isNotEmpty)
              _buildDetailItem(
                'Notas del Doctor',
                appointment['notas'],
                icon: Icons.note,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> appointment) {
    final String status = appointment['estado'] ?? 'pendiente';
    final bool canUpdate = status == 'pendiente';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canUpdate) ...[
          ElevatedButton.icon(
            onPressed: _isLoading
                ? null
                : () => _updateAppointmentStatus('completada'),
            icon: const Icon(Icons.check_circle),
            label: const Text('Marcar como Completada'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed:
                _isLoading ? null : () => _updateAppointmentStatus('cancelada'),
            icon: const Icon(Icons.cancel),
            label: const Text('Cancelar Cita'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _addMedicalNotes,
            icon: const Icon(Icons.note_add),
            label: const Text('Agregar Notas'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
        if (!canUpdate) ...[
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _addMedicalNotes,
            icon: const Icon(Icons.note_add),
            label: const Text('Ver/Editar Notas'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _updateAppointmentStatus(String status) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('citas')
          .doc(widget.appointmentId)
          .update({
        'estado': status,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Cita ${status == 'completada' ? 'completada' : 'cancelada'} correctamente'),
          backgroundColor: status == 'completada' ? Colors.green : Colors.red,
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

  void _addMedicalNotes() async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('citas')
        .doc(widget.appointmentId)
        .get();

    if (!docSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró la cita')),
      );
      return;
    }

    final appointmentData = docSnapshot.data() as Map<String, dynamic>;
    final currentNotes = appointmentData['notas'] as String? ?? '';

    final TextEditingController notesController =
        TextEditingController(text: currentNotes);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notas Médicas'),
        content: TextField(
          controller: notesController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Agregue notas sobre la consulta...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('citas')
                    .doc(widget.appointmentId)
                    .update({
                  'notas': notesController.text.trim(),
                  'fechaActualizacion': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notas guardadas correctamente'),
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
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  int _calculateDuration(DateTime start, DateTime end) {
    return end.difference(start).inMinutes;
  }
}
