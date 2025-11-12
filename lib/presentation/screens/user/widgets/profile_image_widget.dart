// lib/user/widgets/profile_image_widget.dart
import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class ProfileImageWidget extends StatelessWidget {
  final ProfileService service;
  const ProfileImageWidget({required this.service, super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final hasImage = service.profileImage != null ||
            service.firestoreProfileUrl != null ||
            (service.isFirstRegistration && service.user?.photoURL != null);

        return Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: hasImage ? service.getProfileImageProvider() : null,
              child: !hasImage
                  ? const Icon(Icons.account_circle, size: 50, color: Colors.grey)
                  : null,
            ),
            // 카메라 버튼
            Positioned(
              bottom: 0,
              right: 0,
              child: _buildCustomButton(
                context: context,
                icon: Icons.camera_alt,
                onTap: () => service.pickImage(true),
                size: 32,
              ),
            ),
            // 삭제 버튼
            if (hasImage)
              Positioned(
                top: 0,
                right: 0,
                child: _buildCustomButton(
                  context: context,
                  icon: Icons.close,
                  onTap: () => service.deleteImage(true),
                  size: 28,
                  backgroundColor: Colors.red,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCustomButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    required double size,
    Color? backgroundColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(size),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor ?? Theme.of(context).colorScheme.primary,
          ),
          child: Icon(icon, size: size * 0.5, color: Colors.white),
        ),
      ),
    );
  }
}