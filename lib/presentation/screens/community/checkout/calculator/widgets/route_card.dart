// lib/presentation/screens/community/checkout/calculator/widgets/route_card.dart
import 'package:flutter/material.dart';
import 'package:daoapp/data/models/checkout_route_model.dart';

class RouteCard extends StatelessWidget {
  final CheckoutRoute route;
  final bool isPrimary;

  const RouteCard({required this.route, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isPrimary ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      elevation: isPrimary ? 6 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            if (isPrimary)
              Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.star, color: Colors.amber, size: 22),
              ),
            Expanded(
              child: Text(
                route.primary.join(" → "),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (route.alts.isNotEmpty)
              Chip(
                label: Text("+${route.alts.length}개"),
                backgroundColor: Colors.grey[200],
              ),
          ],
        ),
      ),
    );
  }
}