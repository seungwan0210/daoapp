// lib/presentation/screens/admin/event_create_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/core/utils/date_utils.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';
import 'package:daoapp/presentation/widgets/common_appbar.dart';

class EventCreateScreen extends StatefulWidget {
  const EventCreateScreen({super.key});

  @override
  State<EventCreateScreen> createState() => _EventCreateScreenState();
}

class _EventCreateScreenState extends State<EventCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _date = DateTime.now();
  String _time = '';
  String _shopName = '';
  int _entryFee = 0;
  String _admin = '';
  String _contact = '';

  late final TextEditingController _shopController;
  late final TextEditingController _timeController;
  late final TextEditingController _entryFeeController;
  late final TextEditingController _adminController;
  late final TextEditingController _contactController;

  List<String> _shopSearchResults = [];
  bool _isLoadingShop = false;

  @override
  void initState() {
    super.initState();
    _shopController = TextEditingController();
    _timeController = TextEditingController();
    _entryFeeController = TextEditingController();
    _adminController = TextEditingController();
    _contactController = TextEditingController();

    _shopController.addListener(_searchShops);

    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _shopController.removeListener(_searchShops);
    _shopController.dispose();
    _timeController.dispose();
    _entryFeeController.dispose();
    _adminController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<List<String>> _getUniqueShopNames() async {
    final snapshot = await FirebaseFirestore.instance.collection('events').get();
    final Set<String> names = {};
    for (var doc in snapshot.docs) {
      final name = doc['shopName'] as String?;
      if (name != null && name.trim().isNotEmpty) names.add(name.trim());
    }
    return names.toList()..sort();
  }

  void _searchShops() async {
    final query = _shopController.text.trim();
    if (query.isEmpty) {
      setState(() => _shopSearchResults = []);
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
        final fee = data['entryFee'];
        _entryFeeController.text = (fee is int && fee > 0) ? fee.toString() : '';
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    _shopName = _shopController.text.trim();
    _time = _timeController.text.trim();
    _entryFee = int.tryParse(_entryFeeController.text.trim()) ?? 0;
    _admin = _adminController.text.trim();
    _contact = _contactController.text.trim();

    final data = {
      'date': Timestamp.fromDate(_date),
      'time': _time,
      'shopName': _shopName,
      'entryFee': _entryFee,
      'admin': _admin,
      'contact': _contact,
      'title': '$_shopName 경기',
      'resultImageUrl': null,  // 등록 시 사진 없음
      'winner': null,          // 등록 시 우승자 없음
    };

    try {
      await FirebaseFirestore.instance.collection('events').add(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('경기 등록 완료!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등록 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: '경기 등록',
        showBackButton: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 날짜
            AppCard(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: Text('날짜: ${AppDateUtils.formatKoreanDate(_date)}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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

            // 시간
            AppCard(
              child: TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: '시간 (예: 18:00)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.access_time),
                ),
                validator: (v) => v!.trim().isEmpty ? '시간을 입력하세요' : null,
              ),
            ),
            const SizedBox(height: 16),

            // 장소
            AppCard(
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
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : _shopSearchResults.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _shopController.clear())
                          : null,
                    ),
                    validator: (v) => v!.trim().isEmpty ? '샵명을 입력하세요' : null,
                  ),
                  if (_shopSearchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _shopSearchResults.length,
                        itemBuilder: (_, i) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.store, size: 18),
                          title: Text(_shopSearchResults[i], style: const TextStyle(fontWeight: FontWeight.w600)),
                          onTap: () => _selectShop(_shopSearchResults[i]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 참가비
            AppCard(
              child: TextFormField(
                controller: _entryFeeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '참가비 (원, 미입력 시 0원)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (v) {
                  if (v!.trim().isEmpty) return null;
                  return int.tryParse(v.trim()) == null ? '숫자만 입력하세요' : null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // 관리자 + 연락처
            AppCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _adminController,
                    decoration: InputDecoration(
                      labelText: '관리자',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (v) => v!.trim().isEmpty ? '관리자를 입력하세요' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactController,
                    decoration: InputDecoration(
                      labelText: '연락처',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    validator: (v) => v!.trim().isEmpty ? '연락처를 입력하세요' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 등록 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('등록하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}