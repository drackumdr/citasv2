import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:citas_v2/theme/app_theme.dart';
import 'package:citas_v2/screens/doctor_landing_page.dart';

class DoctorsListScreen extends StatefulWidget {
  const DoctorsListScreen({super.key});

  @override
  State<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends State<DoctorsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSpecialty;
  List<String> _specialties = [];

  @override
  void initState() {
    super.initState();
    _loadSpecialties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialties() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('rol', isEqualTo: 'doctor')
          .get();

      // Extract unique specialties
      final Set<String> specialtiesSet = {};
      for (var doc in snapshot.docs) {
        final Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['especialidad'] != null) {
          specialtiesSet.add(data['especialidad']);
        }
      }

      setState(() {
        _specialties = specialtiesSet.toList()..sort();
      });
    } catch (e) {
      print('Error loading specialties: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directorio Médico'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            color: AppTheme.primaryColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar médico por nombre',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Specialty filter dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Filtrar por especialidad'),
                      value: _selectedSpecialty,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedSpecialty = newValue;
                        });
                      },
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todas las especialidades'),
                        ),
                        ..._specialties.map((String specialty) {
                          return DropdownMenuItem<String>(
                            value: specialty,
                            child: Text(specialty),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Doctors list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .where('rol', isEqualTo: 'doctor')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay médicos disponibles'),
                  );
                }

                // Filter doctors by search query and specialty
                var filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final doctorName =
                      (data['nombre'] ?? '').toString().toLowerCase();
                  final doctorSpecialty = data['especialidad'] as String?;

                  // Apply search filter
                  final matchesSearch = _searchQuery.isEmpty ||
                      doctorName.contains(_searchQuery.toLowerCase());

                  // Apply specialty filter
                  final matchesSpecialty = _selectedSpecialty == null ||
                      doctorSpecialty == _selectedSpecialty;

                  return matchesSearch && matchesSpecialty;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child:
                        Text('No se encontraron médicos con estos criterios'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doctorDoc = filteredDocs[index];
                    final doctorData = doctorDoc.data() as Map<String, dynamic>;

                    return DoctorCard(
                      doctorId: doctorDoc.id,
                      name: doctorData['nombre'] ?? 'Sin nombre',
                      specialty:
                          doctorData['especialidad'] ?? 'Sin especialidad',
                      imageUrl: doctorData['imageUrl'],
                      rating: doctorData['rating']?.toDouble() ?? 0.0,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DoctorLandingPage(
                              doctorId: doctorDoc.id,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final String doctorId;
  final String name;
  final String specialty;
  final String? imageUrl;
  final double rating;
  final VoidCallback onTap;

  const DoctorCard({
    super.key,
    required this.doctorId,
    required this.name,
    required this.specialty,
    this.imageUrl,
    required this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Doctor image
              CircleAvatar(
                radius: 35,
                backgroundImage: imageUrl != null
                    ? NetworkImage(imageUrl!)
                    : const AssetImage('assets/images/doctor_default.jpg')
                        as ImageProvider,
              ),
              const SizedBox(width: 16),

              // Doctor info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.medical_services,
                          size: 14,
                          color: AppTheme.doctorColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          specialty,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating > 0 ? rating.toString() : 'Sin calificación',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // View profile button
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
