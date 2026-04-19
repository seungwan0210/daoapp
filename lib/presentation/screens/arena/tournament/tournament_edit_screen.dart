// lib/presentation/screens/arena/tournament/tournament_edit_screen.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daoapp/data/models/tournament_model.dart';
import 'package:daoapp/data/repositories/arena_repository.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/services/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:daoapp/presentation/widgets/app_card.dart';

class TournamentEditScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentEditScreen({super.key, required this.tournamentId});

  @override
  State<TournamentEditScreen> createState() => _TournamentEditScreenState();
}

class _TournamentEditScreenState extends State<TournamentEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _hostNameCtrl = TextEditingController();
  final _hostPhoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  final _teamSizeCtrl = TextEditingController();

  DateTime? _eventDay;
  TimeOfDay? _eventTime;
  DateTime? _entryStartDay;
  DateTime? _entryEndDay;

  File? _posterFile;
  String? _posterUrl;
  List<String> _coOrganizers = [];
  List<String> _customQuestions = []; // ✅ 추가 질문 리스트

  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedType = 'single';

  bool get _canSubmit =>
      _titleCtrl.text.trim().isNotEmpty &&
          _locationCtrl.text.trim().isNotEmpty &&
          _hostNameCtrl.text.trim().isNotEmpty &&
          _hostPhoneCtrl.text.trim().isNotEmpty &&
          _eventDay != null &&
          _eventTime != null &&
          _entryStartDay != null &&
          _entryEndDay != null &&
          _feeCtrl.text.trim().isNotEmpty &&
          _maxCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadTournament();
    void attach(TextEditingController c) {
      c.addListener(() { if (mounted) setState(() {}); });
    }
    [_titleCtrl, _locationCtrl, _hostNameCtrl, _hostPhoneCtrl, _feeCtrl, _maxCtrl, _teamSizeCtrl].forEach(attach);
  }

  @override
  void dispose() {
    [_titleCtrl, _locationCtrl, _hostNameCtrl, _hostPhoneCtrl, _descCtrl, _feeCtrl, _maxCtrl, _teamSizeCtrl].forEach((c) => c.dispose());
    super.dispose();
  }

  DateTime _stripToDay(DateTime d) => DateTime(d.year, d.month, d.day);
  String _formatDay(DateTime d) => DateFormat('yyyy.MM.dd (EEE)', 'ko_KR').format(d);
  String _formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _loadTournament() async {
    try {
      final repo = sl<ArenaRepository>();
      final data = await repo.getTournament(widget.tournamentId);
      if (data == null) {
        if (mounted) Navigator.pop(context);
        return;
      }
      final user = sl<FirebaseAuth>().currentUser;
      final hostEmail = (user?.email ?? '').trim().toLowerCase();

      _titleCtrl.text = data.title;
      _locationCtrl.text = data.location;
      _hostNameCtrl.text = data.hostName;
      _hostPhoneCtrl.text = data.hostPhone;
      _descCtrl.text = data.description;
      _feeCtrl.text = NumberFormat('#,###').format(data.entryFee);
      _maxCtrl.text = data.maxParticipants >= 9999 ? '무제한' : data.maxParticipants.toString();
      _selectedType = data.type;
      _teamSizeCtrl.text = data.teamSize.toString();

      // ✅ 기존 질문들 불러오기
      _customQuestions = List.from(data.customQuestions);

      final eventDt = data.eventDate.toDate();
      _eventDay = _stripToDay(eventDt);
      _eventTime = TimeOfDay(hour: eventDt.hour, minute: eventDt.minute);
      _entryStartDay = _stripToDay(data.entryStartDate.toDate());
      _entryEndDay = _stripToDay(data.entryEndDate.toDate());
      _posterUrl = data.posterUrl;
      _coOrganizers = data.organizerEmails.where((e) => e.trim().toLowerCase() != hostEmail).toList();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  void _onEventDayPicked(DateTime picked) {
    setState(() {
      _eventDay = _stripToDay(picked);
      _eventTime ??= const TimeOfDay(hour: 9, minute: 0);
      final start = picked.subtract(const Duration(days: 10));
      final end = picked.subtract(const Duration(days: 3));
      final today = _stripToDay(DateTime.now());
      _entryStartDay = start.isBefore(today) ? today : _stripToDay(start);
      _entryEndDay = end.isBefore(_entryStartDay!) ? _entryStartDay : _stripToDay(end);
    });
  }

  Future<void> _pickTime() async {
    int hour = _eventTime?.hour ?? 9;
    int minute = _eventTime?.minute ?? 0;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SizedBox(
        height: 300,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
                  const Text('대회 시간 수정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton(
                    onPressed: () {
                      setState(() => _eventTime = TimeOfDay(hour: hour, minute: minute));
                      Navigator.pop(ctx);
                    },
                    child: const Text('완료', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(initialItem: hour),
                      itemExtent: 40,
                      onSelectedItemChanged: (v) => hour = v,
                      children: List.generate(24, (i) => Center(child: Text(i.toString().padLeft(2, '0')))),
                    ),
                  ),
                  const Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(initialItem: minute),
                      itemExtent: 40,
                      onSelectedItemChanged: (v) => minute = v,
                      children: List.generate(60, (i) => Center(child: Text(i.toString().padLeft(2, '0')))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    final user = sl<FirebaseAuth>().currentUser;
    if (user == null) return;

    final eventDateTime = DateTime(_eventDay!.year, _eventDay!.month, _eventDay!.day, _eventTime!.hour, _eventTime!.minute);
    final entryStart = DateTime(_entryStartDay!.year, _entryStartDay!.month, _entryStartDay!.day, 0, 0);
    final entryEnd = DateTime(_entryEndDay!.year, _entryEndDay!.month, _entryEndDay!.day, 23, 59);

    setState(() => _isSaving = true);
    try {
      String? posterUrl = _posterUrl;
      if (_posterFile != null) {
        posterUrl = await sl<StorageService>().uploadFile(_posterFile!.path, 'tournaments/posters');
      }
      final maxText = _maxCtrl.text.replaceAll(',', '').trim().toLowerCase();
      final int maxParticipants = (maxText == '무제한' || maxText == '0') ? 9999 : (int.tryParse(maxText) ?? 64);

      final Map<String, dynamic> updateData = {
        'title': _titleCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'hostName': _hostNameCtrl.text.trim(),
        'hostPhone': _hostPhoneCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'entryFee': int.parse(_feeCtrl.text.replaceAll(',', '').trim()),
        'maxParticipants': maxParticipants,
        'eventDate': Timestamp.fromDate(eventDateTime),
        'entryStartDate': Timestamp.fromDate(entryStart),
        'entryEndDate': Timestamp.fromDate(entryEnd),
        'organizerEmails': {user.email!, ..._coOrganizers}.whereType<String>().toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'posterUrl': posterUrl,
        'type': _selectedType,
        'teamSize': _selectedType == 'single' ? 1 : (int.tryParse(_teamSizeCtrl.text) ?? 2),
        // ✅ 수정된 질문 리스트 반영
        'customQuestions': _customQuestions,
      };

      await FirebaseFirestore.instance.collection('tournaments').doc(widget.tournamentId).update(updateData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('수정되었습니다.'), behavior: SnackBarBehavior.floating));
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: Colors.cyan)));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('대회 수정', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
        actions: [
          TextButton(
            onPressed: _canSubmit && !_isSaving ? _submit : null,
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyan))
                : const Text('저장', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.cyan)),
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPosterSection(),
                const SizedBox(height: 32),

                _sectionTitle('대회 방식 설정', Icons.account_tree_outlined),
                const SizedBox(height: 12),
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('개인전 (Single)')),
                                selected: _selectedType == 'single',
                                onSelected: (val) {
                                  if (val) setState(() => _selectedType = 'single');
                                },
                                selectedColor: Colors.cyan.withOpacity(0.2),
                                checkmarkColor: Colors.cyan,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('팀전 (Team)')),
                                selected: _selectedType == 'team',
                                onSelected: (val) {
                                  if (val) setState(() => _selectedType = 'team');
                                },
                                selectedColor: Colors.cyan.withOpacity(0.2),
                                checkmarkColor: Colors.cyan,
                              ),
                            ),
                          ],
                        ),
                        if (_selectedType == 'team') ...[
                          const SizedBox(height: 16),
                          _buildTextField(_teamSizeCtrl, '팀당 인원수 (대표자 포함)', Icons.people_alt_outlined, isPhone: true),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                _sectionTitle('기본 정보', Icons.info_outline),
                const SizedBox(height: 12),
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_titleCtrl, '대회명', Icons.emoji_events_outlined),
                        const SizedBox(height: 16),
                        _buildTextField(_locationCtrl, '장소', Icons.location_on_outlined),
                        const SizedBox(height: 16),
                        _buildTextField(_hostNameCtrl, '담당자 성함', Icons.person_outline),
                        const SizedBox(height: 16),
                        _buildTextField(_hostPhoneCtrl, '담당자 연락처', Icons.phone_android_outlined, isPhone: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                _sectionTitle('참가 및 날짜 설정', Icons.settings_outlined),
                const SizedBox(height: 12),
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_feeCtrl, '참가비', Icons.paid_outlined, isMoney: true)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTextField(_maxCtrl, '최대 인원', Icons.groups_outlined)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildDateTile('대회 날짜', _eventDay, Colors.orange, Icons.calendar_today, _onEventDayPicked),
                        _buildTimeTile('대회 시간', _eventTime, Colors.orange, Icons.access_time, _pickTime),
                        _buildDateTile('엔트리 시작', _entryStartDay, Colors.green, Icons.play_circle_outline, (d) => setState(() => _entryStartDay = d), suffix: "00:00"),
                        _buildDateTile('엔트리 마감', _entryEndDay, Colors.green, Icons.stop_circle_outlined, (d) => setState(() => _entryEndDay = d), suffix: "23:59"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                _sectionTitle('상세 안내', Icons.description_outlined),
                const SizedBox(height: 12),
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _descCtrl,
                      maxLines: 6,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '대회 규칙 등을 작성해주세요.',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ✅ [수정] 커스텀 질문 수정 섹션 (setState 추가)
                _CustomQuestionInput(
                  initialQuestions: _customQuestions,
                  onChanged: (list) {
                    setState(() {
                      _customQuestions = list;
                    });
                  },
                ),
                const SizedBox(height: 32),

                _CoOrganizerInput(initialEmails: _coOrganizers, onChanged: (list) => _coOrganizers = list),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, IconData icon) => Row(
    children: [
      Icon(icon, size: 18, color: Colors.cyan),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
    ],
  );

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool isPhone = false, bool isMoney = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: (isPhone || isMoney) ? TextInputType.number : TextInputType.text,
      inputFormatters: isMoney ? [ThousandsFormatter()] : null,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, size: 20, color: Colors.grey[400]),
        labelStyle: const TextStyle(fontSize: 13),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyan, width: 2)),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? '필수 입력' : null,
    );
  }

  Widget _buildDateTile(String label, DateTime? day, Color color, IconData icon, Function(DateTime) onSelect, {String? suffix}) {
    String dateText = day != null ? _formatDay(day) : '선택';
    if (day != null && suffix != null) dateText = "$dateText  $suffix";
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      trailing: Text(dateText, style: TextStyle(fontWeight: FontWeight.bold, color: day != null ? Colors.black : Colors.cyan)),
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: day ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365)));
        if (picked != null) onSelect(picked);
      },
    );
  }

  Widget _buildTimeTile(String label, TimeOfDay? time, Color color, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      trailing: Text(time != null ? _formatTime(time!) : '선택',
          style: TextStyle(fontWeight: FontWeight.bold, color: time != null ? Colors.black : Colors.cyan)),
      onTap: onTap,
    );
  }

  Widget _buildPosterSection() {
    return GestureDetector(
      onTap: () async {
        final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
        if (picked != null) setState(() => _posterFile = File(picked.path));
      },
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Container(
          width: double.infinity, height: 180,
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
          child: _posterFile != null
              ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_posterFile!, fit: BoxFit.cover))
              : (_posterUrl != null
              ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(_posterUrl!, fit: BoxFit.cover))
              : const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text('대회 포스터 수정', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ))),
        ),
      ),
    );
  }
}

class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final text = newValue.text.replaceAll(',', '');
    final formatted = NumberFormat('#,###').format(int.tryParse(text) ?? 0);
    return newValue.copyWith(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

// ✅ [추가] 커스텀 질문 수정용 입력 위젯
class _CustomQuestionInput extends StatefulWidget {
  final List<String> initialQuestions;
  final Function(List<String>) onChanged;
  const _CustomQuestionInput({required this.initialQuestions, required this.onChanged});

  @override
  State<_CustomQuestionInput> createState() => _CustomQuestionInputState();
}

class _CustomQuestionInputState extends State<_CustomQuestionInput> {
  final _ctrl = TextEditingController();
  late List<String> _questions;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.initialQuestions);
  }

  void _addQuestion() {
    final text = _ctrl.text.trim();
    if (text.isNotEmpty && !_questions.contains(text)) {
      setState(() {
        _questions.add(text);
        widget.onChanged(_questions);
      });
      _ctrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.help_outline, size: 18, color: Colors.cyan),
            const SizedBox(width: 8),
            const Text('신청 시 추가 질문 (선택)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            hintText: '질문을 입력하고 추가 버튼을 누르세요.',
            hintStyle: const TextStyle(fontSize: 13),
            suffixIcon: IconButton(icon: const Icon(Icons.add_circle, color: Colors.cyan), onPressed: _addQuestion),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
          ),
          onSubmitted: (_) => _addQuestion(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _questions.map((q) => Chip(
            label: Text(q, style: const TextStyle(fontSize: 12)),
            onDeleted: () {
              setState(() {
                _questions.remove(q);
                widget.onChanged(_questions);
              });
            },
            side: BorderSide(color: Colors.cyan.withOpacity(0.1)),
            backgroundColor: Colors.cyan.withOpacity(0.05),
            deleteIconColor: Colors.cyan,
          )).toList(),
        ),
      ],
    );
  }
}

class _CoOrganizerInput extends StatefulWidget {
  final List<String> initialEmails;
  final Function(List<String>) onChanged;
  const _CoOrganizerInput({required this.initialEmails, required this.onChanged});
  @override
  State<_CoOrganizerInput> createState() => _CoOrganizerInputState();
}

class _CoOrganizerInputState extends State<_CoOrganizerInput> {
  final _ctrl = TextEditingController();
  late List<String> _emails;
  @override
  void initState() { super.initState(); _emails = List.from(widget.initialEmails); }
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('공동주최자 추가', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 12),
      TextField(
        controller: _ctrl,
        decoration: InputDecoration(
          hintText: '이메일 입력',
          suffixIcon: IconButton(icon: const Icon(Icons.add_circle, color: Colors.cyan), onPressed: _addEmail),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
        ),
        onSubmitted: (_) => _addEmail(),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: _emails.map((e) => Chip(
        label: Text(e, style: const TextStyle(fontSize: 12)),
        onDeleted: () { setState(() { _emails.remove(e); widget.onChanged(_emails); }); },
        side: BorderSide(color: Colors.cyan.withOpacity(0.1)),
        backgroundColor: Colors.cyan.withOpacity(0.05),
        deleteIconColor: Colors.cyan,
      )).toList()),
    ]);
  }
  void _addEmail() {
    if (_ctrl.text.isNotEmpty && !_emails.contains(_ctrl.text)) { setState(() { _emails.add(_ctrl.text.trim()); widget.onChanged(_emails); }); _ctrl.clear(); }
  }
}