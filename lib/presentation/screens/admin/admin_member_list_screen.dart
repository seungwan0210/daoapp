// lib/presentation/screens/admin/admin_member_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/core/constants/badge_constants.dart';
import 'package:daoapp/core/utils/badge_utils.dart';

class AdminMemberListScreen extends StatefulWidget {
  const AdminMemberListScreen({super.key});

  @override
  State<AdminMemberListScreen> createState() => _AdminMemberListScreenState();
}

class _AdminMemberListScreenState extends State<AdminMemberListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("회원 관리"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "전체"),
            Tab(text: "폰번호 있음"),
            Tab(text: "관리자 지정"),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(filter: 'all'),
                _buildUserList(filter: 'phone_yes'),
                _buildUserList(filter: 'admin_reg'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '이름 또는 이메일 검색',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          )
              : null,
        ),
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
      ),
    );
  }

  Widget _buildUserList({required String filter}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("회원이 없습니다."));
        }

        var docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['koreanName'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          final phone = (data['phoneNumber'] ?? '').toString().trim();
          final gender = data['gender'];

          if (_searchQuery.isNotEmpty && !name.contains(_searchQuery) && !email.contains(_searchQuery)) {
            return false;
          }

          if (filter == 'phone_yes' && phone.isEmpty) return false;
          if (filter == 'admin_reg' && gender == null) return false;

          return true;
        }).toList();

        docs.sort((a, b) {
          final aName = (a['koreanName'] ?? '').toString();
          final bName = (b['koreanName'] ?? '').toString();
          return aName.compareTo(bName);
        });

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final uid = doc.id;
            return _buildUserCard(uid: uid, data: data);
          },
        );
      },
    );
  }

  Widget _buildUserCard({required String uid, required Map<String, dynamic> data}) {
    final name = data['koreanName'] ?? '이름 없음';
    final email = (data['email'] ?? '').toString();
    final phone = (data['phoneNumber'] ?? '').toString().trim();
    final photoUrl = data['profileImageUrl'] as String?;

    final badgesMap = BadgeUtils.extractBadges(data);
    final monthlyKey = BadgeUtils.getLatestMonthlyBadge(badgesMap);
    final adminKey = BadgeUtils.getLatestAdminBadge(badgesMap);

    final hasMonthly = monthlyKey != null;
    final hasAdmin = adminKey != null;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: photoUrl?.isNotEmpty == true ? NetworkImage(photoUrl!) : null,
              child: photoUrl?.isNotEmpty != true ? const Icon(Icons.person, size: 32) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  if (email.isNotEmpty) Text(email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (phone.isNotEmpty) Text(phone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (monthlyKey != null) _buildBadgeChip(context, uid, monthlyKey, isMonthly: true),
                      if (adminKey != null) _buildBadgeChip(context, uid, adminKey, isMonthly: false),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.emoji_events_outlined),
              tooltip: '배지 관리',
              onPressed: () => _openBadgeManageSheet(context, uid: uid, hasMonthly: hasMonthly, hasAdmin: hasAdmin),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeChip(BuildContext context, String uid, String key, {required bool isMonthly}) {
    final label = isMonthly ? '월간' : '관리자';
    final tooltip = BadgeUtils.getBadgeTooltip(key);

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => _showBadgeMenu(context, uid, key, isMonthly),
        child: Chip(
          avatar: BadgeWidget(badgeKey: key, size: 16),
          label: Text('$label: ${tooltip.split(' ').last}', style: const TextStyle(fontSize: 11)),
          backgroundColor: Colors.grey[100],
          padding: const EdgeInsets.symmetric(horizontal: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  void _showBadgeMenu(BuildContext context, String uid, String key, bool isMonthly) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('수정'),
              onTap: () {
                Navigator.pop(ctx);
                if (isMonthly) {
                  _showEditMonthlyBadgeDialog(context, uid);
                } else {
                  _showEditAdminBadgeDialog(context, uid);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('삭제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _removeBadge(context, uid, key, isMonthly);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openBadgeManageSheet(BuildContext context, {required String uid, required bool hasMonthly, required bool hasAdmin}) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('월간 배지 부여/수정'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditMonthlyBadgeDialog(context, uid);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('관리자 배지 부여/수정'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditAdminBadgeDialog(context, uid);
              },
            ),
            if (hasMonthly)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('월간 배지 모두 삭제', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _removeAllMonthlyBadges(context, uid);
                },
              ),
            if (hasAdmin)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('관리자 배지 모두 삭제', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _removeAllAdminBadges(context, uid);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeBadge(BuildContext context, String uid, String key, bool isMonthly) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final batch = FirebaseFirestore.instance.batch();
      batch.update(userRef, {'badges.$key': FieldValue.delete()});
      if (isMonthly) {
        batch.update(userRef, {'lastMonthlyBadge': FieldValue.delete()});
      }
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('배지 삭제 완료!'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _removeAllMonthlyBadges(BuildContext context, String uid) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final snap = await userRef.get();
      final data = snap.data() ?? {};
      final badges = data['badges'] as Map<String, dynamic>? ?? {};
      final batch = FirebaseFirestore.instance.batch();
      badges.forEach((k, _) {
        if (k.startsWith('monthly_')) {
          batch.update(userRef, {'badges.$k': FieldValue.delete()});
        }
      });
      batch.update(userRef, {'lastMonthlyBadge': FieldValue.delete()});
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('월간 배지 삭제 완료!'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _removeAllAdminBadges(BuildContext context, String uid) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final snap = await userRef.get();
      final data = snap.data() ?? {};
      final badges = data['badges'] as Map<String, dynamic>? ?? {};
      final batch = FirebaseFirestore.instance.batch();
      badges.forEach((k, _) {
        if (k.startsWith('admin_')) {
          batch.update(userRef, {'badges.$k': FieldValue.delete()});
        }
      });
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('관리자 배지 삭제 완료!'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showEditMonthlyBadgeDialog(BuildContext context, String uid) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 9));
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$year년 $month월 배지 수정'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: BadgeConstants.allBadges.map((b) {
              final key = 'monthly_${year}_${month}_$b';
              return ListTile(
                leading: BadgeWidget(badgeKey: key, size: 24),
                title: Text(BadgeUtils.getBadgeTooltip(key).split(' ').last),
                onTap: () {
                  Navigator.pop(ctx);
                  _grantMonthlyBadge(context, uid, b);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
        ],
      ),
    );
  }

  void _showEditAdminBadgeDialog(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('관리자 배지 수정'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: BadgeConstants.allBadges.map((b) {
              final key = 'admin_$b';
              return ListTile(
                leading: BadgeWidget(badgeKey: key, size: 24),
                title: Text(BadgeUtils.getBadgeTooltip(key).split(' ').last),
                onTap: () {
                  Navigator.pop(ctx);
                  _grantAdminBadge(context, uid, b);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
        ],
      ),
    );
  }

  Future<void> _grantAdminBadge(BuildContext context, String uid, String badge) async {
    final key = 'admin_$badge';
    try {
      final batch = FirebaseFirestore.instance.batch();
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final snap = await userRef.get();
      final data = snap.data() ?? {};
      final badges = data['badges'] as Map<String, dynamic>? ?? {};
      badges.forEach((k, _) {
        if (k.startsWith('admin_')) {
          batch.update(userRef, {'badges.$k': FieldValue.delete()});
        }
      });
      batch.update(userRef, {'badges.$key': true});
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$badge 배지 부여 완료!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _grantMonthlyBadge(BuildContext context, String uid, String badge) async {
    final now = DateTime.now().toUtc().add(const Duration(hours: 9));
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final key = 'monthly_${year}_${month}_$badge';

    try {
      final batch = FirebaseFirestore.instance.batch();
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final snap = await userRef.get();
      final data = snap.data() ?? {};
      final badges = data['badges'] as Map<String, dynamic>? ?? {};
      badges.forEach((k, _) {
        if (k.startsWith('monthly_')) {
          batch.update(userRef, {'badges.$k': FieldValue.delete()});
        }
      });
      batch.update(userRef, {
        'badges.$key': true,
        'lastMonthlyBadge': '$year년 $month월 ${BadgeUtils.getBadgeTooltip(key).split(' ').last}(수동)',
      });
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$badge 월간 배지 부여 완료!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('월간 배지 부여 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }
}