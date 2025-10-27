// lib/ presentation/screens/admin/event_create_screen.dart
import 'package:flutter/material.dart';

class EventCreateScreen extends StatelessWidget {
  const EventCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('경기 등록하기')),
      body: const Center(
        child: Text(
          '경기 등록 화면이에요!\n샵, 날짜, 시간 입력할 거예요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}