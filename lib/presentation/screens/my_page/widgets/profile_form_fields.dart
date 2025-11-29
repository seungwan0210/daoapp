// lib/user/widgets/profile_form_fields.dart
import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class ProfileFormFields extends StatelessWidget {
  final ProfileService service;
  const ProfileFormFields({required this.service, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: service.koreanNameCtrl,
          decoration: const InputDecoration(labelText: '한국 이름', prefixIcon: Icon(Icons.person)),
          validator: (v) => v!.trim().isEmpty ? '한국 이름을 입력하세요' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: service.englishNameCtrl,
          decoration: const InputDecoration(labelText: '영어 이름', prefixIcon: Icon(Icons.translate)),
          validator: (v) => v!.trim().isEmpty ? '영어 이름을 입력하세요' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: service.shopNameCtrl,
          decoration: const InputDecoration(labelText: '샵 이름', prefixIcon: Icon(Icons.store)),
          validator: (v) => v!.trim().isEmpty ? '샵 이름을 입력하세요' : null,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}