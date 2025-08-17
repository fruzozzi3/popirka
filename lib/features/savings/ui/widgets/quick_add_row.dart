import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/savings_view_model.dart';

class QuickAddRow extends StatelessWidget {
  final List<int> presets;
  const QuickAddRow({super.key, this.presets = const [100, 200, 1000]});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SavingsViewModel>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: presets.map((p) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: OutlinedButton(
              onPressed: () => vm.add(p),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('+$p ₽', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
