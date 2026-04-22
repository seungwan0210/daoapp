import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:daoapp/core/utils/ad_manager.dart';
import 'package:daoapp/presentation/providers/training/ranking/ranking_provider.dart';

class RankingGameRunScreen extends ConsumerStatefulWidget {
  final String gameType;
  const RankingGameRunScreen({super.key, required this.gameType});

  @override
  ConsumerState<RankingGameRunScreen> createState() => _RankingGameRunScreenState();
}

class _RankingGameRunScreenState extends ConsumerState<RankingGameRunScreen> {
  static int _gameCount = 0;
  InterstitialAd? _interstitialAd;

  int _currentRound = 1;
  final int _maxRounds = 8;
  final int _maxRounds501 = 10;

  // 501 관련
  int _leftScore = 501;
  int _totalThrownDarts = 0;
  final List<int> _history501 = [];

  // 크리켓 관련
  int _totalMarks = 0;
  int _selectedMark = 0;
  final List<int> _historyCricket = [];
  final List<String> _cricketTargets = ["20", "19", "18", "17", "16", "15", "BULL", "ANY"];

  // 카운트업 관련
  int _totalCountUpScore = 0;
  final List<int> _historyCountUp = [];
  final TextEditingController _scoreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdManager.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => setState(() => _interstitialAd = ad),
        onAdFailedToLoad: (error) => _interstitialAd = null,
      ),
    );
  }

  void _undoLastRound() {
    if (_currentRound <= 1) return;
    setState(() {
      _currentRound--;
      if (widget.gameType == "501") {
        final last = _history501.removeLast();
        _leftScore += last;
        _totalThrownDarts -= 3;
      } else if (widget.gameType == "cricket") {
        final last = _historyCricket.removeLast();
        _totalMarks -= last;
        _selectedMark = 0;
      } else if (widget.gameType == "countup") {
        final last = _historyCountUp.removeLast();
        _totalCountUpScore -= last;
      }
    });
  }

  // 🔥 [신규] 501 BUST 전용 처리 함수
  void _handleBust() {
    setState(() {
      _history501.add(0);        // 0점 기록
      _totalThrownDarts += 3;    // 3발 소모 처리
      _scoreController.clear();
      _nextRound();
    });
    _showSnackBar("BUST 처리되었습니다.");
  }

  void _submitRound501() {
    final val = int.tryParse(_scoreController.text) ?? 0;
    if (val > 180) { _showSnackBar("최대 180점입니다."); return; }
    setState(() {
      if (val > _leftScore) {
        _showSnackBar("BUST!");
        _history501.add(0); _totalThrownDarts += 3; _nextRound();
      } else if (val == _leftScore) {
        _leftScore = 0; _history501.add(val); _showDartCountPicker();
      } else {
        _leftScore -= val; _history501.add(val); _totalThrownDarts += 3; _nextRound();
      }
      _scoreController.clear();
    });
  }

  void _submitRoundCricket() {
    String target = _cricketTargets[(_currentRound - 1).clamp(0, _cricketTargets.length - 1)];
    if (target == "BULL" && _selectedMark >= 7) {
      _showSnackBar("BULL은 최대 6마크까지만 가능합니다.");
      return;
    }
    setState(() {
      _totalMarks += _selectedMark;
      _historyCricket.add(_selectedMark);
      _selectedMark = 0;
      _nextRound();
    });
  }

  void _submitRoundCountUp() {
    final val = int.tryParse(_scoreController.text) ?? 0;
    if (val > 180) { _showSnackBar("최대 180점입니다."); return; }
    setState(() {
      _totalCountUpScore += val;
      _historyCountUp.add(val);
      _scoreController.clear();
      _nextRound();
    });
  }

  void _nextRound() {
    int max = widget.gameType == "501" ? _maxRounds501 : _maxRounds;
    if (_currentRound >= max) _finishGame();
    else _currentRound++;
  }

  void _finishGame() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _gameCount++;

    double? ppd; double? mpr; int? countUpScore;
    if (widget.gameType == "501") {
      ppd = _totalThrownDarts == 0 ? 0 : (501 - _leftScore) / _totalThrownDarts;
    } else if (widget.gameType == "cricket") {
      mpr = _historyCricket.isEmpty ? 0 : _totalMarks / _historyCricket.length;
    } else if (widget.gameType == "countup") {
      countUpScore = _totalCountUpScore;
    }

    await ref.read(rankingRepositoryProvider).updateBestRecord(
      uid: user.uid,
      ppd: ppd,
      mpr: mpr,
      countUp: countUpScore,
    );

    if (!mounted) return;

    bool shouldShowAd = (_gameCount == 1) || ((_gameCount - 1) % 3 == 0);

    if (shouldShowAd && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          Navigator.pop(context);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          Navigator.pop(context);
        },
      );
      _interstitialAd!.show();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("${widget.gameType.toUpperCase()} RANKING",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        centerTitle: true, elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black87,
        toolbarHeight: 45,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _roundBadge(),
                    const SizedBox(height: 10),
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
        const Text("LEFT", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        Text("$_leftScore", style: const TextStyle(fontSize: 70, fontWeight: FontWeight.w900, height: 1.1)),
        const SizedBox(height: 10),
        _buildHistoryRow(_history501),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildScoreInput("ROUND SCORE"),
            const SizedBox(width: 12),
            // 🔥 [추가] BUST 버튼 UI
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _handleBust,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text("BUST", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCricketContent() {
    String target = _cricketTargets[(_currentRound - 1).clamp(0, 7)];
    double mpr = _historyCricket.isEmpty ? 0 : _totalMarks / _historyCricket.length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _scoreInfoItem("MARKS", "$_totalMarks"),
              _scoreInfoItem("TARGET", target, isTarget: true),
              _scoreInfoItem("MPR", mpr.toStringAsFixed(2)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildHistoryRow(_historyCricket),
        const SizedBox(height: 15),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: List.generate(10, (i) => _markButton(i)),
        ),
      ],
    );
  }

  Widget _buildCountUpContent() {
    return Column(
      children: [
        const Text("TOTAL SCORE", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        Text("$_totalCountUpScore", style: const TextStyle(fontSize: 70, fontWeight: FontWeight.w900, color: Colors.amber, height: 1.1)),
        const SizedBox(height: 10),
        _buildHistoryRow(_historyCountUp),
        const SizedBox(height: 15),
        _buildScoreInput("ROUND SCORE"),
      ],
    );
  }

  Widget _buildHistoryRow(List<int> history) {
    if (history.isEmpty) return const SizedBox(height: 30);
    final lastThree = history.reversed.take(3).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: lastThree.asMap().entries.map((e) {
        int roundNum = history.length - e.key;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: e.key == 0 ? Colors.cyan.withOpacity(0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: e.key == 0 ? Colors.cyan : Colors.transparent),
          ),
          child: Text("$roundNum R: ${e.value}", style: TextStyle(fontSize: 10, fontWeight: e.key == 0 ? FontWeight.bold : FontWeight.normal)),
        );
      }).toList(),
    );
  }

  Widget _buildScoreInput(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 130,
          child: TextField(
            controller: _scoreController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofocus: true,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.cyan, width: 2),
              ),
            ),
            onSubmitted: (_) {
              if (widget.gameType == "501") _submitRound501();
              else _submitRoundCountUp();
            },
          ),
        ),
      ],
    );
  }

  Widget _scoreInfoItem(String label, String value, {bool isTarget = false}) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: isTarget ? Colors.cyanAccent : Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: Colors.white, fontSize: isTarget ? 28 : 18, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _roundBadge() {
    int max = widget.gameType == "501" ? _maxRounds501 : _maxRounds;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
      child: Text("ROUND $_currentRound / $max", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _markButton(int val) {
    String target = _cricketTargets[(_currentRound - 1).clamp(0, 7)];
    bool isDisabled = (target == "BULL" && val >= 7);
    bool isSelected = _selectedMark == val;

    return GestureDetector(
      onTap: isDisabled ? null : () => setState(() => _selectedMark = val),
      child: Container(
        width: 50, height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey[200] : (isSelected ? Colors.cyan : Colors.white),
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.cyan : Colors.grey.shade300),
        ),
        child: Text(
            "$val",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDisabled ? Colors.grey[400] : (isSelected ? Colors.white : Colors.black87)
            )
        ),
      ),
    );
  }

  Widget _buildBottomControlBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
      child: Row(
        children: [
          IconButton(
            onPressed: _currentRound > 1 ? _undoLastRound : null,
            icon: Icon(Icons.undo, color: _currentRound > 1 ? Colors.red : Colors.grey),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: widget.gameType == "501"
                    ? _submitRound501
                    : widget.gameType == "cricket"
                    ? _submitRoundCricket
                    : _submitRoundCountUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[700],
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("CONFIRM", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  void _showDartCountPicker() {
    final int finishScore = _history501.isEmpty ? 0 : _history501.last;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("FINISH! 🎯", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 8),
                Text("마지막 $finishScore점을 몇 발 만에 끝냈나요?", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [1, 2, 3].map((count) {
                    bool isPossible = true;
                    if (count == 1 && finishScore > 60) isPossible = false;
                    if (count == 2 && finishScore > 120) isPossible = false;

                    if (!isPossible) return const SizedBox.shrink();

                    return Expanded(
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
                          child: Text("$count발", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}