import 'package:flutter/material.dart';

import 'counter_page.dart';
import 'form_page.dart';
import 'gesture_page.dart';
import 'tabs_page.dart';

// Пункт меню на главном экране
class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final Widget page;

  const _MenuItem(this.title, this.subtitle, this.icon, this.colors, this.page);
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const items = [
    _MenuItem('Кнопки', 'Счётчик', Icons.touch_app,
        [Color(0xFFFF7043), Color(0xFFFF5252)], CounterPage()),
    _MenuItem('Поле ввода', 'Введите имя', Icons.edit_note,
        [Color(0xFF7C4DFF), Color(0xFF536DFE)], FormPage()),
    _MenuItem('Жесты', 'Нажатия и свайпы', Icons.swipe,
        [Color(0xFF26A69A), Color(0xFF00BFA5)], GesturePage()),
    _MenuItem('Спортпит', 'Протеин, BCAA…', Icons.fitness_center,
        [Color(0xFF212121), Color(0xFF424242)], TabsPage()),
  ];

  // Открыть новый экран
  void open(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  // Показать диалог
  void showMyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.waving_hand, size: 40),
        title: const Text('Привет!'),
        content: const Text('Это пример диалога'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Примеры Flutter')),

      // Шторка (меню слева)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF7043), Color(0xFFFF5252)],
                ),
              ),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Меню',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            for (final item in items)
              ListTile(
                leading: Icon(item.icon, color: scheme.primary),
                title: Text(item.title),
                onTap: () {
                  Navigator.pop(context); // закрыть шторку
                  open(context, item.page);
                },
              ),
          ],
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Выберите пример',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),

          // Плитки с разделами
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.95,
            children: [
              for (final item in items)
                _MenuTile(item: item, onTap: () => open(context, item.page)),
            ],
          ),

          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => showMyDialog(context),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Показать диалог'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  final VoidCallback onTap;

  const _MenuTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: item.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 28),
                ),
                const Spacer(),
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
