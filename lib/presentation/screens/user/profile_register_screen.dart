// lib/presentation/screens/user/profile_register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/user_model.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class ProfileRegisterScreen extends ConsumerStatefulWidget {
  const ProfileRegisterScreen({super.key});

  // body만 반환
  static Widget body() => const ProfileRegisterScreenBody();

  @override
  ConsumerState<ProfileRegisterScreen> createState() => _ProfileRegisterScreenState();
}

class _ProfileRegisterScreenState extends ConsumerState<ProfileRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _koreanNameController = TextEditingController();
  final _englishNameController = TextEditingController();
  final _shopNameController = TextEditingController();
  String? _gender;

  @override
  void dispose() {
    _koreanNameController.dispose();
    _englishNameController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userDoc.update({
        'koreanName': _koreanNameController.text,
        'englishName': _englishNameController.text,
        'shopName': _shopNameController.text,
        'gender': _gender,
        'hasProfile': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileRegisterScreen.body();
  }
}

class ProfileRegisterScreenBody extends ConsumerWidget {
  const ProfileRegisterScreenBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: GlobalKey<FormState>(),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: '한글 이름',
                  labelStyle: theme.textTheme.bodyMedium,
                ),
                validator: (value) => value!.isEmpty ? '한글 이름을 입력하세요' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: '영문 이름',
                  labelStyle: theme.textTheme.bodyMedium,
                ),
                validator: (value) => value!.isEmpty ? '영문 이름을 입력하세요' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: '샵 이름 (선택)',
                  labelStyle: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: '성별 (선택)',
                  labelStyle: theme.textTheme.bodyMedium,
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('남성')),
                  DropdownMenuItem(value: 'female', child: Text('여성')),
                ],
                onChanged: (value) {},
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // _submit 로직은 state에서 처리
                    // 여기서는 간단히 pop
                    Navigator.pop(context);
                  },
                  child: const Text('등록'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}