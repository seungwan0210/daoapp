// lib/user/widgets/barrel_setting_section.dart
import 'package:flutter/material.dart';
import 'barrel_image_widget.dart';           // 같은 폴더
import '../services/profile_service.dart'; // 형제 폴더

class BarrelSettingSection extends StatelessWidget {
  final ProfileService service;
  const BarrelSettingSection({required this.service, super.key});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.sports_esports),
      title: const Text('배럴 세팅 (선택)'),
      children: [
        TextFormField(
          controller: service.barrelNameCtrl,
          decoration: const InputDecoration(
            labelText: '배럴 이름',
            prefixIcon: Icon(Icons.sports_esports),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: service.shaftCtrl,
          decoration: const InputDecoration(
            labelText: '샤프트',
            prefixIcon: Icon(Icons.straighten),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: service.flightCtrl,
          decoration: const InputDecoration(
            labelText: '플라이트',
            prefixIcon: Icon(Icons.flight),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: service.tipCtrl,
          decoration: const InputDecoration(
            labelText: '팁',
            prefixIcon: Icon(Icons.push_pin),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Center(child: BarrelImageWidget(service: service)),
      ],
    );
  }
}