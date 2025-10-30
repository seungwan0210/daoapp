// lib/presentation/screens/admin/event_create_screen.dart
class EventCreateScreen extends StatefulWidget {
  final String? eventId; // 수정 모드
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
  String _status = 'upcoming';

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) _loadEvent();
  }

  Future<void> _loadEvent() async {
    final doc = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .get();
    final data = doc.data()!;
    setState(() {
      _date = (data['date'] as Timestamp).toDate();
      _shopName = data['shopName'];
      _time = data['time'];
      _entryFee = data['entryFee'];
      _resultImageUrl = data['resultImageUrl'];
      _winnerName = data['winnerName'] ?? '';
      _status = data['status'];
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'date': Timestamp.fromDate(_date),
      'shopName': _shopName,
      'time': _time,
      'entryFee': _entryFee,
      'resultImageUrl': _resultImageUrl,
      'winnerName': _winnerName,
      'status': _status,
    };

    if (widget.eventId == null) {
      await FirebaseFirestore.instance.collection('events').add(data);
    } else {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .update(data);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.eventId == null ? '경기 등록' : '경기 수정')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: Text('날짜: ${_date.toLocal().toString().split(' ')[0]}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2027),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: '장소 (샵명)'),
              initialValue: _shopName,
              onChanged: (v) => _shopName = v,
              validator: (v) => v!.isEmpty ? '입력하세요' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: '시간 (예: 14:00)'),
              initialValue: _time,
              onChanged: (v) => _time = v,
              validator: (v) => v!.isEmpty ? '입력하세요' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: '참가비'),
              initialValue: _entryFee.toString(),
              keyboardType: TextInputType.number,
              onChanged: (v) => _entryFee = int.tryParse(v) ?? 0,
            ),
            if (_status == 'completed') ...[
              TextFormField(
                decoration: const InputDecoration(labelText: '우승자 이름'),
                initialValue: _winnerName,
                onChanged: (v) => _winnerName = v,
              ),
              // 사진 업로드 (firebase_storage)
            ],
            ElevatedButton(onPressed: _save, child: const Text('저장')),
          ],
        ),
      ),
    );
  }
}