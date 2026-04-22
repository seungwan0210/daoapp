import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class AdminHardCleanupScreen extends StatefulWidget {
  const AdminHardCleanupScreen({super.key});

  @override
  State<AdminHardCleanupScreen> createState() => _AdminHardCleanupScreenState();
}

class _AdminHardCleanupScreenState extends State<AdminHardCleanupScreen> {
  final _uidController = TextEditingController();
  bool _isLoading = false;

  Future<void> _onCleanup() async {
    final uid = _uidController.text.trim();
    if (uid.isEmpty) {
      _showSnackBar('소멸시킬 유저의 UID를 입력해주세요.');
      return;
    }

    // 1. 실수 방지를 위한 최종 확인 팝업
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ 데이터 영구 소멸 집행'),
        content: Text(
          '대상 UID: $uid\n\n이 유저의 게시글, 대회, 랭킹, 하위 찌꺼기 데이터를 포함한 모든 흔적을 삭제하시겠습니까?\n이 작업은 복구가 불가능합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('집행(소멸)', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      // 2. Cloud Functions 호출 (adminHardCleanup)
      final callable = FirebaseFunctions.instanceFor(region: 'asia-northeast3')
          .httpsCallable('adminHardCleanup');

      final result = await callable.call({'uid': uid});

      if (!mounted) return;

      if (result.data['success'] == true) {
        _uidController.clear();
        _showSnackBar(result.data['message'] ?? '데이터가 완벽히 소멸되었습니다.', color: Colors.green);
      } else {
        _showSnackBar('삭제 실패: ${result.data['message']}', color: Colors.red);
      }
    } on FirebaseFunctionsException catch (e) {
      _showSnackBar('서버 오류: ${e.message}', color: Colors.red);
    } catch (e) {
      _showSnackBar('알 수 없는 오류: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '데이터 소멸 관리', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '유저 흔적 소멸',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '탈퇴한 유저의 UID를 입력하여 남아있는 하위 컬렉션(껍데기)과 게시글, 대회 기록 등을 완전히 파쇄합니다.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _uidController,
                      decoration: const InputDecoration(
                        labelText: '삭제할 대상 UID',
                        hintText: '예: OhsvWlkpE1gvWEDNE4JBZ...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.key),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _onCleanup,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('영구 소멸 집행', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _uidController.dispose();
    super.dispose();
  }
}