// lib/presentation/screens/admin/admin_member_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';

class AdminMemberListScreen extends StatefulWidget {
  const AdminMemberListScreen({super.key});

  @override
  State<AdminMemberListScreen> createState() => _AdminMemberListScreenState();
}

class _AdminMemberListScreenState extends State<AdminMemberListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all'; // all, phone_yes, phone_no

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: "회원 관리", showBackButton: true),
      body: Column(
        children: [
          _buildSearchFilter(),
          const SizedBox(height: 8),
          Expanded(child: _buildUserList()),
        ],
      ),
    );
  }

  // ==================== 검색 + 필터 ====================
  Widget _buildSearchFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // 검색창 (이름 + 이메일)
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '이름 또는 이메일 검색',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
          const SizedBox(height: 8),
          // 필터: 전체 / 폰번호 있음 / 폰번호 없음
          Row(
            children: [
              _filterChip('전체', 'all'),
              const SizedBox(width: 8),
              _filterChip('폰번호 있음', 'phone_yes'),
              const SizedBox(width: 8),
              _filterChip('폰번호 없음', 'phone_no'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterType = value),
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  // ==================== 유저 리스트 ====================
  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("회원이 없습니다."));
        }

        var docs = snapshot.data!.docs;

        // 필터링
        docs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['koreanName'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          final phoneNumber = (data['phoneNumber'] ?? '').toString().trim();
          final hasPhone = phoneNumber.isNotEmpty;

          // 검색어 (이름 / 이메일)
          if (_searchQuery.isNotEmpty &&
              !name.contains(_searchQuery) &&
              !email.contains(_searchQuery)) {
            return false;
          }

          // 폰번호 필터
          if (_filterType == 'phone_yes' && !hasPhone) return false;
          if (_filterType == 'phone_no' && hasPhone) return false;

          return true;
        }).toList();

        // 이름순 정렬
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aName = (aData['koreanName'] ?? '').toString();
          final bName = (bData['koreanName'] ?? '').toString();
          return aName.compareTo(bName);
        });

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final uid = doc.id;

            final name = data['koreanName'] ?? '이름 없음';
            final email = (data['email'] ?? '').toString();
            final phoneNumber = (data['phoneNumber'] ?? '').toString().trim();
            final hasPhone = phoneNumber.isNotEmpty;
            final photoUrl = data['profileImageUrl'] as String?;
            final isAdminReg = data['adminRegistered'] == true;

            // === 관리자 수동 배지: badges.admin_XXX 중 하나 ===
            final badgesMap = data['badges'] as Map<String, dynamic>? ?? {};
            String? adminBadgeKey;
            if (badgesMap.isNotEmpty) {
              final adminKeys = badgesMap.entries
                  .where((e) => e.key.startsWith('admin_') && e.value == true)
                  .map((e) => e.key)
                  .toList();
              if (adminKeys.isNotEmpty) {
                adminBadgeKey = adminKeys.first; // 일단 한 개만 사용
              }
            }

            return AppCard(
              child: ListTile(
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: photoUrl?.isNotEmpty == true
                          ? NetworkImage(photoUrl!)
                          : null,
                      child: photoUrl?.isNotEmpty != true
                          ? const Icon(Icons.person, size: 28)
                          : null,
                    ),
                    if (adminBadgeKey != null)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: BadgeWidget(badgeKey: adminBadgeKey, size: 24),
                      ),
                  ],
                ),
                title: Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    if (isAdminReg)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '관리자 등록',
                          style: TextStyle(fontSize: 10, color: Colors.blue),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email.isNotEmpty ? email : '이메일 없음'),
                    if (hasPhone) ...[
                      const SizedBox(height: 2),
                      Text('폰번호: $phoneNumber', style: const TextStyle(fontSize: 11)),
                    ],
                    const SizedBox(height: 2),
                    if (adminBadgeKey != null)
                      Text(
                        '현재 배지(관리자): ${_badgeLabelFromAdminKey(adminBadgeKey)}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      )
                    else
                      const Text(
                        '현재 배지(관리자): 없음',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) {
                    if (action.startsWith('badge_')) {
                      final badge = action.substring('badge_'.length);
                      _grantAdminBadge(context, uid, badge);
                    } else if (action == 'remove_badge') {
                      _removeAdminBadge(context, uid);
                    }
                  },
                  itemBuilder: (context) => [
                    ..._adminBadgeMenuItems(),
                    if (adminBadgeKey != null)
                      const PopupMenuItem(
                        value: 'remove_badge',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20),
                            SizedBox(width: 8),
                            Text('관리자 배지 삭제'),
                          ],
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
  }

  // ==================== 관리자 수동 배지 관련 ====================

  /// 관리자가 수동으로 줄 수 있는 배지 목록
  /// 키 형식: badges.admin_pro, badges.admin_emerald ...
  List<PopupMenuEntry<String>> _adminBadgeMenuItems() {
    const badges = [
      'pro', 'emerald', 'diamond',
      'platinum1', 'platinum2',
      'gold1', 'gold2',
      'silver1', 'silver2',
      'bronze1', 'bronze2', 'bronze3',
    ];

    return badges.map((b) {
      final key = 'admin_$b';
      return PopupMenuItem(
        value: 'badge_$b',
        child: Row(
          children: [
            BadgeWidget(badgeKey: key, size: 20),
            const SizedBox(width: 8),
            Text(_badgeLabel(b)),
          ],
        ),
      );
    }).toList();
  }

  /// admin_pro → Pro 같은 라벨
  String _badgeLabelFromAdminKey(String key) {
    // key: admin_pro
    if (!key.startsWith('admin_')) return key;
    final badge = key.substring('admin_'.length);
    return _badgeLabel(badge);
  }

  String _badgeLabel(String badge) {
    const map = {
      'pro': 'Pro',
      'emerald': 'Emerald',
      'diamond': 'Diamond',
      'platinum1': 'Platinum 1',
      'platinum2': 'Platinum 2',
      'gold1': 'Gold 1',
      'gold2': 'Gold 2',
      'silver1': 'Silver 1',
      'silver2': 'Silver 2',
      'bronze1': 'Bronze 1',
      'bronze2': 'Bronze 2',
      'bronze3': 'Bronze 3',
    };
    return map[badge] ?? badge;
  }

  /// 관리자 수동 배지 부여
  /// → badges.admin_* 만 건드림 (월간 배지는 건드리지 않음)
  Future<void> _grantAdminBadge(BuildContext context, String uid, String badge) async {
    final key = 'admin_$badge';

    try {
      final batch = FirebaseFirestore.instance.batch();
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      // 1. 기존 관리자 배지 삭제 (admin_ 로 시작하는 키만)
      final snap = await userRef.get();
      final data = snap.data() ?? {};
      final badges = data['badges'] as Map<String, dynamic>? ?? {};
      badges.forEach((k, _) {
        if (k.startsWith('admin_')) {
          batch.set(
            userRef,
            {'badges.$k': FieldValue.delete()},
            SetOptions(merge: true),
          );
        }
      });

      // 2. 새 관리자 배지 부여
      batch.set(
        userRef,
        {'badges.$key': true},
        SetOptions(merge: true),
      );

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_badgeLabel(badge)} 배지(관리자) 부여 완료!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// 관리자 수동 배지 삭제 (admin_ 로 시작하는 키만)
  Future<void> _removeAdminBadge(BuildContext context, String uid) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      final snap = await userRef.get();
      final data = snap.data() ?? {};
      final badges = data['badges'] as Map<String, dynamic>? ?? {};
      badges.forEach((k, _) {
        if (k.startsWith('admin_')) {
          batch.set(
            userRef,
            {'badges.$k': FieldValue.delete()},
            SetOptions(merge: true),
          );
        }
      });

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('관리자 배지 삭제 완료!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
