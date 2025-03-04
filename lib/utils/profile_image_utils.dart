import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileImageUtils {
  /// Returns a widget that displays a profile image with proper error handling for Google profile images
  static Widget profileImageWidget({
    required String? imageUrl,
    required double radius,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    // Check if it's a Google profile image (which often causes 429 errors)
    final bool isGoogleProfileImage = imageUrl != null &&
        (imageUrl.contains('googleusercontent.com') ||
            imageUrl.contains('lh3.google.com'));

    if (imageUrl == null || imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[200],
        child: Icon(Icons.person, size: radius * 0.8, color: Colors.grey[500]),
      );
    }

    // For Google profile images, use a more resilient approach with CachedNetworkImage
    if (isGoogleProfileImage) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              placeholder ??
              CircleAvatar(
                radius: radius,
                backgroundColor: Colors.grey[200],
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          errorWidget: (context, url, error) {
            print('Error loading Google profile image: $error');
            return errorWidget ??
                CircleAvatar(
                  radius: radius,
                  backgroundColor: Colors.grey[200],
                  child: Icon(Icons.person,
                      size: radius * 0.8, color: Colors.grey[500]),
                );
          },
          cacheKey: imageUrl,
          useOldImageOnUrlChange: true,
          memCacheHeight:
              (radius * 2 * ProfileImageUtils.devicePixelRatio).toInt(),
        ),
      );
    }

    // For regular images
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      backgroundImage: NetworkImage(imageUrl),
      onBackgroundImageError: (exception, stackTrace) {
        print('Error loading profile image: $exception');
      },
      child: null,
    );
  }

  static double devicePixelRatio = 1.0; // Will be updated from main.dart
}
