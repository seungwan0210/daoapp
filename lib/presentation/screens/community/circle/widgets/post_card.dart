// lib/presentation/screens/community/circle/widgets/post_card.dart (또는 해당 파일 경로)
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_linkify/flutter_linkify.dart' as fl;
import 'package:linkify/linkify.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:daoapp/presentation/screens/community/circle/widgets/like_button.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/comment_button.dart';
import 'package:daoapp/presentation/screens/community/circle/widgets/comment_preview.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/providers/app_providers.dart';
import 'package:daoapp/presentation/widgets/user_profile_dialog.dart';
import 'package:daoapp/presentation/widgets/badge_widget.dart';
import 'package:daoapp/core/utils/badge_utils.dart';
import 'package:daoapp/l10n/app_localizations.dart';
import 'package:daoapp/presentation/providers/locale_provider.dart'; // 🔹 추가
import 'package:daoapp/core/services/translation_service.dart'; // 🔹 추가

class PostCard extends ConsumerStatefulWidget {
  final QueryDocumentSnapshot doc;
  final String? currentUserId;
  final void Function(double)? onHeightCalculated;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  final Map<String, String?>? barrelData;
  final String? monthlyBadge;
  final String? adminBadge;
  final int? currentRank;

  final Object? heroTag;

  const PostCard({
    super.key,
    required this.doc,
    this.currentUserId,
    this.onHeightCalculated,
    this.onEdit,
    this.onDelete,
    this.barrelData,
    this.monthlyBadge,
    this.adminBadge,
    this.currentRank,
    this.heroTag,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _isContentExpanded = false;
  late final GlobalKey _cardKey = GlobalKey();
  int _currentPage = 0;

  // 🌐 번역 관련 상태 변수 추가
  bool _isTranslated = false;
  String? _translatedText;
  bool _isTranslating = false;

  void _showFullImage(BuildContext context, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.white),
              ),
            ),
            Positioned(
              top: MediaQuery.of(ctx).padding.top + 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const String _fallbackImageAsset = 'assets/images/circle_main.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportHeight());
  }

  void _reportHeight() {
    final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && widget.onHeightCalculated != null) {
      widget.onHeightCalculated!(box.size.height);
    }
  }

  // 🌐 번역 실행 함수 추가
  Future<void> _handleTranslate(String originalText) async {
    final s = AppLocalizations.of(context)!;

    if (_isTranslated) {
      setState(() => _isTranslated = false);
      return;
    }

    if (_translatedText != null) {
      setState(() => _isTranslated = true);
      return;
    }

    setState(() => _isTranslating = true);

    // 홈스크린에서 선택된 언어 코드 가져오기 (ko, en, ja, zh_Hans 등)
    final targetLang = ref.read(localeProvider).languageCode;

    final result = await TranslationService.translateText(originalText, targetLang);

    if (mounted) {
      if (result != null) {
        setState(() {
          _translatedText = result;
          _isTranslated = true;
          _isTranslating = false;
        });
      } else {
        setState(() => _isTranslating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.circle_translate_fail)),
        );
      }
    }
  }

  List<String> _extractImageUrls(Map<String, dynamic> data) {
    final dynamic images = data['imageUrls'];
    if (images is List && images.isNotEmpty) {
      return List<String>.from(images);
    }
    final p = (data['photoUrl'] as String?)?.trim();
    if (p != null && p.isNotEmpty) return [p];
    return [];
  }

  DocumentReference<Map<String, dynamic>> _blockedDocRef({
    required String blockerUid,
    required String blockedUid,
  }) {
    return FirebaseFirestore.instance.collection('users').doc(blockerUid).collection('blockedUsers').doc(blockedUid);
  }

  Future<void> _createReport({
    required String title,
    required String content,
    required String type,
    required String reporterId,
    required String reporterName,
    String? reporterEmail,
    String? targetUserId,
    String? targetUserName,
    String? postId,
    String? imageUrl,
    String? reason,
    String? detail,
  }) async {
    await FirebaseFirestore.instance.collection('reports').add({
      'title': title,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'processed': false,
      'processedAt': null,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reporterEmail': reporterEmail,
      'type': type,
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'postId': postId,
      'imageUrl': imageUrl,
      'reason': reason,
      'detail': (detail ?? '').trim(),
    });
  }

  Future<Map<String, String?>> _getReporterInfo(String uid, AppLocalizations s) async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!snap.exists || snap.data() == null) return {'name': s.member_list_no_name, 'email': null};
      final data = snap.data()!;
      final name = data['koreanName']?.toString().trim();
      final email = data['email']?.toString().trim();
      return {'name': (name?.isNotEmpty == true) ? name! : s.member_list_no_name, 'email': email};
    } catch (_) {
      return {'name': s.member_list_no_name, 'email': null};
    }
  }

  Future<void> _confirmAndBlock({
    required String blockedUid,
    required String blockedName,
    required String postId,
    String? postImageUrl,
  }) async {
    final s = AppLocalizations.of(context)!;
    final me = widget.currentUserId;
    if (me == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(s.post_card_block_title, style: const TextStyle(color: Colors.white)),
        content: Text(s.post_card_block_body(blockedName), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.common_cancel, style: const TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.post_card_block, style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(me)
          .collection('blockedUsers')
          .doc(blockedUid)
          .set({
        'blockedUserId': blockedUid,
        'name': blockedName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final reporterInfo = await _getReporterInfo(me, s);
      await _createReport(
        title: '커뮤니티 차단 접수',
        content: '사용자가 "$blockedName" 를 차단했습니다.',
        type: 'community_block',
        reporterId: me,
        reporterName: reporterInfo['name']!,
        reporterEmail: reporterInfo['email'],
        targetUserId: blockedUid,
        targetUserName: blockedName,
        postId: postId,
        imageUrl: postImageUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.post_card_block_success(blockedName))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _openReportDialog({
    required String postId,
    required String reportedUid,
    required String reportedName,
    required String postContentPreview,
    String? postImageUrl,
  }) async {
    final s = AppLocalizations.of(context)!;
    final me = widget.currentUserId;
    if (me == null) return;

    final reasons = <String>[s.post_card_report_r1, s.post_card_report_r2, s.post_card_report_r3, s.post_card_report_r4, s.post_card_report_r5, s.post_card_report_r6];
    String selected = reasons.first;
    final detailCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(s.post_card_report_title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selected,
                items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => selected = v ?? selected),
                decoration: InputDecoration(labelText: s.post_card_report_reason, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: detailCtrl,
                maxLines: 3,
                decoration: InputDecoration(labelText: s.post_card_report_detail, border: const OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.common_cancel)),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.post_card_report)),
          ],
        ),
      ),
    );

    if (ok != true) {
      detailCtrl.dispose();
      return;
    }

    try {
      final reporterInfo = await _getReporterInfo(me, s);
      await _createReport(
        title: '커뮤니티 게시물 신고',
        content: '사유: $selected\n내용: $postContentPreview',
        type: 'community_post',
        reporterId: me,
        reporterName: reporterInfo['name']!,
        reporterEmail: reporterInfo['email'],
        targetUserId: reportedUid,
        targetUserName: reportedName,
        postId: postId,
        imageUrl: postImageUrl,
        reason: selected,
        detail: detailCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.post_card_report_success)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      detailCtrl.dispose();
    }
  }

  void _sharePostWithDeepLink(String postId, String content, AppLocalizations s) {
    final String deepLink = "https://daoapp-c0527.web.app/post?id=$postId";
    final previewContent = content.length > 100 ? "${content.substring(0, 100)}..." : content;
    final String shareMessage = s.post_card_share_msg(previewContent, deepLink);
    Share.share(shareMessage);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final data = widget.doc.data() as Map<String, dynamic>;
    final postId = widget.doc.id;

    final String? postUserId = (data['userId'] as String?)?.trim();
    final content = (data['content'] ?? '').toString();
    final likes = data['likes'] as int? ?? 0;
    final comments = data['comments'] as int? ?? 0;

    final imageUrls = _extractImageUrls(data);
    final isAuthor = postUserId != null && postUserId == widget.currentUserId;
    final isAdmin = ref.watch(isAdminProvider).when(data: (v) => v, loading: () => false, error: (_, __) => false);

    final canEdit = isAuthor && widget.onEdit != null;
    final canDelete = isAuthor || isAdmin;
    final bool isLongContent = content.length > 100 || content.contains('\n');

    final userStream = (postUserId == null) ? null : FirebaseFirestore.instance.collection('users').doc(postUserId).snapshots();
    final me = widget.currentUserId;
    final blockedStream = (me != null && postUserId != null && me != postUserId) ? _blockedDocRef(blockerUid: me, blockedUid: postUserId).snapshots() : null;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: blockedStream,
      builder: (context, blockedSnap) {
        if (blockedSnap.data?.exists ?? false) return const SizedBox.shrink();

        return Container(
          key: _cardKey,
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(color: theme.cardColor),
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: userStream,
            builder: (context, snap) {
              final userData = (snap.hasData && snap.data!.exists) ? (snap.data!.data() ?? {}) : {};
              final koreanName = (userData['koreanName']?.toString().isNotEmpty == true) ? userData['koreanName'] : (data['userName'] ?? s.member_list_no_name);
              final profileImageUrl = userData['profileImageUrl'] as String?;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, postUserId, koreanName, profileImageUrl, isAuthor, canEdit, canDelete, content, imageUrls, postId, s),
                  _buildImageSlider(imageUrls),
                  _buildActionBar(theme, postId, likes, comments, content, s),
                  if (content.isNotEmpty) _buildBodyContent(theme, koreanName, content, isLongContent, s),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: CommentPreview(postId: postId, currentUserId: widget.currentUserId),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildImageSlider(List<String> urls) {
    if (urls.isEmpty) {
      return ClipRRect(child: Image.asset(_fallbackImageAsset, width: double.infinity, height: 480, fit: BoxFit.cover));
    }
    return Container(
      height: 480,
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: urls.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showFullImage(context, urls[index]),
                child: Image.network(
                    urls[index],
                    width: double.infinity,
                    height: 480,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => Image.asset(_fallbackImageAsset, fit: BoxFit.cover)
                ),
              );
            },
          ),
          if (urls.length > 1)
            Positioned(
              top: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(16)),
                child: Text('${_currentPage + 1}/${urls.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, String? postUserId, String name, String? photo, bool isAuthor, bool canEdit, bool canDelete, String content, List<String> imageUrls, String postId, AppLocalizations s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: postUserId != null ? () => _showUserProfileDialog(postUserId, s) : null,
            child: _ProfileAvatar(
              radius: 20,
              primaryColor: theme.colorScheme.primaryContainer,
              photoUrl: photo,
              currentRank: widget.currentRank,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.primary), overflow: TextOverflow.ellipsis),
                Text(
                  AppDateUtils.formatRelativeTime(widget.doc['timestamp']?.toDate() ?? DateTime.now()),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (widget.currentUserId != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 22),
              onSelected: (v) async {
                final currentUrl = imageUrls.isNotEmpty ? imageUrls[_currentPage] : null;
                final preview = content.length > 50 ? '${content.substring(0, 50)}...' : content;
                if (v == 'share') { _sharePostWithDeepLink(postId, content, s); return; }
                if (v == 'edit') widget.onEdit?.call();
                if (v == 'delete') widget.onDelete?.call();
                if (postUserId == null) return;
                if (v == 'report') await _openReportDialog(postId: postId, reportedUid: postUserId, reportedName: name, postContentPreview: preview, postImageUrl: currentUrl);
                if (v == 'block') await _confirmAndBlock(blockedUid: postUserId, blockedName: name, postId: postId, postImageUrl: currentUrl);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'share', child: Text(s.post_card_share)),
                if (!isAuthor) ...[
                  PopupMenuItem(value: 'report', child: Text(s.post_card_report)),
                  PopupMenuItem(value: 'block', child: Text(s.post_card_block)),
                ],
                if (canEdit) PopupMenuItem(value: 'edit', child: Text(s.post_write_btn_edit)),
                if (canDelete) PopupMenuItem(value: 'delete', child: Text(s.common_delete, style: const TextStyle(color: Colors.red))),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionBar(ThemeData theme, String postId, int likes, int comments, String content, AppLocalizations s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          LikeButton(postId: postId, currentUserId: widget.currentUserId, likesCount: likes),
          const SizedBox(width: 16),
          CommentButton(postId: postId, commentsCount: comments),
          const SizedBox(width: 16),
          IconButton(icon: const Icon(Icons.send_outlined, size: 24), onPressed: () => _sharePostWithDeepLink(postId, content, s), color: theme.colorScheme.primary),
          // 🌐 번역 버튼 추가
          if (_isTranslating)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent)),
            )
          else
            TextButton(
              onPressed: () => _handleTranslate(content),
              child: Text(
                _isTranslated ? s.circle_translate_show_original : s.circle_translate_btn,
                style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
            ),
          const Spacer(),
          const Icon(Icons.bookmark_border, size: 24),
        ],
      ),
    );
  }

  Widget _buildBodyContent(ThemeData theme, String name, String content, bool isLong, AppLocalizations s) {
    // 🌐 번역 여부에 따라 보여줄 본문 선택
    final String currentContent = _isTranslated ? (_translatedText ?? content) : content;

    final int lineCount = '\n'.allMatches(currentContent).length + 1;
    final bool effectiveIsLong = lineCount >= 3 || currentContent.length > 40;
    String displayContent = currentContent;

    if (effectiveIsLong && !_isContentExpanded) {
      displayContent = currentContent.replaceAll('\n', '  ');
      if (displayContent.length > 35) displayContent = "${displayContent.substring(0, 35)}...";
    }
    final elements = linkify(displayContent, options: const fl.LinkifyOptions(humanize: false));

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: (!_isContentExpanded && effectiveIsLong) ? () => setState(() => _isContentExpanded = true) : null,
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87, letterSpacing: -0.3),
                children: [
                  TextSpan(text: "$name   ", style: const TextStyle(fontFamily: 'Pretendard', color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14.5)),
                  ...elements.map((element) {
                    if (element is LinkableElement) {
                      return TextSpan(
                        text: element.text,
                        style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()..onTap = () async {
                          final uri = Uri.parse(element.url);
                          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                      );
                    } else { return TextSpan(text: element.text); }
                  }).toList(),
                  if (effectiveIsLong && !_isContentExpanded)
                    TextSpan(text: "  ${s.post_card_more}", style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w800, fontSize: 14.5)),
                ],
              ),
              maxLines: _isContentExpanded ? null : 3,
              overflow: _isContentExpanded ? TextOverflow.visible : TextOverflow.clip,
            ),
          ),
          if (_isContentExpanded && effectiveIsLong)
            GestureDetector(
              onTap: () => setState(() => _isContentExpanded = false),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(s.post_card_fold, style: TextStyle(fontSize: 13, color: Colors.blue[700], fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
              ),
            ),
        ],
      ),
    );
  }

  void _showUserProfileDialog(String userId, AppLocalizations s) {
    final isMe = widget.currentUserId == userId;
    showDialog(
      context: context,
      builder: (_) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data?.data() ?? {};
          return UserProfileDialog(
            koreanName: data['koreanName'] ?? s.member_list_no_name,
            englishName: data['englishName'],
            photoUrl: data['profileImageUrl'],
            shopName: data['shopName'],
            barrelData: data['barrelName'] != null ? {
              'barrelImageUrl': data['barrelImageUrl'],
              'barrelName': data['barrelName'],
              'shaft': data['shaft'],
              'flight': data['flight'],
              'tip': data['tip'],
            } : null,
            isMe: isMe,
            userId: userId,
          );
        },
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final double radius;
  final Color primaryColor;
  final String? photoUrl;
  final int? currentRank;

  const _ProfileAvatar({required this.radius, required this.primaryColor, this.photoUrl, this.currentRank});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: primaryColor,
          child: ClipOval(
            child: (photoUrl != null && photoUrl!.isNotEmpty)
                ? Image.network(photoUrl!, width: radius * 2, height: radius * 2, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white))
                : const Icon(Icons.person, color: Colors.white),
          ),
        ),
        if (currentRank != null)
          Positioned(
            left: -6, top: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)]),
              child: BadgeWidget(rank: currentRank, size: 16),
            ),
          ),
      ],
    );
  }
}