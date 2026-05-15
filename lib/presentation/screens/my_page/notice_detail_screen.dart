import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';
import 'package:daoapp/l10n/app_localizations.dart';

class NoticeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> noticeData;

  const NoticeDetailScreen({super.key, required this.noticeData});

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  late String _selectedLang;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    // 초기 언어 설정 (기본값 한국어)
    _selectedLang = 'ko';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final data = widget.noticeData;

    // 🔥 다국어 데이터 구조 추출
    final langs = data['langs'] as Map<String, dynamic>? ?? {};
    final currentContent = langs[_selectedLang] ?? langs['ko'] ?? {};

    final String title = currentContent['title'] ?? '';
    final String content = currentContent['content'] ?? '';

    // 🔥 사진 리스트 처리 (최대 7장)
    final List<String> imageUrls = data['imageUrls'] != null
        ? List<String>.from(data['imageUrls'])
        : (data['imageUrl'] != null ? [data['imageUrl']] : []);

    final timestamp = (data['createdAt'] as Timestamp?)?.toDate();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: s.notice_title, showBackButton: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 상단 이미지 슬라이더
            if (imageUrls.isNotEmpty) _buildPhotoSlider(imageUrls, s),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. 다국어 선택 칩 (국기 및 정렬 적용)
                  _buildLanguageChips(langs.keys.toList(), s),
                  const SizedBox(height: 24),

                  // 3. 제목 영역
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. 날짜 표시
                  if (timestamp != null)
                    Text(
                      AppDateUtils.formatRelativeTime(timestamp),
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  ),

                  // 5. 공지 본문 내용
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: Color(0xFF334155),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📸 사진 슬라이더 위젯
  Widget _buildPhotoSlider(List<String> urls, AppLocalizations s) {
    return Stack(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 280,
            viewportFraction: 1.0,
            enableInfiniteScroll: urls.length > 1,
            onPageChanged: (index, reason) {
              setState(() => _currentPhotoIndex = index);
            },
          ),
          items: urls.map((url) {
            return Builder(
              builder: (context) => GestureDetector(
                onTap: () => _showFullImage(context, url),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (urls.length > 1)
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                s.notice_photo_indicator((_currentPhotoIndex + 1).toString(), urls.length.toString()),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  // 🌐 언어 선택 칩 위젯 (정렬 + 국기 이모티콘)
  Widget _buildLanguageChips(List<dynamic> availableLangs, AppLocalizations s) {
    // 💡 정렬 순서 정의: 한국, 미국, 일본, 중국, 대만
    const sortedKeys = ['ko', 'en', 'ja', 'zh_Hans', 'zh_Hant'];

    // 존재하는 언어들만 필터링하여 정렬
    final displayLangs = sortedKeys.where((key) => availableLangs.contains(key)).toList();

    // 언어별 정보 매핑
    final langInfo = {
      'ko': {'name': s.notice_lang_ko, 'flag': '🇰🇷'},
      'en': {'name': s.notice_lang_en, 'flag': '🇺🇸'},
      'ja': {'name': s.notice_lang_ja, 'flag': '🇯🇵'},
      'zh_Hans': {'name': s.notice_lang_zh_hans, 'flag': '🇨🇳'},
      'zh_Hant': {'name': s.notice_lang_zh_hant, 'flag': '🇹🇼'},
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: displayLangs.map((lang) {
        final isSelected = _selectedLang == lang;
        final info = langInfo[lang] ?? {'name': lang.toString(), 'flag': '🌐'};

        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(info['flag']!, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(info['name']!),
            ],
          ),
          selected: isSelected,
          onSelected: (val) {
            if (val) setState(() => _selectedLang = lang);
          },
          selectedColor: const Color(0xFF3B82F6),
          backgroundColor: const Color(0xFFF1F5F9),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        );
      }).toList(),
    );
  }

  // 🔍 이미지 확대 보기 다이얼로그
  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(url),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
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
}