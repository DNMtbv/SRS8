import 'package:flutter/material.dart';

class GesturePage extends StatefulWidget {
  const GesturePage({super.key});

  @override
  State<GesturePage> createState() => _GesturePageState();
}

class _GesturePageState extends State<GesturePage> {
  bool isRed = false;
  List<String> items = ['Яблоко', 'Банан', 'Груша', 'Апельсин'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Жесты')),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Нажатие на квадрат
          GestureDetector(
            onTap: () => setState(() => isRed = !isRed),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 140,
              height: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isRed
                      ? const [Color(0xFFFF7043), Color(0xFFFF5252)]
                      : const [Color(0xFF26A69A), Color(0xFF00BFA5)],
                ),
                borderRadius: BorderRadius.circular(isRed ? 70 : 28),
              ),
              child: const Text(
                'Нажми',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'Смахни строку в сторону:',
            style: TextStyle(color: Colors.grey.shade700),
          ),

          // Список, строки можно смахнуть
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: Key(item),
                      onDismissed: (direction) {
                        setState(() => items.remove(item));
                      },
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: const Icon(Icons.eco_outlined),
                          title: Text(item),
                          trailing: const Icon(Icons.drag_handle),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
