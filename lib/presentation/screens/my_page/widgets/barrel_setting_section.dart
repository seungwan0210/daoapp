// lib/presentation/screens/my_page/widgets/barrel_setting_section.dart
import 'package:flutter/material.dart';
import 'barrel_image_widget.dart';
import '../services/profile_service.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class BarrelSettingSection extends StatelessWidget {
  final ProfileService service;
  const BarrelSettingSection({required this.service, super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스

    return ExpansionTile(
      leading: const Icon(Icons.sports_esports),
      title: Text(s.barrel_section_title), // 🔹 다국어 적용
      children: [
        // 배럴 이름
        TextFormField(
          controller: service.barrelNameCtrl,
          decoration: InputDecoration(
            labelText: s.barrel_label_name, // 🔹 다국어 적용
            prefixIcon: const Icon(Icons.sports_esports),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        // 샤프트
        TextFormField(
          controller: service.shaftCtrl,
          decoration: InputDecoration(
            labelText: s.barrel_label_shaft, // 🔹 다국어 적용
            prefixIcon: const Icon(Icons.straighten),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        // 플라이트
        TextFormField(
          controller: service.flightCtrl,
          decoration: InputDecoration(
            labelText: s.barrel_label_flight, // 🔹 다국어 적용
            prefixIcon: const Icon(Icons.flight),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        // 팁
        TextFormField(
          controller: service.tipCtrl,
          decoration: InputDecoration(
            labelText: s.barrel_label_tip, // 🔹 다국어 적용
            prefixIcon: const Icon(Icons.push_pin),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // 배럴 사진 위젯
        Center(child: BarrelImageWidget(service: service)),
      ],
    );
  }
}