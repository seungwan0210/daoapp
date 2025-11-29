// lib/user/profile_register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/profile_form_fields.dart';
import 'widgets/phone_verification_section.dart';
import 'widgets/barrel_setting_section.dart';
import 'widgets/profile_image_widget.dart';
import 'services/profile_service.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class ProfileRegisterScreen extends ConsumerStatefulWidget {
  const ProfileRegisterScreen({super.key});

  @override
  ConsumerState<ProfileRegisterScreen> createState() => _ProfileRegisterScreenState();
}

class _ProfileRegisterScreenState extends ConsumerState<ProfileRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ProfileService service;

  @override
  void initState() {
    super.initState();
    service = ProfileService(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '프로필 등록/수정', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(child: ProfileImageWidget(service: service)),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  children: [
                    ProfileFormFields(service: service),
                    PhoneVerificationSection(service: service),
                    const SizedBox(height: 24),
                    BarrelSettingSection(service: service),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => service.save(_formKey),
                        child: const Text('완료'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void dispose() {
    // service.dispose();  // 삭제!
    super.dispose();
  }
}