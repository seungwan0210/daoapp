// lib/user/widgets/barrel_image_widget.dart
import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class BarrelImageWidget extends StatelessWidget {
  final ProfileService service;
  const BarrelImageWidget({required this.service, super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final hasImage = service.barrelImage != null || service.firestoreBarrelUrl != null;

        return Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                image: hasImage ? service.getBarrelDecorationImage() : null,
              ),
              child: !hasImage
                  ? const Icon(Icons.sports_esports, size: 40, color: Colors.grey)
                  : null,
            ),
            // 카메라 버튼
            Positioned(
              bottom: 0,
              right: 0,
              child: _buildCustomButton(
                context: context,
                icon: Icons.camera_alt,
                onTap: () => service.pickImage(false),
                size: 28,
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
                  onTap: () => service.deleteImage(false),
                  size: 24,
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