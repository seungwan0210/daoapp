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
// 🎯 ChatUtils 경로 확인 후 임포트하세요
import 'package:daoapp/core/utils/chat_utils.dart';

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
    // ProfileService가 ChangeNotifier이므로
    // initState에서 context와 ref를 넘겨 초기화하는 방식 유지
    service = ProfileService(context, ref);
  }

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
    final form = _formKey.currentState;
    if (form == null) return;

    if (!form.validate()) {
      _showSnackBar('입력값을 확인해주세요.', isError: true);
      return;
    }

    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // 🎯 [수정] ProfileService에 정의된 변수명 'isFirstRegistration' 사용
      final bool isFirstTime = service.isFirstRegistration;

      // 서비스 저장 실행
      final result = await service.saveAndReturnResult(_formKey);

      if (!mounted) return;

      if (result.success) {
        _showSnackBar('성공적으로 저장되었습니다!');

        // 🎯 [수정] 신규 가입 시에만 ChatUtils의 'sendWelcomeNotice' 호출
        if (isFirstTime) {
          try {
            // 🎯 [수정] ProfileService의 'koreanNameCtrl'에서 텍스트 추출
            final nickName = service.koreanNameCtrl.text.trim();
            await ChatUtils.sendWelcomeNotice(nickName);
          } catch (chatError) {
            debugPrint('Welcome message error: $chatError');
          }
        }

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        final msg = (result.message.trim().isNotEmpty == true)
            ? result.message.trim()
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
    return Scaffold(
      appBar: CommonAppBar(
        title: '프로필 등록/수정',
        showBackButton: !_isSaving,
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}