// lib/presentation/screens/community/checkout/calculator/widgets/route_card.dart
import 'package:flutter/material.dart';
import 'package:daoapp/data/models/checkout_route_model.dart';

class RouteCard extends StatelessWidget {
  final CheckoutRoute route;
  const RouteCard({required this.route, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.lightbulb, color: Colors.amber),
      title: Text(
        route.primary.join(" → "),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}