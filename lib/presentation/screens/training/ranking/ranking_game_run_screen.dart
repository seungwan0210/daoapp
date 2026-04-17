import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';

class RankingGameRunScreen extends ConsumerStatefulWidget {
  final String gameType;
  const RankingGameRunScreen({super.key, required this.gameType});

  @override
  ConsumerState<RankingGameRunScreen> createState() => _RankingGameRunScreenState();
}

class _RankingGameRunScreenState extends ConsumerState<RankingGameRunScreen> {
  int _currentRound = 1;
  final int _maxRounds501 = 10;
  final int _maxRoundsCricket = 8;

  int _leftScore = 501;
  int _totalThrownDarts = 0;
  final List<int> _history501 = [];

  int _totalMarks = 0;
  int _selectedMark = 0;
  final List<int> _historyCricket = [];
  final List<String> _cricketTargets = ["20", "19", "18", "17", "16", "15", "BULL", "ANY"];

  final TextEditingController _countUpController = TextEditingController();
  final TextEditingController _scoreController501 = TextEditingController();

  void _undoLastRound() {
    if (_currentRound <= 1) return;
    setState(() {
      _currentRound--;
      if (widget.gameType == "501") {
        final lastScore = _history501.removeLast();
        _leftScore += lastScore;
        _totalThrownDarts -= 3;
      } else if (widget.gameType == "cricket") {
        final lastMark = _historyCricket.removeLast();
        _totalMarks -= lastMark;
        _selectedMark = 0;
      }
    });
  }

  void _submitRound501() {
    final value = int.tryParse(_scoreController501.text) ?? 0;
    if (value > 180) { _showSnackBar("최대 180점입니다."); return; }
    setState(() {
      if (value > _leftScore) {
        _showSnackBar("BUST!");
        _history501.add(0); _totalThrownDarts += 3; _nextRound501();
      } else if (value == _leftScore) {
        _leftScore = 0; _history501.add(value); _showDartCountPicker();
      } else {
        _leftScore -= value; _history501.add(value); _totalThrownDarts += 3; _nextRound501();
      }
      _scoreController501.clear();
    });
  }

  void _nextRound501() { if (_currentRound >= _maxRounds501) _finishGame(); else _currentRound++; }

  void _showDartCountPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // 키보드나 높이 제어를 위해 true 권장
      builder: (context) => SafeArea( // 하단 내비게이션 바 영역 침범 방지
        child: Container(
          // margin을 줘서 바닥에 붙지 않고 떠 있는 느낌으로 만들면 더 깔끔합니다.
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24), // 둥근 모서리로 수정
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 내용만큼만 높이 차지
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 40),
              const SizedBox(height: 12),
              const Text(
                  "FINISH! 🎯",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))
              ),
              const SizedBox(height: 8),
              const Text(
                  "마지막 라운드에서 몇 발을 던졌나요?",
                  style: TextStyle(fontSize: 13, color: Colors.grey)
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [1, 2, 3].map((count) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _totalThrownDarts += count);
                        Navigator.pop(context);
                        _finishGame();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan[700],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text(
                          "$count발",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 8), // 하단 여백 추가
            ],
          ),
        ),
      ),
    );
  }

  void _submitRoundCricket() {
    setState(() {
      _totalMarks += _selectedMark; _historyCricket.add(_selectedMark);
      if (_currentRound >= _maxRoundsCricket) _finishGame();
      else { _currentRound++; _selectedMark = 0; }
    });
  }

  void _submitCountUp() { if (_countUpController.text.isNotEmpty) _finishGame(); }

  // 🔥 [수정] 레포지토리의 변경된 매개변수에 맞춰 nickname 제거
  void _finishGame() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    double? ppd; double? mpr; int? countUpScore;
    if (widget.gameType == "501") ppd = _totalThrownDarts == 0 ? 0 : (501 - _leftScore) / _totalThrownDarts;
    else if (widget.gameType == "cricket") mpr = _totalMarks / _maxRoundsCricket;
    else if (widget.gameType == "countup") countUpScore = int.tryParse(_countUpController.text) ?? 0;

    await ref.read(rankingRepositoryProvider).updateBestRecord(
      uid: user.uid, // 닉네임과 프로필은 레포지토리 내부에서 처리함
      ppd: ppd,
      mpr: mpr,
      countUp: countUpScore,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("${widget.gameType.toUpperCase()} RANKING", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        centerTitle: true, elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black87,
        toolbarHeight: 45,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    _roundBadge(widget.gameType == "501" ? _maxRounds501 : 8),
                    const SizedBox(height: 15),
                    if (widget.gameType == "501") _build501Content(),
                    if (widget.gameType == "cricket") _buildCricketContent(),
                    if (widget.gameType == "countup") _buildCountUpContent(),
                  ],
                ),
              ),
            ),
            _buildBottomControlBar(),
          ],
        ),
      ),
    );
  }

  Widget _build501Content() {
    return Column(
      children: [
        const Text("LEFT SCORE", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        Text("$_leftScore", style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 20),
        TextField(
          controller: _scoreController501,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: "Score", filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
          autofocus: true,
          onSubmitted: (_) => _submitRound501(),
        ),
      ],
    );
  }

  Widget _buildCricketContent() {
    String currentTarget = _cricketTargets[_currentRound - 1];
    double currentMpr = _totalMarks / (_currentRound == 1 ? 1 : _currentRound);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF004D40), Color(0xFF00695C)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _scoreInfoItem("MARKS", "$_totalMarks"),
                  _scoreInfoItem("MPR", currentMpr.toStringAsFixed(2)),
                ],
              ),
              const Divider(color: Colors.white24, height: 20),
              const Text("TARGET", style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(currentTarget, style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12, runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(10, (index) => _markButton(index)),
        ),
      ],
    );
  }

  Widget _scoreInfoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildCountUpContent() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.emoji_events_rounded, size: 50, color: Colors.amber),
        const SizedBox(height: 15),
        const Text("FINAL SCORE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 20),
        TextField(
          controller: _countUpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: "0", filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _roundBadge(int max) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.blueGrey[900], borderRadius: BorderRadius.circular(15)),
      child: Text("ROUND $_currentRound / $max", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
    );
  }

  Widget _markButton(int val) {
    bool isSelected = _selectedMark == val;
    return InkWell(
      onTap: () => setState(() => _selectedMark = val),
      borderRadius: BorderRadius.circular(100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 52, height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyan[700] : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
          border: Border.all(color: isSelected ? Colors.cyan.shade200 : Colors.grey.shade200, width: 1),
        ),
        child: Text("$val", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
      ),
    );
  }

  Widget _buildBottomControlBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Row(
        children: [
          if (widget.gameType != "countup")
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: _currentRound > 1 ? _undoLastRound : null,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _currentRound > 1 ? Colors.red[50] : Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                  child: Icon(Icons.undo_rounded, color: _currentRound > 1 ? Colors.redAccent : Colors.grey, size: 24),
                ),
              ),
            ),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: widget.gameType == "501" ? _submitRound501 : widget.gameType == "cricket" ? _submitRoundCricket : _submitCountUp,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan[700], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0),
                child: Text(
                  widget.gameType == "countup" ? "SUBMIT" : "CONFIRM",
                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1)));
  }
}