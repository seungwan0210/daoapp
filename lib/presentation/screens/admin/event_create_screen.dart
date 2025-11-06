// lib/presentation/screens/admin/event_create_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class EventCreateScreen extends StatefulWidget {
  final bool editMode;
  final String? docId;
  final Map<String, dynamic>? initialData;

  const EventCreateScreen({
    super.key,
    this.editMode = false,
    this.docId,
    this.initialData,
  });

  @override
  State<EventCreateScreen> createState() => _EventCreateScreenState();
}

class _EventCreateScreenState extends State<EventCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();
  String _shopName = '';
  String _time = '';
  int _entryFee = 0;
  String? _resultImageUrl;
  String _winnerName = '';
  String _status = 'upcoming';

  late final TextEditingController _shopController;
  late final TextEditingController _timeController;
  late final TextEditingController _entryFeeController;
  late final TextEditingController _winnerController;

  File? _pickedImage;
  bool _isUploading = false;

  List<String> _shopSearchResults = [];
  bool _isLoadingShop = false;

  @override
  void initState() {
    super.initState();
    _shopController = TextEditingController();
    _timeController = TextEditingController();
    _entryFeeController = TextEditingController();
    _winnerController = TextEditingController();

    _shopController.addListener(_searchShops);

    if (widget.editMode && widget.initialData != null) {
      _loadEvent();
    }
  }

  @override
  void dispose() {
    _shopController.removeListener(_searchShops);
    _shopController.dispose();
    _timeController.dispose();
    _entryFeeController.dispose();
    _winnerController.dispose();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    final data = widget.initialData!;
    setState(() {
      _date = (data['date'] as Timestamp).toDate();
      _shopName = data['shopName'] ?? '';
      _time = data['time'] ?? '';
      _entryFee = data['entryFee'] ?? 0;
      _resultImageUrl = data['resultImageUrl'];
      _winnerName = data['winnerName'] ?? '';
      _status = data['status'] ?? 'upcoming';

      _shopController.text = _shopName;
      _timeController.text = _time;
      _entryFeeController.text = _entryFee.toString();
      _winnerController.text = _winnerName;
    });
  }

  Future<List<String>> _getUniqueShopNames() async {
    final snapshot = await FirebaseFirestore.instance.collection('events').get();
    final Set<String> names = {};
    for (var doc in snapshot.docs) {
      final name = doc['shopName'] as String?;
      if (name != null && name.trim().isNotEmpty) {
        names.add(name.trim());
      }
    }
    return names.toList()..sort();
  }

  void _searchShops() async {
    final query = _shopController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _shopSearchResults = [];
        _isLoadingShop = false;
      });
      return;
    }

    setState(() => _isLoadingShop = true);

    final allShops = await _getUniqueShopNames();
    final filtered = allShops
        .where((name) => name.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();

    setState(() {
      _shopSearchResults = filtered;
      _isLoadingShop = false;
    });
  }

  Future<void> _selectShop(String shopName) async {
    setState(() => _isLoadingShop = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('shopName', isEqualTo: shopName)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    setState(() {
      _shopName = shopName;
      _shopController.text = shopName;
      _shopSearchResults = [];
      _isLoadingShop = false;

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        _timeController.text = data['time'] ?? '';
        _entryFeeController.text = (data['entryFee'] ?? 0).toString();
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    setState(() => _isUploading = true);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('event_results')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = ref.putFile(image);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 업로드 실패: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    _shopName = _shopController.text.trim();
    _time = _timeController.text.trim();
    _entryFee = int.tryParse(_entryFeeController.text) ?? 0;
    _winnerName = _winnerController.text.trim();

    if (_pickedImage != null) {
      final url = await _uploadImage(_pickedImage!);
      if (url != null) _resultImageUrl = url;
    }

    final data = {
      'date': Timestamp.fromDate(_date),
      'shopName': _shopName,
      'time': _time,
      'entryFee': _entryFee,
      'resultImageUrl': _resultImageUrl,
      'winnerName': _winnerName,
      'status': _status,
      'title': '$_shopName 경기',
    };

    try {
      if (widget.editMode) {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.docId)
            .update(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('경기 수정 완료!'), backgroundColor: Colors.green),
          );
        }
      } else {
        await FirebaseFirestore.instance.collection('events').add(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('경기 등록 완료!'), backgroundColor: Colors.green),
          );
        }
      }
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editMode ? '경기 수정' : '경기 등록'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 날짜
            AppCard(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: Text(
                  '날짜: ${AppDateUtils.formatKoreanDate(_date)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: AppDateUtils.firstDay,
                    lastDate: AppDateUtils.lastDay,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: theme.colorScheme.copyWith(
                            primary: theme.colorScheme.primary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
            ),
            const SizedBox(height: 16),

            // 상태
            AppCard(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(
                  labelText: '경기 상태',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(
                    _status == 'completed' ? Icons.emoji_events : Icons.schedule,
                    color: _status == 'completed' ? Colors.amber : Colors.green,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'upcoming', child: Text('예정')),
                  DropdownMenuItem(value: 'completed', child: Text('종료')),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
            ),
            const SizedBox(height: 16),

            // 장소 (자동완성)
            AppCard(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _shopController,
                    decoration: InputDecoration(
                      labelText: '장소 (샵명)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.location_on),
                      suffixIcon: _isLoadingShop
                          ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                          : _shopSearchResults.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _shopController.clear();
                          setState(() => _shopSearchResults = []);
                        },
                      )
                          : null,
                    ),
                    validator: (v) => v!.trim().isEmpty ? '샵명을 입력하세요' : null,
                  ),
                  if (_shopSearchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _shopSearchResults.length,
                        itemBuilder: (_, i) {
                          final shopName = _shopSearchResults[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.store, size: 18),
                            title: Text(shopName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            onTap: () => _selectShop(shopName),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 시간
            AppCard(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: '시간 (예: 14:00)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.access_time),
                ),
                validator: (v) => v!.trim().isEmpty ? '시간을 입력하세요' : null,
              ),
            ),
            const SizedBox(height: 16),

            // 참가비
            AppCard(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: TextFormField(
                controller: _entryFeeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '참가비 (원)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (v) {
                  final val = v!.trim();
                  if (val.isEmpty) return null;
                  if (int.tryParse(val) == null) return '숫자만 입력하세요';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // 종료된 경기일 때만
            if (_status == 'completed') ...[
              AppCard(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: TextFormField(
                  controller: _winnerController,
                  decoration: InputDecoration(
                    labelText: '우승자 이름 (필수)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.emoji_events, color: Colors.amber),
                  ),
                  validator: (v) => v!.trim().isEmpty ? '우승자 이름을 입력하세요' : null,
                ),
              ),
              const SizedBox(height: 16),

              // 이미지 업로드
              AppCard(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    if (_pickedImage != null || _resultImageUrl != null) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _pickedImage != null
                                ? Image.file(_pickedImage!, height: 200, width: double.infinity, fit: BoxFit.cover)
                                : Image.network(_resultImageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              style: IconButton.styleFrom(backgroundColor: Colors.black54),
                              onPressed: () => setState(() {
                                _pickedImage = null;
                                _resultImageUrl = null;
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    _isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo),
                        label: Text(_pickedImage != null || _resultImageUrl != null ? '사진 변경' : '결과 사진 추가 (필수)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (_pickedImage == null && _resultImageUrl == null) ? Colors.red : theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_status == 'completed' && (_pickedImage == null && _resultImageUrl == null)) ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_status == 'completed' && (_pickedImage == null && _resultImageUrl == null)) ? Colors.grey : theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  widget.editMode ? '수정하기' : '등록하기',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}