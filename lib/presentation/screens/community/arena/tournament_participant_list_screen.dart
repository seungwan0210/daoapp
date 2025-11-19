// lib/presentation/screens/arena/tournament_participant_list_screen.dart
import 'package:flutter/material.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class TournamentParticipantListScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentTitle; // 선택사항: 화면 상단에 제목 표시용

  const TournamentParticipantListScreen({
    Key? key,
    required this.tournamentId,
    this.tournamentTitle = '참가자 명단',
  }) : super(key: key);

  @override
  State<TournamentParticipantListScreen> createState() => _TournamentParticipantListScreenState();
}

class _TournamentParticipantListScreenState extends State<TournamentParticipantListScreen> {
  final _repository = sl<ArenaRepository>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tournamentTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'CSV 공유',
            onPressed: _shareAsCsv,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: '전체 복사',
            onPressed: _copyAllToClipboard,
          ),
        ],
      ),
      body: StreamBuilder<List<TournamentEntryModel>>(
        stream: _repository.getEntries(widget.tournamentId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data!;

          if (entries.isEmpty) {
            return const Center(
              child: Text('아직 참가자가 없어요', style: TextStyle(fontSize: 18, color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text('${entry.nameKo} (${entry.nameEn})'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entry.rating != null && entry.rating!.isNotEmpty)
                        Text('레이팅: ${entry.rating}'),
                      if (entry.homeShop != null && entry.homeShop!.isNotEmpty)
                        Text('홈샵: ${entry.homeShop}'),
                      Text('연락처: ${entry.phone}'),
                      if (entry.email != null && entry.email!.isNotEmpty)
                        Text('이메일: ${entry.email}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: '이 참가자 정보 복사',
                    onPressed: () => _copyEntryToClipboard(entry),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 참가자 한 명 정보 복사
  void _copyEntryToClipboard(TournamentEntryModel entry) {
    final text = '''
${entry.nameKo} (${entry.nameEn})
연락처: ${entry.phone}
${entry.email != null ? '이메일: ${entry.email}' : ''}
${entry.rating != null ? '레이팅: ${entry.rating}' : ''}
${entry.homeShop != null ? '홈샵: ${entry.homeShop}' : ''}
''';
    Clipboard.setData(ClipboardData(text: text.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('참가자 정보가 복사되었습니다!')),
    );
  }

  // 전체 참가자 CSV 생성 후 공유
  Future<void> _shareAsCsv() async {
    final snapshot = await _repository.getEntries(widget.tournamentId).first;
    if (snapshot.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('참가자가 없어요')));
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('순번,한글이름,영문이름,연락처,이메일,레이팅,홈샵');

    for (int i = 0; i < snapshot.length; i++) {
      final e = snapshot[i];
      buffer.writeln(
        '${i + 1},${e.nameKo},${e.nameEn},${e.phone},${e.email ?? ''},${e.rating ?? ''},${e.homeShop ?? ''}',
      );
    }

    final csvContent = buffer.toString();

    // share_plus로 공유 (카톡, 텔레그램, 이메일 등)
    Share.share(
      csvContent,
      subject: '${widget.tournamentTitle} 참가자 명단',
    );
  }

  // 전체 텍스트로 복사
  Future<void> _copyAllToClipboard() async {
    final snapshot = await _repository.getEntries(widget.tournamentId).first;
    if (snapshot.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('${widget.tournamentTitle} 참가자 명단 (${snapshot.length}명)\n');

    for (int i = 0; i < snapshot.length; i++) {
      final e = snapshot[i];
      buffer.writeln('${i + 1}. ${e.nameKo} (${e.nameEn}) | ${e.phone} | ${e.rating ?? '-'} | ${e.homeShop ?? '-'}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('전체 명단이 복사되었습니다!')),
    );
  }
}