import 'package:flutter/material.dart';
import 'package:daoapp/presentation/screens/training/ranking/ranking_game_run_screen.dart';

class GameSelectionSheet extends StatelessWidget {
  const GameSelectionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 25),
          const Text("도전 종목 선택", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _gameTile(context, "501 GAME", "PPD 랭킹 도전 (10라운드)", Icons.looks_5, Colors.cyan, "501"),
          _gameTile(context, "CRICKET", "MPR 랭킹 도전 (15라운드)", Icons.ads_click, Colors.orange, "cricket"),
          _gameTile(context, "COUNT-UP", "최고 점수 도전 (8라운드)", Icons.calculate, Colors.deepPurple, "countup"),
        ],
      ),
    );
  }

  Widget _gameTile(BuildContext context, String title, String sub, IconData icon, Color color, String type) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => RankingGameRunScreen(gameType: type)));
      },
    );
  }
}