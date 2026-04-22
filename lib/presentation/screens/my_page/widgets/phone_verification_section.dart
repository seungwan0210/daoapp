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

        // 포맷팅 로직 (한국 번호일 때만 하이픈 추가)
        String formatPhone(String raw) {
          final digits = raw.replaceAll(RegExp(r'\D'), '');
          if (service.selectedCountryCode == '+82') {
            if (digits.length == 11 && digits.startsWith('0')) {
              return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
            }
          }
          return raw; // 해외 번호는 입력값 그대로 노출
        }

        final displayPhone = formatPhone(service.phoneCtrl.text);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🆕 1. 국가 코드 선택 섹션 (입력창 위 배치하여 가독성 확보)
              if (isFirstReg || isEditing) ...[
                const Text(
                  '국가 선택',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                DropdownButton<String>(
                  value: service.selectedCountryCode,
                  isExpanded: true,
                  underline: Container(height: 1, color: Colors.grey.shade300),
                  onChanged: service.codeSent ? null : (String? newValue) {
                    if (newValue != null) service.setCountryCode(newValue);
                  },
                  items: const [
                    DropdownMenuItem(value: '+82', child: Text('🇰🇷 대한민국 (+82)')),
                    DropdownMenuItem(value: '+81', child: Text('🇯🇵 일본 (+81)')),
                    DropdownMenuItem(value: '+1', child: Text('🇺🇸 미국/캐나다 (+1)')),
                    DropdownMenuItem(value: '+886', child: Text('🇹🇼 대만 (+886)')),
                    DropdownMenuItem(value: '+852', child: Text('🇭🇰 홍콩 (+852)')),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // ───────────────── 전화번호 입력/표시 라인 ─────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.phone, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ 인증 완료된 번호 표시 모드
                        if (!isEditing && isVerified && !isFirstReg)
                          Text(
                            '${service.selectedCountryCode} $displayPhone',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),

                        // ✅ 번호 입력 모드
                        if (isFirstReg || isEditing)
                          TextFormField(
                            controller: service.phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: service.selectedCountryCode == '+82' ? '01012345678' : 'Phone Number',
                              border: const UnderlineInputBorder(),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              // 한국일 때만 11자리 체크, 나머지는 단순 존재 여부 체크
                              errorText: _validatePhoneInput(service.phoneCtrl.text, service.selectedCountryCode)
                                  ? null
                                  : '번호를 확인해주세요',
                            ),
                            onChanged: (_) => service.notifyListeners(),
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
                      if (isVerified && !isEditing && !isFirstReg)
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),

                      if (isVerified && !isEditing && !isFirstReg)
                        TextButton(
                          onPressed: () {
                            service.isEditingPhone = true;
                            service.codeSent = false;
                            service.codeCtrl.clear();
                            service.isPhoneVerified = false;
                            service.notifyListeners();
                          },
                          child: const Text('변경', style: TextStyle(fontSize: 12)),
                        ),

                      if ((isFirstReg || isEditing) && !service.codeSent && !isVerified)
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: service.isVerifying ? null : service.sendVerificationCode,
                        ),

                      // lib/user/widgets/phone_verification_section.dart (해당 부분)

                      if (isEditing && !isFirstReg && !service.codeSent)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            // ✅ 개별 변수를 수정하는 대신, 서비스의 통합 롤백 메서드를 호출합니다.
                            service.cancelEditing();
                          },
                        ),
                    ],
                  ),
                ],
              ),

              // 🆕 2. 인증번호 입력 라인 (오입력 대응 수정 버튼 포함)
              if (service.codeSent && !isVerified) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: service.codeCtrl,
                        keyboardType: TextInputType.number,
                        // ✨ iOS/Android 인증번호 자동완성 (키보드 상단 노출)
                        autofillHints: const [AutofillHints.oneTimeCode],
                        decoration: InputDecoration(
                          hintText: '인증번호 6자리',
                          border: const UnderlineInputBorder(),
                          isDense: true,
                          // ✨ 번호 오입력 시 탈출구 버튼 추가
                          suffixIcon: TextButton(
                            onPressed: service.resetVerification,
                            child: const Text('번호 수정', style: TextStyle(color: Colors.red, fontSize: 12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    service.isVerifying
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: service.verifyCode,
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    '문자로 발송된 6자리 코드를 입력해주세요.',
                    style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // 🆕 국가별 유연한 번호 검증
  bool _validatePhoneInput(String input, String countryCode) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return true; // 입력 중에는 에러 안 띄움

    if (countryCode == '+82') {
      return digits.length >= 10 && digits.length <= 11 && digits.startsWith('0');
    }
    // 해외 번호는 최소 7자리 이상이면 일단 허용 (국가별 편차가 큼)
    return digits.length >= 7;
  }
}