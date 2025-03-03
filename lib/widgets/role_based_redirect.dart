import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:citas_v2/screens/login_screen.dart';
import 'package:citas_v2/screens/patient_dashboard.dart';
import 'package:citas_v2/screens/doctor_dashboard.dart';
import 'package:citas_v2/screens/admin_dashboard.dart';

class RoleBasedRedirect extends StatelessWidget {
  const RoleBasedRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If not logged in, show login screen
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        // User is logged in, check role in Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('usuarios')
              .where('email', isEqualTo: user.email)
              .limit(1)
              .get()
              .then((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              return FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(snapshot.docs.first.id)
                  .get();
            }
            throw Exception('Usuario no encontrado');
          }),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data == null) {
              // Error or user not found in database
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Error: No se pudo obtener la información del usuario",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: const Text("Volver a iniciar sesión"),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Get user role and redirect accordingly
            final userData = snapshot.data!.data() as Map<String, dynamic>?;
            final String userRole = userData?['rol'] ?? 'paciente';
            final bool isSuspended = userData?['isSuspended'] ?? false;

            // Check if user is suspended
            if (isSuspended) {
              return _buildSuspendedScreen();
            }

            // Redirect based on role
            switch (userRole) {
              case 'admin':
                return const AdminDashboard();
              case 'doctor':
                return const DoctorDashboard();
              case 'paciente':
              default:
                return PatientDashboard(user: user);
            }
          },
        );
      },
    );
  }

  Widget _buildSuspendedScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                'Cuenta suspendida',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tu cuenta ha sido suspendida. Contacta al administrador para más información.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
