// lib/presentation/screens/my_page/profile_register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/profile_form_fields.dart';
import 'widgets/barrel_setting_section.dart';
import 'widgets/profile_image_widget.dart';
import 'services/profile_service.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/utils/chat_utils.dart';
import 'package:daoapp/l10n/app_localizations.dart';

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

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(milliseconds: 2000), // 메시지를 읽을 시간을 위해 조금 늘림
      ),
    );
  }

  Future<void> _onSave() async {
    final s = AppLocalizations.of(context)!;
    final form = _formKey.currentState;
    if (form == null) return;

    if (!form.validate()) {
      _showSnackBar(s.profile_reg_input_check, isError: true);
      return;
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final bool isFirstTime = service.isFirstRegistration;

      // ✅ 서비스 레벨에서 중복 체크 및 저장을 수행하고 결과 객체를 받음
      final result = await service.saveAndReturnResult(_formKey);

      if (!mounted) return;

      if (result.success) {
        _showSnackBar(s.profile_reg_success);

        if (isFirstTime) {
          try {
            final nickName = service.koreanNameCtrl.text.trim();
            await ChatUtils.sendWelcomeNotice(nickName);
          } catch (chatError) {
            debugPrint('Welcome message error: $chatError');
          }
        }

        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.of(context).pop(true);
      } else {
        // ✅ [수정] 서비스에서 반환된 구체적인 메시지(예: 닉네임 중복)가 있으면 표시하고, 없으면 기본 실패 메시지 표시
        final errorMessage = result.message ?? s.profile_reg_fail;
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      // 예외 발생 시 상세 내용을 사용자에게 알림
      _showSnackBar(s.profile_reg_error(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CommonAppBar(
        title: s.profile_reg_title,
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
                    const SizedBox(height: 24),
                    BarrelSettingSection(service: service),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _onSave,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            : Text(s.profile_reg_save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
}