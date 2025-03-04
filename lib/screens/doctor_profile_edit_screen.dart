import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class DoctorProfileEditScreen extends StatefulWidget {
  const DoctorProfileEditScreen({super.key});

  @override
  _DoctorProfileEditScreenState createState() =>
      _DoctorProfileEditScreenState();
}

class _DoctorProfileEditScreenState extends State<DoctorProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _especialidadController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _appointmentDurationController =
      TextEditingController();

  Map<String, List<TimeRange>> availability = {
    'lunes': [],
    'martes': [],
    'miércoles': [],
    'jueves': [],
    'viernes': [],
    'sábado': [],
    'domingo': [],
  };
  String? _imageUrl;
  bool _isLoading = false;
  List<String> _galleryImages = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doctorDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('email', isEqualTo: user.email)
        .get();

    if (doctorDoc.docs.isNotEmpty) {
      final docData = doctorDoc.docs.first.data();
      _especialidadController.text = docData['especialidad'] ?? '';
      _telefonoController.text = docData['telefono'] ?? '';
      _direccionController.text = docData['direccion'] ?? '';
      _appointmentDurationController.text =
          docData['appointmentDuration']?.toString() ?? '';
      _imageUrl = docData['imageUrl'];
      _galleryImages = List<String>.from(docData['galleryImages'] ?? []);

      final horario = docData['horario'] as Map<String, dynamic>?;

      if (horario != null) {
        setState(() {
          availability = horario.map((key, value) {
            if (value is List) {
              return MapEntry(
                key,
                value
                    .map((e) => TimeRange(
                          start: TimeOfDay(
                              hour: (e as Map)['startHour'],
                              minute: (e)['startMinute']),
                          end: TimeOfDay(
                              hour: (e)['endHour'], minute: (e)['endMinute']),
                        ))
                    .toList(),
              );
            } else {
              return MapEntry(key, <TimeRange>[]);
            }
          });
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doctorDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('email', isEqualTo: user.email)
        .get();

    if (doctorDoc.docs.isNotEmpty) {
      final docId = doctorDoc.docs.first.id;

      final horarioParaGuardar = availability.map((key, value) => MapEntry(
          key,
          value
              .map((timeRange) => {
                    'startHour': timeRange.start.hour,
                    'startMinute': timeRange.start.minute,
                    'endHour': timeRange.end.hour,
                    'endMinute': timeRange.end.minute,
                  })
              .toList()));

      final Map<String, dynamic> updatedData = {
        'especialidad': _especialidadController.text,
        'telefono': _telefonoController.text,
        'direccion': _direccionController.text,
        'horario': horarioParaGuardar,
        'imageUrl': _imageUrl,
        'galleryImages': _galleryImages,
        'appointmentDuration':
            int.tryParse(_appointmentDurationController.text) ?? 0,
      };

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(docId)
          .update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
    }
  }

  Future<void> _uploadImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Uint8List? imageBytes;
      String? fileName;

      if (kIsWeb) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          imageBytes = result.files.first.bytes;
          fileName = result.files.first.name;
        }
      } else {
        final ImagePicker picker = ImagePicker();
        final XFile? image =
            await picker.pickImage(source: ImageSource.gallery);

        if (image != null) {
          imageBytes = await image.readAsBytes();
          fileName = image.name;
        }
      }

      if (imageBytes != null && fileName != null) {
        final user = FirebaseAuth.instance.currentUser;
        final String filePathName =
            'doctor_images/${user?.uid}_${DateTime.now().millisecondsSinceEpoch}_$fileName';
        final firebase_storage.Reference storageRef =
            firebase_storage.FirebaseStorage.instance.ref().child(filePathName);

        // Determine MIME type based on file extension
        String? extension = fileName.split('.').last.toLowerCase();
        String contentType = 'image/jpeg'; // Default value

        switch (extension) {
          case 'png':
            contentType = 'image/png';
            break;
          case 'gif':
            contentType = 'image/gif';
            break;
          case 'bmp':
            contentType = 'image/bmp';
            break;
          case 'webp':
            contentType = 'image/webp';
            break;
        }

        final metadata = firebase_storage.SettableMetadata(
          contentType: contentType,
          customMetadata: {'picked-file-path': fileName},
        );

        await storageRef.putData(imageBytes, metadata);
        final downloadUrl = await storageRef.getDownloadURL();

        setState(() {
          _imageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen subida correctamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la imagen: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadGalleryImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Uint8List? imageBytes;
      String? fileName;

      if (kIsWeb) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          imageBytes = result.files.first.bytes;
          fileName = result.files.first.name;
        }
      } else {
        final ImagePicker picker = ImagePicker();
        final XFile? image =
            await picker.pickImage(source: ImageSource.gallery);

        if (image != null) {
          imageBytes = await image.readAsBytes();
          fileName = image.name;
        }
      }

      if (imageBytes != null && fileName != null) {
        final user = FirebaseAuth.instance.currentUser;
        final String filePathName =
            'doctor_gallery/${user?.uid}_${DateTime.now().millisecondsSinceEpoch}_$fileName';
        final firebase_storage.Reference storageRef =
            firebase_storage.FirebaseStorage.instance.ref().child(filePathName);

        // Determine MIME type based on file extension
        String? extension = fileName.split('.').last.toLowerCase();
        String contentType = 'image/jpeg'; // Default value

        switch (extension) {
          case 'png':
            contentType = 'image/png';
            break;
          case 'gif':
            contentType = 'image/gif';
            break;
          case 'bmp':
            contentType = 'image/bmp';
            break;
          case 'webp':
            contentType = 'image/webp';
            break;
        }

        final metadata = firebase_storage.SettableMetadata(
          contentType: contentType,
          customMetadata: {'picked-file-path': fileName},
        );

        await storageRef.putData(imageBytes, metadata);
        final downloadUrl = await storageRef.getDownloadURL();

        setState(() {
          _galleryImages.add(downloadUrl);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen subida correctamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la imagen: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String formatTimeRange(TimeRange timeRange) {
    final format = DateFormat('HH:mm');
    final now = DateTime.now();
    final startDt = DateTime(now.year, now.month, now.day, timeRange.start.hour,
        timeRange.start.minute);
    final endDt = DateTime(
        now.year, now.month, now.day, timeRange.end.hour, timeRange.end.minute);
    return '${format.format(startDt)} - ${format.format(endDt)}';
  }

  Future<void> _addTimeRange(String day) async {
    final TimeRange? result = await showDialog<TimeRange>(
      context: context,
      builder: (BuildContext context) {
        return TimeRangePickerDialog();
      },
    );

    if (result != null) {
      setState(() {
        availability[day]!.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil Profesional'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Profile Picture with improved error handling
                    GestureDetector(
                      onTap: _uploadImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _imageUrl != null
                                ? NetworkImage(_imageUrl!)
                                : null,
                            onBackgroundImageError: _imageUrl != null
                                ? (exception, stackTrace) {
                                    print(
                                        'Error loading profile image: $exception');
                                  }
                                : null,
                            child: _imageUrl == null
                                ? const Icon(Icons.camera_alt,
                                    size: 40, color: Colors.grey)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Specialty
                    TextFormField(
                      controller: _especialidadController,
                      decoration: const InputDecoration(
                        labelText: "Especialidad",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingrese su especialidad';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Phone Number
                    TextFormField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(
                        labelText: "Teléfono",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Address
                    TextFormField(
                      controller: _direccionController,
                      decoration: const InputDecoration(
                        labelText: "Dirección",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Appointment Duration
                    TextFormField(
                      controller: _appointmentDurationController,
                      decoration: const InputDecoration(
                        labelText: "Duración estándar de la cita (minutos)",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingrese la duración de la cita';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Por favor ingrese un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Availability
                    const Text(
                      'Disponibilidad Semanal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (var day in availability.keys)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                day.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Column(
                                children: availability[day]!.map((timeRange) {
                                  return Chip(
                                    label: Text(formatTimeRange(timeRange)),
                                    onDeleted: () {
                                      setState(() {
                                        availability[day]!.remove(timeRange);
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => _addTimeRange(day),
                                child: const Text('Agregar Horario'),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Gallery section with improved error handling
                    const SizedBox(height: 20),
                    const Text(
                      'Galería de Imágenes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _uploadGalleryImage,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Subir Imagen a la Galería'),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: _galleryImages.isEmpty
                          ? Center(
                              child: Text(
                                'No hay imágenes en la galería',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _galleryImages.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border:
                                              Border.all(color: Colors.grey),
                                        ),
                                        child: Image.network(
                                          _galleryImages[index],
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                                child:
                                                    CircularProgressIndicator());
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            print(
                                                'Error loading gallery image: $error');
                                            return const Center(
                                              child: Icon(Icons.broken_image,
                                                  color: Colors.grey),
                                            );
                                          },
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _galleryImages.removeAt(index);
                                          });
                                        },
                                        child: const CircleAvatar(
                                          backgroundColor: Colors.red,
                                          radius: 10,
                                          child: Icon(Icons.close,
                                              size: 12, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class TimeRange {
  TimeOfDay start;
  TimeOfDay end;

  TimeRange({required this.start, required this.end});
}

class TimeRangePickerDialog extends StatefulWidget {
  const TimeRangePickerDialog({super.key});

  @override
  _TimeRangePickerDialogState createState() => _TimeRangePickerDialogState();
}

class _TimeRangePickerDialogState extends State<TimeRangePickerDialog> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Seleccionar rango de tiempo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(_startTime == null
                ? 'Seleccionar hora de inicio'
                : 'Hora de inicio: ${_formatTime(_startTime!)}'),
            onTap: () async {
              final selectedTime = await showTimePicker(
                context: context,
                initialTime: _startTime ?? TimeOfDay.now(),
                builder: (BuildContext context, Widget? child) {
                  return MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  );
                },
              );
              if (selectedTime != null) {
                setState(() {
                  _startTime = selectedTime;
                });
              }
            },
          ),
          ListTile(
            title: Text(_endTime == null
                ? 'Seleccionar hora de fin'
                : 'Hora de fin: ${_formatTime(_endTime!)}'),
            onTap: () async {
              final selectedTime = await showTimePicker(
                context: context,
                initialTime: _endTime ?? TimeOfDay.now(),
                builder: (BuildContext context, Widget? child) {
                  return MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  );
                },
              );
              if (selectedTime != null) {
                setState(() {
                  _endTime = selectedTime;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('Cancelar'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('Aceptar'),
          onPressed: () {
            if (_startTime != null && _endTime != null) {
              Navigator.of(context)
                  .pop(TimeRange(start: _startTime!, end: _endTime!));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Por favor seleccione hora de inicio y fin')),
              );
            }
          },
        ),
      ],
    );
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat('HH:mm');
    return format.format(dt);
  }
}
