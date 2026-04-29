// lib/presentation/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/core/constants/route_constants.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart'; // (현재는 사용 안 하지만 남겨둠)

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return _buildNoPermissionScaffold('로그인이 필요합니다');
    }

    return StreamBuilder<DocumentSnapshot>(
      stream:
      FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildNoPermissionScaffold('사용자 정보가 없습니다');
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final isAdmin = data['admin'] == true;

        if (!isAdmin) {
          return _buildNoPermissionScaffold('관리자 권한이 없습니다');
        }

        return _buildAdminDashboard(context, theme);
      },
    );
  }

  Widget _buildNoPermissionScaffold(String message) {
    return Scaffold(
      appBar: CommonAppBar(title: '접근 불가', showBackButton: true),
      body: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAdminDashboard(BuildContext context, ThemeData theme) {
    return Scaffold(
      appBar: CommonAppBar(title: 'ADMIN', showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -------------------------
          // 공지·뉴스·스폰서·사진
          // -------------------------
          _buildSection(
            context,
            title: '공지·뉴스·스폰서·사진',
            items: [
              _buildItem(
                context,
                icon: Icons.campaign,
                title: '공지 등록',
                subtitle: '공지 작성·수정·삭제·링크',
                route: RouteConstants.noticeForm,
              ),
              _buildItem(
                context,
                icon: Icons.article,
                title: '뉴스 등록',
                subtitle: '뉴스 작성·수정·삭제·링크',
                route: RouteConstants.newsForm,
              ),
              _buildItem(
                context,
                icon: Icons.image,
                title: '스폰서 배너 등록',
                subtitle: '스폰서 등록·수정·삭제·링크',
                route: RouteConstants.sponsorForm,
              ),
              _buildItem(
                context,
                icon: Icons.photo_library,
                title: '대회 사진 등록',
                subtitle: '대회 사진 등록·수정·삭제·링크',
                route: RouteConstants.competitionPhotosForm,
              ),
              // 🔥 [추가] 신규 매거진 등록 메뉴
              _buildItem(
                context,
                icon: Icons.auto_stories,
                title: '다트 매거진 관리 (신규)',
                subtitle: '한국/해외 매거진 통합 관리 및 영구 삭제',
                route: RouteConstants.magazineForm,
              ),
              _buildItem(
                context,
                icon: Icons.chat_outlined,
                title: '라이브 톡 전광판 공지',
                subtitle: '전광판 상단 띠 공지 실시간 수정',
                route: RouteConstants.adminChatConfig, // 방금 만든 라우트
              ),
            ],
          ),
          const SizedBox(height: 16),

          // -------------------------
          // 포인트 관리
          // -------------------------
          _buildSection(
            context,
            title: '포인트 관리',
            items: [
              _buildItem(
                context,
                icon: Icons.add_circle,
                title: '포인트 수동 부여',
                subtitle: '스틸리그 포인트 부여·등록',
                route: RouteConstants.pointAward,
              ),
              _buildItem(
                context,
                icon: Icons.list_alt,
                title: '포인트 내역 관리',
                subtitle: '포인트 내역 수정·삭제',
                route: RouteConstants.pointAwardList,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // -------------------------
          // 스틸리그 경기
          // -------------------------
          _buildSection(
            context,
            title: '스틸리그 경기',
            items: [
              _buildItem(
                context,
                icon: Icons.sports_esports,
                title: '경기 등록',
                subtitle: '스틸리그 경기 일정 등록·예정·종료',
                route: RouteConstants.eventCreate,
              ),
              _buildItem(
                context,
                icon: Icons.list_alt,
                title: '경기 관리',
                subtitle: '스틸리그 경기 삭제·재등록',
                route: RouteConstants.eventList,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // -------------------------
          // 공식 일정 관리 (★ 신규 추가)
          // -------------------------
          _buildSection(
            context,
            title: '공식 일정 관리',
            items: [
              _buildItem(
                context,
                icon: Icons.calendar_month,
                title: '공식 일정 등록', // 여기에 title이 잘 들어가 있는지 확인
                subtitle: '국내·해외·리그 기간별 바(Bar) 일정 등록',
                route: '/admin/official-calendar/create',
              ),
            ],
          ),

          _buildSection(
            context,
            title: '퀵 노티스 관리',
            items: [
              _buildItem(
                context,
                icon: Icons.campaign_rounded, // 아이콘을 campaign으로 바꾸면 더 직관적입니다
                title: '퀵 노티스 관리', // 👈 이 줄이 빠져서 에러가 났을 거예요! 추가하세요.
                subtitle: '홈 화면 하단 흐르는 한 줄 공지 관리',
                route: RouteConstants.adminQuickNotice,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // -------------------------
          // 스틸리그 선발 (★ 새로 추가)
          // -------------------------
          _buildSection(
            context,
            title: '스틸리그 선발',
            items: [
              _buildItem(
                context,
                icon: Icons.stars,
                title: '선발 선수 관리',
                subtitle: '시즌별 남/여 대표 8명 설정',
                route: RouteConstants.selectionPlayersAdmin, // 새 라우트
              ),
            ],
          ),
          const SizedBox(height: 16),

          // -------------------------
          // KDF 정회원
          // -------------------------
          _buildSection(
            context,
            title: 'KDF 정회원',
            items: [
              _buildItem(
                context,
                icon: Icons.card_membership,
                title: '정회원 등록',
                subtitle: 'KDF 정회원 등록·사진 등록',
                route: RouteConstants.memberRegister,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // -------------------------
          // 버그/신고 관리
          // -------------------------
          _buildSection(
            context,
            title: '버그/신고 관리',
            items: [
              _buildItem(
                context,
                icon: Icons.bug_report,
                title: '신고 내역 확인',
                subtitle: '사용자 신고 확인 및 처리',
                route: RouteConstants.adminReportList,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // -------------------------
          // 사용자 차단 관리 (★ 새로 추가)
          // -------------------------
          _buildSection(
            context,
            title: '사용자 차단 관리',
            items: [
              _buildItem(
                context,
                icon: Icons.person_off,
                title: '블랙리스트 통합 관리', // 명칭 통합
                subtitle: '누적 차단 횟수 확인 및 유저 정지/해제',
                route: RouteConstants.adminBlockManage,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 시스템 관리 (★ 새로 추가)
          // -------------------------
          _buildSection(
            context,
            title: '시스템 관리',
            items: [
              _buildItem(
                context,
                icon: Icons.cleaning_services,
                title: '데이터 소멸 관리',
                subtitle: '탈퇴 유저의 찌꺼기 및 흔적 완전 파쇄',
                route: RouteConstants.adminHardCleanup, // 새로 등록한 라우트
              ),
            ],
          ),

          // -------------------------
          // 회원 관리
          // -------------------------
          _buildSection(
            context,
            title: '회원 관리',
            items: [
              _buildItem(
                context,
                icon: Icons.people,
                title: '회원 목록 & 배지 부여',
                subtitle: '모든 회원 확인 및 체크아웃 배지 수동 부여',
                route: RouteConstants.adminMemberList,
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, {
        required String title,
        required List<Widget> items,
      }) {
    final theme = Theme.of(context);

    return AppCard(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          // 섹션 아이템들
          Column(
            children: List.generate(items.length, (i) {
              return Column(
                children: [
                  items[i],
                  if (i < items.length - 1)
                    const Divider(
                      height: 1,
                      indent: 68,
                      endIndent: 16,
                    ),
                ],
              );
            }),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required String route,
      }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
