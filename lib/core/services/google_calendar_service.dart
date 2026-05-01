import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class GoogleCalendarService {
  final String apiKey = "AIzaSyClBdOgfMQU4EbSt0xSOPJShhxMQ-FSM8M";

  Future<List<Map<String, dynamic>>> fetchMergedEvents(List<String> calendarIds, DateTime targetMonth) async {
    List<Map<String, dynamic>> combinedEvents = [];

    final String timeMin = DateTime(targetMonth.year, targetMonth.month, 1, 0, 0, 0)
        .subtract(const Duration(hours: 12))
        .toUtc()
        .toIso8601String();
    final String timeMax = DateTime(targetMonth.year, targetMonth.month + 1, 1, 0, 0, 0)
        .add(const Duration(hours: 12))
        .toUtc()
        .toIso8601String();

    await Future.wait(calendarIds.map((id) async {
      String? pageToken;
      try {
        do {
          final String url = "https://www.googleapis.com/calendar/v3/calendars/$id/events"
              "?key=$apiKey"
              "&timeMin=$timeMin"
              "&timeMax=$timeMax"
              "&singleEvents=true"
              "&orderBy=startTime"
              "&maxResults=2500${pageToken != null ? '&pageToken=$pageToken' : ''}";

          final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['items'] != null) {
              final List items = data['items'];
              for (var item in items) {
                item['calendarId'] = id;
                combinedEvents.add(item);
              }
            }
            pageToken = data['nextPageToken'];
          } else {
            pageToken = null;
          }
        } while (pageToken != null);
      } catch (e) {
        // 네트워크 에러 시 중단 방지를 위해 빈 catch 유지
      }
    }));

    return combinedEvents;
  }
}