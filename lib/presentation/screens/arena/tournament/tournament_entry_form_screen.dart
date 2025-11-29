// lib/presentation/screens/community/arena/tournament_entry_form_screen.dart
import 'dart:async';

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

  const TournamentEntryFormScreen({super.key, required this.tournamentId});

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

  TournamentModel? _tournament;
  EntryStatus? _status;
  bool _isFull = false;
  bool _isLoading = false;
  bool _alreadyEntered = false;

  StreamSubscription<QuerySnapshot>? _entrySubscription;

  @override
  void initState() {
    super.initState();
    _loadTournament();
  }

  @override
  void dispose() {
    _entrySubscription?.cancel();
    _nameKoCtrl.dispose();
    _nameEnCtrl.dispose();
    _phoneCtrl.dispose();
    _ratingCtrl.dispose();
    _homeShopCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTournament() async {
    final repo = sl<ArenaRepository>();
    final tournament = await repo.getTournament(widget.tournamentId);
    if (!mounted) return;

    if (tournament != null) {
      final status = ArenaUtils.getEntryStatus(
        entryStartDate: tournament.entryStartDate,
        entryEndDate: tournament.entryEndDate,
        eventDate: tournament.eventDate,
      );
      final isFull = tournament.entryCount >= tournament.maxParticipants;

      setState(() {
        _tournament = tournament;
        _status = status;
        _isFull = isFull;
      });

      // 대회 로드 완료 후 실시간 리스너 시작
      _startListeningToMyEntry();
    }
  }

  // 실시간으로 내 참가 여부 감시 (안정성 100% 보장)
  void _startListeningToMyEntry() {
    _entrySubscription?.cancel(); // 기존 리스너 있으면 취소

    final uid = sl<FirebaseAuth>().currentUser?.uid;
    if (uid == null || _tournament?.id == null) {
      setState(() => _alreadyEntered = false);
      return;
    }

    final colRef = FirebaseFirestore.instance
        .collection('tournaments')
        .doc(_tournament!.id!)
        .collection('entries');

    _entrySubscription = colRef
        .where('userUid', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _alreadyEntered = snapshot.docs.isNotEmpty;
      });
    }, onError: (error) {
      // 네트워크 끊겨도 크래시 안 나게
      if (mounted) {
        setState(() => _alreadyEntered = false);
      }
    });
  }

  bool get _canEnter =>
      _status == EntryStatus.open && !_isFull && !_alreadyEntered;

  bool get _canCancel =>
      _alreadyEntered && _status == EntryStatus.open;

  // 연타 방지 + 안전한 제출
  Future<void> _submit() async {
    if (_isLoading) return;
    if (_tournament == null || !_canEnter || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = sl<FirebaseAuth>().currentUser!;
      final entry = TournamentEntryModel(
        userUid: user.uid,
        nameKo: _nameKoCtrl.text.trim(),
        nameEn: _nameEnCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: user.email,
        rating: _ratingCtrl.text.trim().isEmpty ? null : _ratingCtrl.text.trim(),
        homeShop: _homeShopCtrl.text.trim().isEmpty ? null : _homeShopCtrl.text.trim(),
        createdAt: Timestamp.now(),
      );

      await sl<ArenaRepository>().submitEntry(
        tournamentId: widget.tournamentId,
        entry: entry,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('참가 신청 완료!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('신청 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 취소도 완벽하게
  Future<void> _cancelEntry() async {
    if (!_canCancel || _isLoading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('참가 취소'),
        content: const Text('참가 신청을 취소하시겠습니까?\n다시 신청 가능합니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('아니오')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('취소하기', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await sl<ArenaRepository>().cancelEntry(
        tournamentId: widget.tournamentId,
        userUid: sl<FirebaseAuth>().currentUser!.uid,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('참가 신청이 취소되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('취소 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tournament == null || _status == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 이미 참가한 경우
    if (_alreadyEntered) {
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
                '이미 "${_tournament!.title}"에\n참가 신청하셨습니다.',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_canCancel) ...[
                const Text(
                  '일정 변경 등으로 참가가 어려우면\n아래 버튼을 눌러 참가를 취소할 수 있습니다.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _cancelEntry,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('참가 신청 취소하기', style: TextStyle(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  '현재는 엔트리 마감 이후이므로\n앱에서 직접 취소할 수 없습니다.\n변경이 필요하면 대회 주최자에게 문의해주세요.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      );
    }

    // 신청 불가 상태
    if (_status != EntryStatus.open || _isFull) {
      String titleText;
      String bodyText;

      if (_isFull) {
        titleText = '정원 마감';
        bodyText = '해당 대회는 참가 정원이 이미 마감되었습니다.';
      } else {
        switch (_status!) {
          case EntryStatus.upcoming:
            titleText = '엔트리 예정';
            bodyText = '아직 엔트리 시작 전입니다.\n엔트리가 열리면 신청하실 수 있어요.';
            break;
          case EntryStatus.closed:
            titleText = '엔트리 마감';
            bodyText = '엔트리 마감 후에는 앱에서 신청이 불가능합니다.\n필요 시 대회 주최자에게 문의해주세요.';
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
        appBar: CommonAppBar(title: _tournament!.title, showBackButton: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isFull ? Icons.groups : Icons.event_busy,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(titleText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(bodyText, style: const TextStyle(fontSize: 15, color: Colors.grey), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    // 정상 참가 신청 폼
    return Scaffold(
      appBar: CommonAppBar(title: _tournament!.title, showBackButton: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(_tournament!.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('참가 신청서를 작성해 주세요'),
            const SizedBox(height: 30),

            TextFormField(
              controller: _nameKoCtrl,
              decoration: const InputDecoration(labelText: '한글이름 *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? '필수 입력 항목입니다' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameEnCtrl,
              decoration: const InputDecoration(labelText: '영문이름 *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? '필수 입력 항목입니다' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: '연락처 *'),
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty) ? '필수 입력 항목입니다' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _ratingCtrl,
              decoration: const InputDecoration(labelText: '레이팅 (선택)'),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _homeShopCtrl,
              decoration: const InputDecoration(labelText: '홈샵 (선택)'),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('참가 신청 완료', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}