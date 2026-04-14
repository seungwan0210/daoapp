import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/core/utils/arena_utils.dart';

class TournamentEntryFormScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const TournamentEntryFormScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  ConsumerState<TournamentEntryFormScreen> createState() =>
      _TournamentEntryFormScreenState();
}

class _TournamentEntryFormScreenState
    extends ConsumerState<TournamentEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameKoCtrl = TextEditingController();
  final _nameEnCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ratingCtrl = TextEditingController();
  final _homeShopCtrl = TextEditingController();

  bool _isSubmitting = false; // 제출/취소 연타 방지

  @override
  void dispose() {
    _nameKoCtrl.dispose();
    _nameEnCtrl.dispose();
    _phoneCtrl.dispose();
    _ratingCtrl.dispose();
    _homeShopCtrl.dispose();
    super.dispose();
  }

  void _showSnack(BuildContext context, String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================
  // ✅ 제출 (B안: repo에서 트랜잭션으로 entryCount 증가가 되어 있어야 함)
  // =========================
  Future<void> _submit({
    required TournamentModel tournament,
    required User user,
  }) async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final entry = TournamentEntryModel(
        userUid: user.uid,
        nameKo: _nameKoCtrl.text.trim(),
        nameEn: _nameEnCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: user.email,
        rating: _ratingCtrl.text.trim().isEmpty ? null : _ratingCtrl.text.trim(),
        homeShop:
        _homeShopCtrl.text.trim().isEmpty ? null : _homeShopCtrl.text.trim(),
        createdAt: Timestamp.now(),
      );

      await sl<ArenaRepository>().submitEntry(
        tournamentId: tournament.id!,
        entry: entry,
      );

      if (!mounted) return;

      // ✅ pop 전에 SnackBar (현재 화면에서 안전하게 띄우기)
      _showSnack(context, '참가 신청 완료!', success: true);
      Navigator.pop(context, true); // ✅ result = true (필요하면 이전 화면에서 갱신용)
    } catch (e) {
      if (!mounted) return;
      _showSnack(context, '신청 실패: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // =========================
  // ✅ 취소 (B안: repo에서 트랜잭션으로 entryCount 감소가 되어 있어야 함)
  // =========================
  Future<void> _cancelEntry({
    required TournamentModel tournament,
    required User user,
  }) async {
    if (_isSubmitting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('참가 취소'),
        content:
        const Text('참가 신청을 취소하시겠습니까?\n엔트리 마감 전까지는 다시 신청 가능합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '취소하기',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      await sl<ArenaRepository>().cancelEntry(
        tournamentId: tournament.id!,
        userUid: user.uid,
      );

      if (!mounted) return;

      _showSnack(context, '참가 신청이 취소되었습니다.', success: true);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack(context, '취소 실패: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = sl<FirebaseAuth>().currentUser;

    // ✅ 로그인 필요
    if (user == null) {
      return Scaffold(
        appBar: CommonAppBar(title: '참가 신청', showBackButton: true),
        body: const Center(child: Text('로그인 후 참가 신청이 가능합니다')),
      );
    }

    final tournamentDoc = FirebaseFirestore.instance
        .collection('tournaments')
        .doc(widget.tournamentId);

    final entriesCol = tournamentDoc.collection('entries');

    // ✅ 대회 문서를 실시간으로 본다 (정원/마감/취소/수정 즉시 반영)
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: tournamentDoc.snapshots(),
      builder: (context, tSnap) {
        if (tSnap.hasError) {
          return Scaffold(
            appBar: CommonAppBar(title: '참가 신청', showBackButton: true),
            body: Center(child: Text('오류: ${tSnap.error}')),
          );
        }

        if (!tSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final doc = tSnap.data!;
        if (!doc.exists || doc.data() == null) {
          return Scaffold(
            appBar: CommonAppBar(title: '참가 신청', showBackButton: true),
            body: const Center(child: Text('대회를 찾을 수 없습니다')),
          );
        }

        final tournament =
        TournamentModel.fromJson(doc.data()!).copyWith(id: doc.id);

        final status = ArenaUtils.getEntryStatus(
          entryStartDate: tournament.entryStartDate,
          entryEndDate: tournament.entryEndDate,
          eventDate: tournament.eventDate,
        );

        // ✅ entries size(실시간)도 같이 본다: entryCount가 잠깐 틀려도 화면에서 방어 가능
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: entriesCol.snapshots(),
          builder: (context, eSnap) {
            final liveEntryCount = eSnap.hasData ? eSnap.data!.size : null;
            final max = tournament.maxParticipants;

            final isFullByLive =
            (liveEntryCount != null) ? liveEntryCount >= max : false;
            final isFullByField = tournament.entryCount >= max;

            // ✅ 둘 중 하나라도 full이면 full로 본다 (보수적)
            final isFull = isFullByLive || isFullByField;

            // ✅ 내 엔트리: docId = user.uid 로 통일
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: entriesCol.doc(user.uid).snapshots(),
              builder: (context, mySnap) {
                final alreadyEntered =
                    mySnap.hasData && (mySnap.data?.exists ?? false);

                final canCancel = alreadyEntered && status == EntryStatus.open;
                final canEnter = status == EntryStatus.open && !isFull;

                // =========================
                // ✅ 이미 참가한 경우 UI
                // =========================
                if (alreadyEntered) {
                  return Scaffold(
                    appBar: CommonAppBar(title: '참가 신청', showBackButton: true),
                    body: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 80,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '이미 "${tournament.title}"에\n참가 신청하셨습니다.',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          // 참가 현황도 같이 보여주면 UX 좋음
                          if (liveEntryCount != null)
                            Text(
                              '현재 참가: $liveEntryCount / $max',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          const SizedBox(height: 24),

                          if (canCancel) ...[
                            const Text(
                              '엔트리 마감 전까지는\n아래 버튼으로 참가를 취소할 수 있습니다.',
                              style:
                              TextStyle(fontSize: 14, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isSubmitting
                                    ? null
                                    : () => _cancelEntry(
                                  tournament: tournament,
                                  user: user,
                                ),
                                icon: const Icon(Icons.cancel_outlined),
                                label: const Text(
                                  '참가 신청 취소하기',
                                  style: TextStyle(fontSize: 16),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ] else ...[
                            const Text(
                              '현재는 엔트리 마감 이후이므로\n앱에서 직접 취소할 수 없습니다.\n변경이 필요하면 주최자에게 문의해주세요.',
                              style:
                              TextStyle(fontSize: 14, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                // =========================
                // ✅ 신청 불가 상태 UI
                // =========================
                if (!canEnter) {
                  String titleText;
                  String bodyText;

                  if (isFull) {
                    titleText = '정원 마감';
                    bodyText = '해당 대회는 참가 정원이 이미 마감되었습니다.';
                  } else {
                    switch (status) {
                      case EntryStatus.upcoming:
                        titleText = '엔트리 예정';
                        bodyText =
                        '아직 엔트리 시작 전입니다.\n엔트리가 열리면 신청하실 수 있어요.';
                        break;
                      case EntryStatus.closed:
                        titleText = '엔트리 마감';
                        bodyText =
                        '엔트리 마감 후에는 앱에서 신청이 불가능합니다.\n필요 시 대회 주최자에게 문의해주세요.';
                        break;
                      case EntryStatus.inProgress:
                        titleText = '대회 진행 중';
                        bodyText = '이미 대회가 진행 중입니다.';
                        break;
                      case EntryStatus.finished:
                        titleText = '대회 종료';
                        bodyText = '이미 종료된 대회입니다.';
                        break;
                      case EntryStatus.canceled:
                        titleText = '대회 취소';
                        bodyText = '해당 대회는 취소되었습니다.';
                        break;
                      default:
                        titleText = '신청 불가';
                        bodyText = '현재는 신청할 수 없는 상태입니다.';
                    }
                  }

                  return Scaffold(
                    appBar: CommonAppBar(
                      title: tournament.title,
                      showBackButton: true,
                    ),
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isFull ? Icons.groups : Icons.event_busy,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              titleText,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              bodyText,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            if (liveEntryCount != null)
                              Text(
                                '현재 참가: $liveEntryCount / $max',
                                style: const TextStyle(color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // =========================
                // ✅ 정상 참가 신청 폼
                // =========================
                return Scaffold(
                  appBar:
                  CommonAppBar(title: tournament.title, showBackButton: true),
                  body: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          tournament.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          liveEntryCount == null
                              ? '참가 신청서를 작성해 주세요'
                              : '참가 신청서를 작성해 주세요  ($liveEntryCount / $max)',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 30),

                        TextFormField(
                          controller: _nameKoCtrl,
                          decoration: const InputDecoration(
                            labelText: '한글이름 *',
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? '필수 입력 항목입니다'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _nameEnCtrl,
                          decoration: const InputDecoration(
                            labelText: '영문이름 *',
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? '필수 입력 항목입니다'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: '연락처 *',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? '필수 입력 항목입니다'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _ratingCtrl,
                          decoration: const InputDecoration(
                            labelText: '레이팅 (선택)',
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _homeShopCtrl,
                          decoration: const InputDecoration(
                            labelText: '홈샵 (선택)',
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 28),

                        // ✅ 정원/마감 다시 한 번 안내
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.18),
                            ),
                          ),
                          child: Text(
                            '엔트리 오픈 상태에서만 신청 가능합니다.\n'
                                '마감 이후 변경이 필요하면 주최자에게 문의해 주세요.',
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),

                        const SizedBox(height: 22),

                        ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _submit(
                            tournament: tournament,
                            user: user,
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            '참가 신청 완료',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
