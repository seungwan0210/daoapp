// lib/user/widgets/phone_verification_section.dart
import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class PhoneVerificationSection extends StatelessWidget {
  final ProfileService service;
  const PhoneVerificationSection({required this.service, super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final isEditing = service.isEditingPhone;
        final isVerified = service.isPhoneVerified;
        final isFirstReg = service.isFirstRegistration;

        // 포맷팅: 01025939470 → 010-2593-9470
        String formatPhone(String raw) {
          final digits = raw.replaceAll(RegExp(r'\D'), '');
          if (digits.length != 11 || !digits.startsWith('0')) return raw;
          return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
        }

        final displayPhone = formatPhone(service.phoneCtrl.text);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              const Icon(Icons.phone, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 기존 번호 (인증됨 + 수정 전)
                    if (!isEditing && isVerified && !isFirstReg)
                      Text(
                        displayPhone,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),

                    // 2. 입력창 (최초 등록 OR 수정 중)
                    if (isFirstReg || isEditing)
                      TextFormField(
                        controller: service.phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '01012345678',
                          border: const UnderlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          errorText: _validatePhone(service.phoneCtrl.text) ? null : '11자리 숫자',
                        ),
                        onChanged: (_) => service.notifyListeners(),
                        enabled: !service.codeSent,
                      ),

                    // 3. 인증번호 입력창
                    if (service.codeSent && (isFirstReg || isEditing))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: service.codeCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '인증번호 6자리',
                                  border: UnderlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            service.isVerifying
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: service.verifyCode,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // 4. 액션 버튼들
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 인증 완료 체크
                  if (isVerified && !isEditing && !isFirstReg)
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),

                  // 변경 버튼
                  if (isVerified && !isEditing && !isFirstReg)
                    TextButton(
                      onPressed: () {
                        // 1. 기존 번호를 가져와서 하이픈 제거
                        final originalDigits = service.originalPhone?.replaceAll(RegExp(r'\D'), '') ?? '';

                        // 2. 3-4-4 형식으로 포맷팅
                        String formatted = '';
                        if (originalDigits.length >= 3) formatted += originalDigits.substring(0, 3);
                        if (originalDigits.length > 3) formatted += '-${originalDigits.substring(3, originalDigits.length.clamp(3, 7))}';
                        if (originalDigits.length > 7) formatted += '-${originalDigits.substring(7, originalDigits.length.clamp(7, 11))}';

                        // 3. 컨트롤러에 포맷된 값 넣기
                        service.phoneCtrl.text = formatted;
                        service.phoneCtrl.selection = TextSelection.fromPosition(
                          TextPosition(offset: formatted.length),
                        );

                        // 4. 상태 초기화
                        service.isEditingPhone = true;
                        service.codeSent = false;
                        service.codeCtrl.clear();
                        service.isPhoneVerified = false;
                        service.notifyListeners();
                      },
                      child: const Text('변경', style: TextStyle(fontSize: 12)),
                    ),

                  // 인증번호 요청 버튼
                  if ((isFirstReg || isEditing) && !service.codeSent && !isVerified)
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: service.isVerifying ? null : service.sendVerificationCode,
                    ),

                  // 취소 버튼
                  if (isEditing && !isFirstReg)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        service.isEditingPhone = false;
                        service.codeSent = false;
                        service.codeCtrl.clear();
                        service.phoneCtrl.text = service.originalPhone ?? '';
                        service.isPhoneVerified = true;
                        service.notifyListeners();
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 11자리 숫자 검증
  bool _validatePhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    return digits.length == 11 && digits.startsWith('0');
  }
}