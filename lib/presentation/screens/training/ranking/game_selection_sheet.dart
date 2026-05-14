// lib/presentation/screens/training/ranking/game_selection_sheet.dart

import 'package:flutter/material.dart';
import 'package:daoapp/presentation/screens/training/ranking/ranking_game_run_screen.dart';
import 'package:daoapp/l10n/app_localizations.dart'; // 🔹 추가

class GameSelectionSheet extends StatelessWidget {
  const GameSelectionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!; // 🔹 언어팩 인스턴스

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 25),
          // 🔹 제목 다국어화
          Text(s.rank_select_title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 20),

          // 🔹 각 타일의 설명을 다국어 키로 교체
          _gameTile(context, "501 GAME", s.rank_501_desc, Icons.looks_5, Colors.cyan, "501"),
          _gameTile(context, "CRICKET", s.rank_cricket_desc, Icons.ads_click, Colors.orange, "cricket"),
          _gameTile(context, "COUNT-UP", s.rank_countup_desc, Icons.calculate, Colors.deepPurple, "countup"),
        ],
      ),
    );
  }

  Widget _gameTile(BuildContext context, String title, String sub, IconData icon, Color color, String type) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RankingGameRunScreen(gameType: type))
        );
      },
    );
  }
}