import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorManagementScreen extends StatefulWidget {
  const DoctorManagementScreen({super.key});

  @override
  _DoctorManagementScreenState createState() => _DoctorManagementScreenState();
}

class _DoctorManagementScreenState extends State<DoctorManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _especialidadController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();

  String _editingDoctorId = '';
  bool _isEditing = false;
  String _selectedRole = 'doctor'; // Default role
  bool _isSuspended = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _especialidadController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nombreController.clear();
    _emailController.clear();
    _especialidadController.clear();
    _telefonoController.clear();
    _direccionController.clear();
    setState(() {
      _isEditing = false;
      _editingDoctorId = '';
      _selectedRole = 'doctor';
      _isSuspended = false;
    });
  }

  Future<void> _saveDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    final Map<String, dynamic> doctorData = {
      'nombre': _nombreController.text.trim(),
      'email': _emailController.text.trim(),
      'especialidad': _especialidadController.text.trim(),
      'telefono': _telefonoController.text.trim(),
      'direccion': _direccionController.text.trim(),
      'rol': _selectedRole,
      'isSuspended': _isSuspended,
    };

    try {
      if (_isEditing) {
        // Update existing doctor
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(_editingDoctorId)
            .update(doctorData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Doctor actualizado exitosamente")),
        );
      } else {
        // Create new doctor
        doctorData['horario'] = {
          'lunes': <dynamic>[],
          'martes': <dynamic>[],
          'miércoles': <dynamic>[],
          'jueves': <dynamic>[],
          'viernes': <dynamic>[],
          'sábado': <dynamic>[],
          'domingo': <dynamic>[]
        };
        doctorData['fechaRegistro'] = FieldValue.serverTimestamp();

        await FirebaseFirestore.instance.collection('usuarios').add(doctorData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Doctor registrado exitosamente")),
        );
      }
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  void _editDoctor(DocumentSnapshot doctorDoc) {
    final doctorData = doctorDoc.data() as Map<String, dynamic>;
    _nombreController.text = doctorData['nombre'] ?? '';
    _emailController.text = doctorData['email'] ?? '';
    _especialidadController.text = doctorData['especialidad'] ?? '';
    _telefonoController.text = doctorData['telefono'] ?? '';
    _direccionController.text = doctorData['direccion'] ?? '';
    _selectedRole = doctorData['rol'] ?? 'doctor';
    _isSuspended = doctorData['isSuspended'] ?? false;

    setState(() {
      _isEditing = true;
      _editingDoctorId = doctorDoc.id;
    });
  }

  Future<void> _deleteDoctor(String doctorId) async {
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(doctorId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Doctor eliminado exitosamente")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al eliminar: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Administración de Doctores"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearForm,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Doctor Form
            Form(
              key: _formKey,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? "Editar Doctor" : "Registrar Doctor",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: "Nombre",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingrese un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Correo Electrónico",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingrese un correo electrónico';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Por favor ingrese un correo electrónico válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _especialidadController,
                        decoration: const InputDecoration(
                          labelText: "Especialidad",
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingrese una especialidad';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _telefonoController,
                        decoration: const InputDecoration(
                          labelText: "Teléfono",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _direccionController,
                        decoration: const InputDecoration(
                          labelText: "Dirección",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Rol",
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedRole,
                        items: <String>['admin', 'doctor', 'patient']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedRole = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text("Suspendido:"),
                          Switch(
                            value: _isSuspended,
                            onChanged: (bool newValue) {
                              setState(() {
                                _isSuspended = newValue;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxWidth: 400), // Adjust the maxWidth as needed
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveDoctor,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                ),
                                child: Text(
                                    _isEditing ? "Actualizar" : "Registrar"),
                              ),
                            ),
                            if (_isEditing) ...[
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: _clearForm,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  backgroundColor: Colors.grey,
                                ),
                                child: const Text("Cancelar"),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // List of Doctors
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Listado de Doctores",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('usuarios')
                          .where('rol', isNotEqualTo: 'admin')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Error al cargar los datos'),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text('No hay doctores registrados'),
                          );
                        }

                        final doctors = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: doctors.length,
                          itemBuilder: (context, index) {
                            final doctor = doctors[index];
                            final data = doctor.data() as Map<String, dynamic>;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                title: Text(data['nombre'] ?? 'Sin nombre'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['especialidad'] ??
                                        'Sin especialidad'),
                                    Text(data['email'] ?? 'Sin correo'),
                                    Text('Rol: ${data['rol'] ?? 'Sin rol'}'),
                                    Text(
                                        'Suspendido: ${data['isSuspended'] ?? false}'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () => _editDoctor(doctor),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                              "Confirmar eliminación"),
                                          content: const Text(
                                              "¿Está seguro que desea eliminar este doctor?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text("Cancelar"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deleteDoctor(doctor.id);
                                              },
                                              child: const Text("Eliminar"),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
