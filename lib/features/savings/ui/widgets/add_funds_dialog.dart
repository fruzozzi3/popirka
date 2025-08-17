import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/savings_view_model.dart';

class AddFundsDialog extends StatefulWidget {
  const AddFundsDialog({super.key});

  @override
  State<AddFundsDialog> createState() => _AddFundsDialogState();
}

class _AddFundsDialogState extends State<AddFundsDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Пополнить копилку'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Введите сумму (₽)',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            final value = int.tryParse(text);
            if (value == null || value <= 0) {
              setState(() => _error = 'Введите положительное число');
              return;
            }
            context.read<SavingsViewModel>().addCustom(value);
            Navigator.pop(context);
          },
          child: const Text('Добавить'),
        )
      ],
    );
  }
}
