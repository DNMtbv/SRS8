import 'package:flutter/material.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Кнопки')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Круг со значением счётчика
              Container(
                width: 200,
                height: 200,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF7043), Color(0xFFFF5252)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x55FF5252),
                      blurRadius: 30,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton(
                    onPressed: () => setState(() => count++),
                    child: const Text('+1'),
                  ),
                  OutlinedButton(
                    onPressed: () => setState(() => count--),
                    child: const Text('-1'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => setState(() => count += 10),
                    icon: const Icon(Icons.star),
                    label: const Text('+10'),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => count = 0),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Сброс'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
