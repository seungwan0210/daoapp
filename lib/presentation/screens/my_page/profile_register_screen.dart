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

  /// 공통 스낵바 메서드
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  Future<void> _onSave() async {
    // 1) 폼 검증
    final form = _formKey.currentState;
    if (form == null) return;

    final isValid = form.validate();
    if (!isValid) {
      _showSnackBar('입력값을 확인해주세요.', isError: true);
      return;
    }

    // 2) 중복 클릭 방지
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // ✅ 서비스 저장 실행
      final result = await service.saveAndReturnResult(_formKey);

      if (!mounted) return;

      if (result.success) {
        // 성공 피드백 표시
        _showSnackBar('성공적으로 저장되었습니다!');

        // ✅ 저장 완료 후 약 0.8초 뒤에 자동으로 마이페이지로 이동
        // 유저가 스낵바를 인지할 시간을 줍니다.
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          // 마이페이지로 돌아가기 (결과값 true 전달)
          Navigator.of(context).pop(true);
        }
      } else {
        final msg = (result.message?.trim().isNotEmpty == true)
            ? result.message!.trim()
            : '저장에 실패했어요. 다시 시도해주세요.';
        _showSnackBar('저장 실패: $msg', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('저장 중 오류가 발생했습니다: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold 내부의 내용을 WillPopScope나 PopScope로 감싸서
    // 저장 중일 때 뒤로가기를 막는 처리도 고려해볼 수 있습니다.
    return Scaffold(
      appBar: CommonAppBar(
        title: '프로필 등록/수정',
        showBackButton: !_isSaving, // 저장 중일 때는 뒤로가기 버튼 비활성화 권장
      ),
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
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          '저장 완료',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40), // 하단 여백 추가
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 필요한 경우 여기서 service 내의 컨트롤러들을 정리합니다.
    super.dispose();
  }
}