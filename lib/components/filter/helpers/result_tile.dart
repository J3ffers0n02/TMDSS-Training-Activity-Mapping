import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ResultTile extends StatelessWidget {
  final String title;
  final String venue;
  final DateTime startDate;
  final DateTime endDate;

  const ResultTile({
    super.key,
    required this.title,
    required this.venue,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final formattedStartDate = DateFormat.yMMMd().format(startDate);
    final formattedEndDate = DateFormat.yMMMd().format(endDate);

    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
      child: Container(
        decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              border: Border.all(color: Color(0xFF00AEF0), width: 1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
        child: ListTile(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  venue,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.inverseSurface,
                  ),
                ),
              ),
              Text(
                '$formattedStartDate - $formattedEndDate',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.inverseSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
