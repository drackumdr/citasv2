import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:citas_v2/services/auth_service.dart';
import 'package:citas_v2/theme/app_theme.dart';
import 'package:citas_v2/widgets/dashboard_card.dart';
import 'package:citas_v2/widgets/user_profile_header.dart';

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
            ),
            const SizedBox(height: 24),

            // Patient dashboard content
            const Text(
              'Mis Citas',
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
                  title: 'Agendar Cita',
                  icon: Icons.add_circle,
                  color: Colors.blue,
                  onTap: () {
                    // Navigate to appointment booking
                  },
                ),
                DashboardCard(
                  title: 'Mis Citas',
                  icon: Icons.calendar_today,
                  color: Colors.green,
                  onTap: () {
                    // Navigate to appointment list
                  },
                ),
                DashboardCard(
                  title: 'Historial',
                  icon: Icons.history,
                  color: Colors.amber,
                  onTap: () {
                    // Navigate to appointment history
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
