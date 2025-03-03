import 'package:flutter/material.dart';
import 'package:citas_v2/theme/app_theme.dart';

class UserProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final String? photoUrl;
  final Color roleColor;
  final VoidCallback? onProfileTap;

  const UserProfileHeader({
    Key? key,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
    required this.roleColor,
    this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onProfileTap,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: roleColor.withOpacity(0.1),
                      child: photoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(36),
                              child: Image.network(
                                photoUrl!,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.person,
                                        size: 36, color: roleColor),
                              ),
                            )
                          : Icon(Icons.person, size: 36, color: roleColor),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            color: AppTheme.secondaryTextColor,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getRoleDisplayName(role),
                            style: TextStyle(
                              color: roleColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onProfileTap != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: onProfileTap,
                      tooltip: 'Editar perfil',
                      color: AppTheme.primaryColor,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleDisplayName(String roleKey) {
    switch (roleKey.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'doctor':
        return 'Médico';
      case 'paciente':
        return 'Paciente';
      default:
        return 'Usuario';
    }
  }
}
