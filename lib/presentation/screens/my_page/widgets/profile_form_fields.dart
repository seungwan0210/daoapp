// lib/presentation/screens/my_page/widgets/profile_form_fields.dart

import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class ProfileFormFields extends StatelessWidget {
  final ProfileService service;
  const ProfileFormFields({required this.service, super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Column(
      children: [
        // 🔹 로컬 이름 입력 (한국어/해당 국가 언어)
        TextFormField(
          controller: service.koreanNameCtrl,
          decoration: InputDecoration(
            labelText: s.profile_form_korean_name,
            hintText: s.profile_form_korean_name_hint,
            prefixIcon: const Icon(Icons.person),
          ),
          validator: (v) => v!.trim().isEmpty ? s.profile_form_korean_name_hint : null,
        ),
        const SizedBox(height: 12),

        // 🔹 글로벌 통용 이름 입력 (영문)
        TextFormField(
          controller: service.englishNameCtrl,
          decoration: InputDecoration(
            labelText: s.profile_form_english_name,
            hintText: s.profile_form_english_name_hint,
            prefixIcon: const Icon(Icons.translate),
          ),
          validator: (v) => v!.trim().isEmpty ? s.profile_form_english_name_hint : null,
        ),
        const SizedBox(height: 12),

        // 🔹 소속 샵 입력
        TextFormField(
          controller: service.shopNameCtrl,
          decoration: InputDecoration(
            labelText: s.profile_form_shop_name,
            hintText: s.profile_form_shop_name_hint,
            prefixIcon: const Icon(Icons.store),
          ),
          validator: (v) => v!.trim().isEmpty ? s.profile_form_shop_name_hint : null,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}