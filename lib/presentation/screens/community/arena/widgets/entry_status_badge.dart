// lib/presentation/screens/arena/widgets/entry_status_badge.dart
import 'package:flutter/material.dart';
import 'package:daoapp/core/utils/arena_utils.dart';

class EntryStatusBadge extends StatelessWidget {
  final EntryStatus status;

  const EntryStatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ArenaUtils.getStatusColor(status, context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        ArenaUtils.getStatusText(status),
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}