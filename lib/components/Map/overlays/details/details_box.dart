import 'package:flutter/material.dart';

class DetailsBox extends StatelessWidget {
  final int totalTrainings;
  final bool shouldShow; // NEW FLAG

  const DetailsBox({
    super.key,
    required this.totalTrainings,
    required this.shouldShow,
  });

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink(); // HIDE if no dropdowns

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: ListTile(
        leading: const Icon(Icons.analytics_outlined),
        title: Text(
          'Total Trainings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        trailing: Text(
          totalTrainings.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
        ),
      ),
    );
  }
}
