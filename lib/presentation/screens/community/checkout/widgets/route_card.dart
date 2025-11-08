// lib/presentation/screens/checkout/widgets/route_card.dart
import 'package:flutter/material.dart';
import 'package:daoapp/data/models/checkout_route_model.dart';

class RouteCard extends StatelessWidget {
  final CheckoutRoute route;
  const RouteCard({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "추천 체크아웃 경로",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildRoute(route.primary, isPrimary: true, context: context),  // context 전달
            ...route.alts.map((alt) => _buildRoute(alt, isPrimary: false, context: context)),
          ],
        ),
      ),
    );
  }

  // context 파라미터 추가
  Widget _buildRoute(List<String> segments, {required bool isPrimary, required BuildContext context}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (isPrimary)
            const Icon(Icons.star, color: Colors.amber, size: 18),
          if (isPrimary) const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: segments.map((seg) {
                return Chip(
                  label: Text(
                    seg,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: isPrimary
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)  // context 사용
                      : null,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}