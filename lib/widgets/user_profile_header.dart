import 'package:flutter/material.dart';

class UserProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final String? photoUrl;
  final Color roleColor;
  final VoidCallback? onTap;

  const UserProfileHeader({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
    required this.roleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl!) : null,
                    radius: 30,
                    child: photoUrl == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          role,
                          style: TextStyle(
                            color: roleColor,
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
    );
  }
}
