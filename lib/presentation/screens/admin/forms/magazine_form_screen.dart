import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/core/constants/route_constants.dart';

class MagazineFormScreen extends StatefulWidget {
  const MagazineFormScreen({super.key});

  @override
  State<MagazineFormScreen> createState() => _MagazineFormScreenState();
}

class _MagazineFormScreenState extends State<MagazineFormScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  File? _image;
  String? _existingImageUrl;
  String? _editingDocId;

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _actionUrlController = TextEditingController();

  String _category = 'magazine_ko';
  String _actionType = 'link';
  String _selectedRoute = RouteConstants.arenaHome;
  String _listFilter = 'all';

  bool _isLoading = false;
  final picker = ImagePicker();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  /* ────────────────────────── 🖼️ 이미지 판독 헬퍼 ────────────────────────── */

  // ✅ 네트워크 이미지와 어셋 이미지를 구분하여 빌드하는 함수
  Widget _buildMagazineImage(String? imageUrl, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width, height: height, color: Colors.grey[100],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    if (imageUrl.startsWith('http')) {
      // 인터넷 주소인 경우
      return Image.network(
        imageUrl,
        width: width, height: height, fit: fit,
        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(width, height),
      );
    } else {
      // assets/images/... 경로인 경우
      return Image.asset(
        imageUrl,
        width: width, height: height, fit: fit,
        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(width, height),
      );
    }
  }

  Widget _buildErrorPlaceholder(double? w, double? h) {
    return Container(
      width: w, height: h, color: Colors.grey[100],
      child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        appBar: CommonAppBar(
          title: _editingDocId == null ? '매거진 관리' : '매거진 수정 중',
          showBackButton: true,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.edit), text: '등록/수정'),
              Tab(icon: Icon(Icons.list), text: '목록 관리'),
            ],
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.colorScheme.primary,
            padding: const EdgeInsets.only(bottom: 8),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInputTab(theme),
            _buildListTab(theme),
          ],
        ),
      ),
    );
  }

  /* ────────────────────────── 1번 탭: 입력/수정 폼 ────────────────────────── */
  Widget _buildInputTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _buildCategoryChip('magazine_ko', '🇰🇷 한국 매거진')),
              const SizedBox(width: 8),
              Expanded(child: _buildCategoryChip('magazine_global', '🌏 해외 소식')),
            ],
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
              ),
              child: _image != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_image!, fit: BoxFit.cover))
                  : (_existingImageUrl != null
                  ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildMagazineImage(_existingImageUrl, width: double.infinity, height: 180) // ✅ 수정됨
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 40, color: theme.colorScheme.primary),
                  const SizedBox(height: 8),
                  const Text('사진 선택 (필수)'),
                ],
              )),
            ),
          ),
          const SizedBox(height: 20),

          _buildTextField(_titleController, '매거진 제목', Icons.title),
          const SizedBox(height: 16),

          _buildTextField(_contentController, '본문 내용 (상세 설명)', Icons.description, maxLines: 4),
          const SizedBox(height: 24),

          _buildActionSelector(theme),
          const SizedBox(height: 32),

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
            onPressed: _saveMagazine,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(_editingDocId == null ? '매거진 등록하기' : '수정 완료',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),

          if (_editingDocId != null)
            TextButton(
              onPressed: _clearForm,
              child: const Text('수정 취소하고 새로 만들기', style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  /* ────────────────────────── 2번 탭: 목록 관리 ────────────────────────── */
  Widget _buildListTab(ThemeData theme) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildFilterChip('all', '전체'),
              const SizedBox(width: 8),
              _buildFilterChip('pending', '⏳ 대기 중'),
              const SizedBox(width: 8),
              _buildFilterChip('ko', '🇰🇷 한국'),
              const SizedBox(width: 8),
              _buildFilterChip('global', '🌏 해외'),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('magazines')
                .orderBy('isActive', descending: true)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final allDocs = snapshot.data!.docs;
              final docs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (_listFilter == 'pending') return (data['isActive'] ?? false) == false;
                if (_listFilter == 'ko') return data['category'] == 'magazine_ko';
                if (_listFilter == 'global') return data['category'] == 'magazine_global';
                return true;
              }).toList();

              if (docs.isEmpty) return const Center(child: Text('표시할 매거진이 없습니다.'));

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final id = doc.id;
                  final bool isActive = data['isActive'] ?? false;
                  final String contentSummary = data['content'] ?? '내용 없음';

                  return AppCard(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildMagazineImage(data['imageUrl'], width: 60, height: 60), // ✅ 수정됨
                          ),
                          Positioned(
                            top: 0, left: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(4),
                                  )
                              ),
                              child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                          data['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            contentSummary,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                    data['category'] == 'magazine_ko' ? '🇰🇷 한국' : '🌏 해외',
                                    style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                    isActive ? "● 게시 중" : "○ 대기 중",
                                    style: TextStyle(color: isActive ? Colors.green : Colors.grey, fontSize: 11),
                                    overflow: TextOverflow.ellipsis
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 30,
                            child: Switch(
                              value: isActive,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (val) {
                                _firestore.collection('magazines').doc(id).update({'isActive': val});
                              },
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => _startEditing(id, data),
                                child: const Icon(Icons.edit_note, color: Colors.blue, size: 22),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _deleteMagazine(id, data['imageUrl']),
                                child: const Icon(Icons.delete_sweep_outlined, color: Colors.red, size: 22),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /* ────────────────────────── 컴포넌트 ────────────────────────── */

  Widget _buildCategoryChip(String value, String label) {
    return ChoiceChip(
      label: Container(width: double.infinity, alignment: Alignment.center, child: Text(label)),
      selected: _category == value,
      onSelected: (b) => setState(() => _category = value),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _listFilter == value,
      onSelected: (selected) {
        if (selected) setState(() => _listFilter = value);
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
      ),
    );
  }

  Widget _buildActionSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('이동 경로 설정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildRadioOption('none', '없음'),
            _buildRadioOption('link', '외부 링크'),
            _buildRadioOption('internal', '앱 내부'),
          ],
        ),
        const SizedBox(height: 8),
        if (_actionType == 'link')
          _buildTextField(_actionUrlController, 'URL 입력', Icons.link)
        else if (_actionType == 'internal')
          DropdownButtonFormField<String>(
            value: _selectedRoute,
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.near_me)),
            items: const [
              DropdownMenuItem(value: RouteConstants.arenaHome, child: Text('아레나(토너먼트) 홈')),
              DropdownMenuItem(value: RouteConstants.steelLeagueRanking, child: Text('스틸리그 랭킹')),
              DropdownMenuItem(value: RouteConstants.community, child: Text('커뮤니티 홈')),
            ],
            onChanged: (v) => setState(() => _selectedRoute = v!),
          ),
      ],
    );
  }

  Widget _buildRadioOption(String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _actionType,
          onChanged: (v) => setState(() => _actionType = v!),
          visualDensity: VisualDensity.compact,
        ),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  /* ────────────────────────── 로직 ────────────────────────── */

  void _startEditing(String id, Map<String, dynamic> data) {
    setState(() {
      _editingDocId = id;
      _titleController.text = data['title'] ?? '';
      _contentController.text = data['content'] ?? '';
      _category = data['category'] ?? 'magazine_ko';
      _actionType = data['actionType'] ?? 'link';
      if (_actionType == 'link') {
        _actionUrlController.text = data['actionUrl'] ?? '';
      } else {
        _selectedRoute = data['actionUrl'] ?? RouteConstants.arenaHome;
      }
      _existingImageUrl = data['imageUrl'];
      _image = null;
      _tabController.animateTo(0);
    });
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 80);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _saveMagazine() async {
    if (_titleController.text.trim().isEmpty || (_image == null && _existingImageUrl == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("제목과 이미지를 확인해주세요.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String finalImageUrl = _existingImageUrl ?? '';

      if (_image != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final ref = _storage.ref().child('magazines').child('$timestamp.jpg');
        await ref.putFile(_image!);
        finalImageUrl = await ref.getDownloadURL();

        // ✅ 기존 이미지가 진짜 '파일'일 때만 스토리지에서 삭제
        if (_existingImageUrl != null && _existingImageUrl!.startsWith('http')) {
          try { await _storage.refFromURL(_existingImageUrl!).delete(); } catch (_) {}
        }
      }

      String finalActionUrl = '';
      if (_actionType == 'link') {
        finalActionUrl = _actionUrlController.text.trim();
      } else if (_actionType == 'internal') {
        finalActionUrl = _selectedRoute;
      }

      final data = {
        'category': _category,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'imageUrl': finalImageUrl,
        'actionType': _actionType,
        'actionUrl': finalActionUrl,
        'isActive': true,
        'createdAt': _editingDocId == null ? FieldValue.serverTimestamp() : DateTime.now(),
      };

      if (_editingDocId == null) {
        await _firestore.collection('magazines').add(data);
      } else {
        await _firestore.collection('magazines').doc(_editingDocId).update(data);
      }

      _clearForm();
      _tabController.animateTo(1);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("완료되었습니다!"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _deleteMagazine(String docId, String? imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('영구 삭제'),
        content: const Text('데이터와 이미지를 모두 파쇄합니다. 복구 불가합니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('확인', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      // ✅ 진짜 인터넷 파일(http)인 경우에만 스토리지 삭제 시도
      if (imageUrl != null && imageUrl.startsWith('http')) {
        try {
          if (imageUrl.contains('firebasestorage')) {
            await _storage.refFromURL(imageUrl).delete();
          }
        } catch (e) {
          debugPrint("이미지 삭제 실패: $e");
        }
      }
      await _firestore.collection('magazines').doc(docId).delete();
    }
  }

  void _clearForm() {
    setState(() {
      _editingDocId = null;
      _existingImageUrl = null;
      _image = null;
      _titleController.clear();
      _contentController.clear();
      _actionUrlController.clear();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _actionUrlController.dispose();
    super.dispose();
  }
}