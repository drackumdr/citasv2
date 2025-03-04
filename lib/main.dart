import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:citas_v2/firebase_options.dart';
import 'package:citas_v2/widgets/role_based_redirect.dart';
import 'package:citas_v2/theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Agregamos manejo de errores para la inicialización de Firebase
  try {
    log('Iniciando configuración de Firebase');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log('Firebase inicializado correctamente');

    // Initialize date formatting for Spanish locale
    await initializeDateFormatting('es', null);

    runApp(const MyApp());
  } catch (e) {
    log('Error al inicializar Firebase: $e');
    runApp(const ErrorApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Citas App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RoleBasedRedirect(),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 86, color: AppTheme.errorColor),
                const SizedBox(height: 24),
                Text(
                  'Error de configuración',
                  style: AppTheme.headingStyle
                      .copyWith(color: AppTheme.errorColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'No se pudo inicializar Firebase. Por favor verifica la configuración.',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyStyle,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    log('Intento de reiniciar la app después de error');
                    main();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
