import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/color.dart';
import '../../viewmodels/savings_view_model.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SavingsViewModel>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Моя цель', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(vm.formattedCurrent, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                Text('/ ${vm.formattedGoal}', style: const TextStyle(fontSize: 18, color: kTextSecondary)),
              ],
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: vm.progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 14,
                    backgroundColor: Colors.grey.shade200,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text('Осталось: ${vm.formattedRemaining}', style: const TextStyle(color: kTextSecondary)),
          ],
        ),
      ),
    );
  }
}
