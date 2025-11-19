// lib/presentation/screens/arena/widgets/participant_list_item.dart
import 'package:flutter/material.dart';
import 'package:daoapp/data/models/tournament_entry_model.dart';

class ParticipantListItem extends StatelessWidget {
  final TournamentEntryModel entry;
  final int index;

  const ParticipantListItem({Key? key, required this.entry, required this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('${index + 1}')),
        title: Text('${entry.nameKo} (${entry.nameEn})'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('연락처: ${entry.phone}'),
            if (entry.email?.isNotEmpty ?? false) Text('이메일: ${entry.email}'),
            if (entry.rating?.isNotEmpty ?? false) Text('레이팅: ${entry.rating}'),
            if (entry.homeShop?.isNotEmpty ?? false) Text('홈샵: ${entry.homeShop}'),
          ],
        ),
      ),
    );
  }
}