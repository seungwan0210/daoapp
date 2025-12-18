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

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    service = ProfileService(context, ref);
  }

  Future<void> _onSave() async {
    // 1) 폼 검증
    final form = _formKey.currentState;
    if (form == null) return;

    final isValid = form.validate();
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('입력값을 확인해주세요.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2) 중복 클릭 방지
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // ✅ service.save()가 이제 결과를 리턴한다고 가정 (아래 2번 참고)
      final result = await service.saveAndReturnResult(_formKey);

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장 완료!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final msg = (result.message?.trim().isNotEmpty == true)
            ? result.message!.trim()
            : '저장에 실패했어요. 다시 시도해주세요.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $msg'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 중 오류: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
                        onPressed: _isSaving ? null : _onSave,
                        child: _isSaving
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text('완료'),
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

  @override
  void dispose() {
    // service.dispose();  // 삭제!
    super.dispose();
  }
}
