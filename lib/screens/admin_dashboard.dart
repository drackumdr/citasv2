import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:citas_v2/services/auth_service.dart';
import 'package:citas_v2/screens/doctor_management_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
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
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          radius: 30,
                          child: user?.photoURL == null
                              ? const Icon(Icons.person, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'Administrador',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                user?.email ?? 'No email',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const Text(
                                'Administrador',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Admin dashboard content
            const Text(
              'Gestión del Sistema',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Admin functionalities
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildFeatureCard(
                  context: context,
                  title: 'Gestionar Usuarios',
                  icon: Icons.people,
                  color: Colors.blue,
                  onTap: () {
                    // Navigate to user management
                  },
                ),
                _buildFeatureCard(
                  context: context,
                  title: 'Gestionar Médicos',
                  icon: Icons.medical_services,
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DoctorManagementScreen()),
                    );
                  },
                ),
                _buildFeatureCard(
                  context: context,
                  title: 'Informes',
                  icon: Icons.analytics,
                  color: Colors.purple,
                  onTap: () {
                    // Navigate to reports
                  },
                ),
                _buildFeatureCard(
                  context: context,
                  title: 'Configuración',
                  icon: Icons.settings,
                  color: Colors.orange,
                  onTap: () {
                    // Navigate to settings
                  },
                ),
                _buildFeatureCard(
                  context: context,
                  title: 'Gestionar Disponibilidad',
                  icon: Icons.schedule,
                  color: Colors.teal,
                  onTap: () {
                    // Navigate to manage availability
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
