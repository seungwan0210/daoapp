// lib/presentation/screens/training/calculator/widgets/route_card.dart
import 'package:flutter/material.dart';

import 'package:daoapp/data/models/checkout_route_model.dart';

class RouteCard extends StatelessWidget {
  final CheckoutRoute route;

  const RouteCard({
    super.key,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.lightbulb,
        color: Colors.amber,
      ),
      title: Text(
        route.primary.join(" → "),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
