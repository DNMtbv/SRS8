import 'package:flutter/material.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final controller = TextEditingController();
  String result = '';
  String initial = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void showGreeting() {
    final name = controller.text.trim();
    FocusScope.of(context).unfocus(); // спрятать клавиатуру
    setState(() {
      result = name.isEmpty ? '' : 'Привет, $name!';
      initial = name.isEmpty ? '' : name[0].toUpperCase();
    });
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала введите имя')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Поле ввода')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => showGreeting(),
            decoration: const InputDecoration(
              labelText: 'Введите имя',
              hintText: 'Например, Динмухаммед',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: showGreeting,
            icon: const Icon(Icons.waving_hand),
            label: const Text('Показать'),
          ),
          const SizedBox(height: 28),

          // Карточка с приветствием
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: result.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    key: ValueKey(result),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Text(
                            initial,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            result,
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
