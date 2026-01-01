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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ───────────────── 전화번호 + 버튼 라인 ─────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.phone, size: 20),
                  const SizedBox(width: 12),
                  // 전화번호 텍스트/입력 영역
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. 기존 번호 (인증됨 + 수정 전)
                        if (!isEditing && isVerified && !isFirstReg)
                          Text(
                            displayPhone,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
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
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              errorText:
                                  _validatePhone(service.phoneCtrl.text)
                                      ? null
                                      : '11자리 숫자',
                            ),
                            onChanged: (_) => service.notifyListeners(),
                            // 인증번호가 발송되면 번호 입력은 잠시 막기
                            enabled: !service.codeSent,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 오른쪽 액션 버튼들
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ 인증 완료 체크 아이콘
                      if (isVerified && !isEditing && !isFirstReg)
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 20),

                      // ✅ 번호 변경 버튼
                      if (isVerified && !isEditing && !isFirstReg)
                        TextButton(
                          onPressed: () {
                            // 1. 기존 번호를 가져와서 하이픈 제거
                            final originalDigits = service.originalPhone
                                    ?.replaceAll(RegExp(r'\D'), '') ??
                                '';

                            // 2. 3-4-4 형식으로 포맷팅
                            String formatted = '';
                            if (originalDigits.length >= 3) {
                              formatted += originalDigits.substring(0, 3);
                            }
                            if (originalDigits.length > 3) {
                              final end =
                                  originalDigits.length.clamp(3, 7).toInt();
                              formatted +=
                                  '-${originalDigits.substring(3, end)}';
                            }
                            if (originalDigits.length > 7) {
                              final end =
                                  originalDigits.length.clamp(7, 11).toInt();
                              formatted +=
                                  '-${originalDigits.substring(7, end)}';
                            }

                            // 3. 컨트롤러에 포맷된 값 넣기
                            service.phoneCtrl.text = formatted;
                            service.phoneCtrl.selection =
                                TextSelection.fromPosition(
                              TextPosition(offset: formatted.length),
                            );

                            // 4. 상태 초기화
                            service.isEditingPhone = true;
                            service.codeSent = false;
                            service.codeCtrl.clear();
                            service.isPhoneVerified = false;
                            service.notifyListeners();
                          },
                          child:
                              const Text('변경', style: TextStyle(fontSize: 12)),
                        ),

                      // ✅ 인증번호 요청 버튼 (최초/수정 중 + 아직 코드 안 보냄 + 미인증)
                      if ((isFirstReg || isEditing) &&
                          !service.codeSent &&
                          !isVerified)
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: service.isVerifying
                              ? null
                              : service.sendVerificationCode,
                        ),

                      // ✅ 취소 버튼 (수정 중일 때)
                      if (isEditing && !isFirstReg)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            service.isEditingPhone = false;
                            service.codeSent = false;
                            service.codeCtrl.clear();
                            service.phoneCtrl.text =
                                service.originalPhone ?? '';
                            service.isPhoneVerified = true;
                            service.notifyListeners();
                          },
                        ),
                    ],
                  ),
                ],
              ),

              // ───────────────── 인증번호 입력 라인 ─────────────────
              if (service.codeSent && !isVerified) ...[
                const SizedBox(height: 8),
                Row(
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
              ],
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
