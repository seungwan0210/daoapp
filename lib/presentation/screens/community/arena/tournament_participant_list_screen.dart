// lib/presentation/screens/arena/tournament_participant_list_screen.dart

import 'package:flutter/material.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class TournamentParticipantListScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentTitle;

  const TournamentParticipantListScreen({
    super.key,
    required this.tournamentId,
    this.tournamentTitle = '참가자 명단',
  });

  @override
  State<TournamentParticipantListScreen> createState() => _TournamentParticipantListScreenState();
}

class _TournamentParticipantListScreenState extends State<TournamentParticipantListScreen> {
  final _repository = sl<ArenaRepository>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tournamentTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'CSV로 공유',
            onPressed: _shareAsCsv,
          ),
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: '전체 복사',
            onPressed: _copyAllToClipboard,
          ),
        ],
      ),
      body: StreamBuilder<List<TournamentEntryModel>>(
        stream: _repository.getEntries(widget.tournamentId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다', style: TextStyle(color: Colors.red[600])));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data!;

          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  Text(
                    '아직 참가자가 없어요',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  Text('참가 신청을 기다리고 있어요!', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _buildParticipantCard(context, entry, index + 1);
            },
          );
        },
      ),
    );
  }

  Widget _buildParticipantCard(BuildContext context, TournamentEntryModel entry, int rank) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 순위 아바타 (고급스럽게!)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: rank <= 3
                      ? [Colors.amber[600]!, Colors.orange[700]!]
                      : [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // 참가자 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.nameKo} (${entry.nameEn})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (entry.rating?.isNotEmpty == true)
                    _infoRow(Icons.star, '레이팅', entry.rating!),
                  if (entry.homeShop?.isNotEmpty == true)
                    _infoRow(Icons.store, '홈샵', entry.homeShop!),
                  _infoRow(Icons.phone, '연락처', entry.phone),
                  if (entry.email?.isNotEmpty == true)
                    _infoRow(Icons.email, '이메일', entry.email!),
                ],
              ),
            ),

            // 개별 복사 버튼
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.deepPurple),
              tooltip: '이 참가자 정보 복사',
              onPressed: () => _copyEntryToClipboard(entry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  // 개별 참가자 복사
  void _copyEntryToClipboard(TournamentEntryModel entry) {
    final text = '''
${entry.nameKo} (${entry.nameEn})
연락처: ${entry.phone}
${entry.email != null ? '이메일: ${entry.email}\n' : ''}${entry.rating != null ? '레이팅: ${entry.rating}\n' : ''}${entry.homeShop != null ? '홈샵: ${entry.homeShop}' : ''}'''.trim();

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check, color: Colors.white),
            SizedBox(width: 12),
            Text('참가자 정보가 복사되었습니다!'),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // CSV 공유
  Future<void> _shareAsCsv() async {
    final entries = await _repository.getEntries(widget.tournamentId).first;
    if (entries.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('순번,한글이름,영문이름,연락처,이메일,레이팅,홈샵');
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      buffer.writeln('${i + 1},${e.nameKo},${e.nameEn},${e.phone},${e.email ?? ''},${e.rating ?? ''},${e.homeShop ?? ''}');
    }

    Share.share(buffer.toString(), subject: '${widget.tournamentTitle} 참가자 명단 (CSV)');
  }

  // 전체 복사
  Future<void> _copyAllToClipboard() async {
    final entries = await _repository.getEntries(widget.tournamentId).first;
    if (entries.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('${widget.tournamentTitle} 참가자 명단 (${entries.length}명)\n');
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      buffer.writeln('${i + 1}. ${e.nameKo} (${e.nameEn}) | ${e.phone} | ${e.rating ?? '-'} | ${e.homeShop ?? '-'}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('전체 명단이 복사되었습니다!'),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}