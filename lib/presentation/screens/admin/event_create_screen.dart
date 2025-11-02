// lib/presentation/screens/admin/event_create_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:daoapp/core/utils/date_utils.dart'; // 추가

class EventCreateScreen extends StatefulWidget {
  final String? eventId;
  const EventCreateScreen({super.key, this.eventId});

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
  String _status = 'upcoming'; // 기본값

  late final TextEditingController _shopController;
  late final TextEditingController _timeController;
  late final TextEditingController _entryFeeController;
  late final TextEditingController _winnerController;

  File? _pickedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _shopController = TextEditingController();
    _timeController = TextEditingController();
    _entryFeeController = TextEditingController();
    _winnerController = TextEditingController();

    if (widget.eventId != null) _loadEvent();
  }

  @override
  void dispose() {
    _shopController.dispose();
    _timeController.dispose();
    _entryFeeController.dispose();
    _winnerController.dispose();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    final doc = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .get();
    if (!doc.exists) return;

    final data = doc.data()!;
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
          SnackBar(content: Text('이미지 업로드 실패: $e')),
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
      // calendar_screen과 연동을 위해 추가
      'title': '$_shopName 경기',
    };

    try {
      if (widget.eventId == null) {
        await FirebaseFirestore.instance.collection('events').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .update(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('경기 저장 완료!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventId == null ? '경기 등록' : '경기 수정'),
        backgroundColor: const Color(0xFF00D4FF),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 날짜 선택
            Card(
              child: ListTile(
                title: Text('날짜: ${_date.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                // showDatePicker 부분만 수정
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: AppDateUtils.firstDay,
                    lastDate: AppDateUtils.lastDay,
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
            ),
            const SizedBox(height: 16),

            // 상태 선택
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: '경기 상태',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'upcoming', child: Text('예정')),
                DropdownMenuItem(value: 'completed', child: Text('종료')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),

            // 장소
            TextFormField(
              controller: _shopController,
              decoration: const InputDecoration(
                labelText: '장소 (샵명)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.trim().isEmpty ? '샵명을 입력하세요' : null,
            ),
            const SizedBox(height: 16),

            // 시간
            TextFormField(
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: '시간 (예: 14:00)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.trim().isEmpty ? '시간을 입력하세요' : null,
            ),
            const SizedBox(height: 16),

            // 참가비
            TextFormField(
              controller: _entryFeeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '참가비 (원)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final val = v!.trim();
                if (val.isEmpty) return null;
                if (int.tryParse(val) == null) return '숫자만 입력하세요';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 종료된 경기일 때만 보임
            if (_status == 'completed') ...[
              TextFormField(
                controller: _winnerController,
                decoration: const InputDecoration(
                  labelText: '우승자 이름 (필수)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.trim().isEmpty ? '우승자 이름을 입력하세요' : null,
              ),
              const SizedBox(height: 16),

              // 이미지 업로드
              _pickedImage == null && _resultImageUrl == null
                  ? ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo),
                label: const Text('결과 사진 추가 (필수)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              )
                  : Column(
                children: [
                  if (_pickedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_pickedImage!, height: 200, fit: BoxFit.cover),
                    ),
                  if (_resultImageUrl != null && _pickedImage == null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(_resultImageUrl!, height: 200, fit: BoxFit.cover),
                    ),
                  const SizedBox(height: 8),
                  _isUploading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo),
                    label: const Text('사진 변경'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _status == 'completed' && (_pickedImage == null && _resultImageUrl == null)
                    ? null
                    : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.eventId == null ? '등록하기' : '수정하기',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}