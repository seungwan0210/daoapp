// lib/presentation/screens/community/arena/tournament_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:daoapp/core/utils/arena_utils.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class TournamentDetailScreen extends StatelessWidget {
  final TournamentModel tournament;
  final bool isOrganizer;

  const TournamentDetailScreen({
    super.key,
    required this.tournament,
    required this.isOrganizer,
  });

  @override
  Widget build(BuildContext context) {
    final status = ArenaUtils.getEntryStatus(
      eventDate: tournament.eventDate,
      entryStartDate: tournament.entryStartDate,
      entryEndDate: tournament.entryEndDate,
    );
    final canEntry = status == EntryStatus.open;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text('대회 상세'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 포스터 (더 크게 + 고급스럽게)
            if (tournament.imageUrl != null && tournament.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Image.network(
                      tournament.imageUrl!,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                      progress == null ? child : Container(height: 300, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                      errorBuilder: (_, __, ___) => Container(
                        height: 300,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                      ),
                    ),
                    // 어두운 그라데이션 오버레이
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey[200],
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('포스터 준비 중', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // 상태 뱃지 + 주최자 뱃지
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: ArenaUtils.getStatusColor(status, context),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ArenaUtils.getStatusText(status),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (status == EntryStatus.open) ...[
                          const SizedBox(width: 12),
                          Text(
                            ArenaUtils.getEntryDday(tournament.entryEndDate),
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (isOrganizer) ...[
                  const SizedBox(width: 12),
                  Chip(
                    backgroundColor: Colors.deepPurple.withOpacity(0.15),
                    label: const Text('주최 중', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                    avatar: const Icon(Icons.star, color: Colors.deepPurple, size: 20),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 28),

            // 제목
            Text(
              tournament.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // 설명
            Text(
              tournament.description,
              style: TextStyle(fontSize: 16, height: 1.6, color: Colors.grey[800]),
            ),

            const SizedBox(height: 32),

            // 정보 카드 리스트
            _buildInfoCard(context, '대회일', _formatFullDate(tournament.eventDate.toDate()), Icons.calendar_today),
            _buildInfoCard(context, '엔트리 기간', '${_formatFullDate(tournament.entryStartDate.toDate())} ~ ${_formatFullDate(tournament.entryEndDate.toDate())}', Icons.how_to_reg),
            _buildInfoCard(context, '참가비', tournament.entryFee == 0 ? '무료 이벤트' : '${tournament.entryFee.toString()}원', Icons.payments),
            _buildInfoCard(context, '현재 참가자', '${tournament.entryCount}명 참가 중', Icons.people, highlight: true),

            const SizedBox(height: 40),

            // 액션 버튼 영역
            if (isOrganizer)
              _buildActionButton(
                context: context,
                label: '참가자 명단 보기',
                icon: Icons.people,
                color: Colors.deepPurple,
                onTap: () => Navigator.pushNamed(
                  context,
                  RouteConstants.tournamentParticipantList,
                  arguments: {'tournamentId': tournament.id!, 'tournamentTitle': tournament.title},
                ),
              )
            else if (canEntry)
              _buildActionButton(
                context: context,
                label: '지금 참가하기',
                icon: Icons.how_to_reg,
                color: Colors.green[600]!,
                onTap: () => Navigator.pushNamed(context, RouteConstants.tournamentEntryForm, arguments: tournament.id!),
              )
            else
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.lock_clock, size: 70, color: ArenaUtils.getStatusColor(status, context)),
                      const SizedBox(height: 16),
                      Text(
                        ArenaUtils.getStatusText(status),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ArenaUtils.getStatusColor(status, context)),
                      ),
                      const SizedBox(height: 8),
                      Text('엔트리 기간을 기다려주세요', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // context 전달 추가!
  Widget _buildInfoCard(BuildContext context, String label, String value, IconData icon, {bool highlight = false}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: highlight ? Theme.of(context).colorScheme.primary : Colors.grey[600], size: 28),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            color: highlight ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 30),
        label: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: color.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final weekday = ['월', '화', '수', '목', '금', '토', '일'][date.weekday - 1];
    return '${date.year}년 ${date.month}월 ${date.day}일 ($weekday)';
  }
}