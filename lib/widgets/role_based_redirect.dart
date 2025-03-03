import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:citas_v2/screens/login_screen.dart';
import 'package:citas_v2/screens/admin_dashboard.dart';
import 'package:citas_v2/screens/doctor_dashboard.dart';
import 'package:citas_v2/screens/patient_dashboard.dart';
import 'package:citas_v2/theme/app_theme.dart';

class RoleBasedRedirect extends StatelessWidget {
  const RoleBasedRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen(
              message: 'Verificando estado de autenticación...');
        }

        if (!snapshot.hasData) return const LoginScreen();

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingScreen(
                  message: 'Cargando datos de usuario...');
            }

            if (!userSnapshot.hasData || userSnapshot.hasError) {
              return _buildErrorScreen(context);
            }

            Map<String, dynamic>? userData =
                userSnapshot.data!.data() as Map<String, dynamic>?;

            // If userData is null or role is not set, default to patient role
            String role = 'paciente';
            if (userData != null) {
              // Check both 'role' and 'rol' keys for compatibility
              role = userData['rol'] ?? userData['role'] ?? 'paciente';
            }

            if (role == 'admin') return const AdminDashboard();
            if (role == 'doctor') return const DoctorDashboard();
            return PatientDashboard(user: snapshot.data!);
          },
        );
      },
    );
  }

  Widget _buildLoadingScreen({required String message}) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withOpacity(0.8),
              AppTheme.secondaryColor,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: 'appLogo',
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 72,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: AppTheme.backgroundColor),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Error al cargar datos del usuario',
                  style: AppTheme.headingStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'No se han podido cargar tus datos. Por favor, intenta iniciar sesión nuevamente.',
                  style: AppTheme.bodyStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Volver a inicio de sesión'),
                  style: AppTheme.primaryButtonStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
