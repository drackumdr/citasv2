import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:citas_v2/services/auth_service.dart';
import 'package:citas_v2/theme/app_theme.dart';
import 'package:citas_v2/widgets/dashboard_card.dart';
import 'package:citas_v2/widgets/user_profile_header.dart';
import 'package:citas_v2/screens/doctors_list_screen.dart';
import 'package:citas_v2/screens/patient_appointments_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientDashboard extends StatelessWidget {
  final User user;

  const PatientDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Paciente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await authService.signOut();
              // No need to navigate - RoleBasedRedirect will handle navigation
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info card
            UserProfileHeader(
              roleColor: AppTheme.patientColor,
              name: user.displayName ?? 'Usuario',
              email: user.email ?? '',
              role: 'Paciente',
              photoUrl: user.photoURL,
            ),
            const SizedBox(height: 24),
            // Upcoming appointments section
            const Text(
              'Próximas Citas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Show upcoming appointments from Firestore
            _buildUpcomingAppointments(context),

            // Patient dashboard content
            const Text(
              'Mis Opciones',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Patient functionalities
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                DashboardCard(
                  title: 'Buscar Médico',
                  icon: Icons.search,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DoctorsListScreen(),
                      ),
                    );
                  },
                ),
                DashboardCard(
                  title: 'Mis Citas',
                  icon: Icons.calendar_today,
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PatientAppointmentsScreen(),
                      ),
                    );
                  },
                ),
                DashboardCard(
                  title: 'Historial',
                  icon: Icons.history,
                  color: Colors.amber,
                  onTap: () {
                    // Navigate to appointment history
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PatientAppointmentsScreen(),
                      ),
                    );
                  },
                ),
                DashboardCard(
                  title: 'Mi Perfil',
                  icon: Icons.person,
                  color: Colors.purple,
                  onTap: () {
                    // Navigate to profile
                  },
                ),
                DashboardCard(
                  title: 'Gestionar Disponibilidad',
                  icon: Icons.schedule,
                  color: Colors.purple,
                  onTap: () {
                    // Navigate to manage availability
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments(BuildContext context) {
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
          return _buildNoAppointmentsCard(context);
        }

        final patientId = userSnapshot.data!.docs[0].id;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('citas')
              .where('pacienteId', isEqualTo: patientId)
              .where('fecha', isGreaterThanOrEqualTo: Timestamp.now())
              .where('estado', isEqualTo: 'pendiente')
              .orderBy('fecha', descending: false)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              print(snapshot.error);
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final appointments = snapshot.data?.docs ?? [];

            if (appointments.isEmpty) {
              return _buildNoAppointmentsCard(context);
            }

            return Column(
              children: appointments.map((doc) {
                final appointment = doc.data() as Map<String, dynamic>;
                final dateTime = (appointment['fecha'] as Timestamp).toDate();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppTheme.doctorColor.withAlpha((0.2 * 255).toInt()),
                      child: Icon(Icons.medical_services,
                          color: AppTheme.doctorColor),
                    ),
                    title:
                        Text('Dr. ${appointment['doctorNombre'] ?? 'Médico'}'),
                    subtitle: Text(
                      'Fecha: ${dateTime.day}/${dateTime.month}/${dateTime.year} - ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PatientAppointmentsScreen(),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildNoAppointmentsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blue[300],
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              'No tienes citas próximas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Busca un médico y agenda una cita',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoctorsListScreen(),
                    ),
                  );
                },
                child: const Text('Buscar Médicos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
