import 'package:flutter/material.dart';

// Товар спортивного питания
class Product {
  final String name;
  final String brand;
  final String description;
  final String size;
  final int price; // в тенге
  final double rating;
  final IconData icon;
  final Color color;

  const Product({
    required this.name,
    required this.brand,
    required this.description,
    required this.size,
    required this.price,
    required this.rating,
    required this.icon,
    required this.color,
  });
}

// Категория = одна вкладка
class Category {
  final String title;
  final IconData icon;
  final List<Product> products;

  const Category(this.title, this.icon, this.products);
}

const categories = [
  Category('Протеин', Icons.fitness_center, [
    Product(
      name: 'Gold Standard 100% Whey',
      brand: 'Optimum Nutrition',
      description: 'Сывороточный протеин, 24 г белка на порцию. Вкус: шоколад.',
      size: '2,27 кг · 74 порции',
      price: 38900,
      rating: 4.9,
      icon: Icons.fitness_center,
      color: Color(0xFFFF7043),
    ),
    Product(
      name: 'Syntha-6',
      brand: 'BSN',
      description: 'Многокомпонентный протеин с медленным усвоением.',
      size: '2,27 кг · 48 порций',
      price: 32500,
      rating: 4.7,
      icon: Icons.fitness_center,
      color: Color(0xFFEF5350),
    ),
    Product(
      name: 'Casein Pro',
      brand: 'MyProtein',
      description: 'Казеин на ночь: питает мышцы до 7 часов.',
      size: '1 кг · 40 порций',
      price: 17900,
      rating: 4.5,
      icon: Icons.nightlight_round,
      color: Color(0xFF5C6BC0),
    ),
    Product(
      name: 'ISO 100',
      brand: 'Dymatize',
      description: 'Гидролизованный изолят, почти без лактозы и жиров.',
      size: '1,6 кг · 48 порций',
      price: 36400,
      rating: 4.8,
      icon: Icons.fitness_center,
      color: Color(0xFFFFA726),
    ),
  ]),
  Category('BCAA', Icons.science, [
    Product(
      name: 'BCAA 2:1:1',
      brand: 'Scivation Xtend',
      description: 'Лейцин, изолейцин, валин + электролиты. Вкус: манго.',
      size: '420 г · 30 порций',
      price: 14500,
      rating: 4.7,
      icon: Icons.science,
      color: Color(0xFF26A69A),
    ),
    Product(
      name: 'Amino Energy',
      brand: 'Optimum Nutrition',
      description: 'Аминокислоты с кофеином для энергии на тренировке.',
      size: '270 г · 30 порций',
      price: 12900,
      rating: 4.6,
      icon: Icons.bolt,
      color: Color(0xFF66BB6A),
    ),
    Product(
      name: 'EAA Complex',
      brand: 'MyProtein',
      description: 'Все 9 незаменимых аминокислот для восстановления.',
      size: '500 г · 50 порций',
      price: 11200,
      rating: 4.4,
      icon: Icons.science,
      color: Color(0xFF29B6F6),
    ),
    Product(
      name: 'Glutamine',
      brand: 'Universal',
      description: 'L-глютамин: восстановление и поддержка иммунитета.',
      size: '300 г · 60 порций',
      price: 8900,
      rating: 4.3,
      icon: Icons.healing,
      color: Color(0xFF7E57C2),
    ),
  ]),
  Category('Креатин', Icons.bolt, [
    Product(
      name: 'Creatine Monohydrate',
      brand: 'Optimum Nutrition',
      description: 'Чистый микронизированный креатин: сила и выносливость.',
      size: '300 г · 60 порций',
      price: 11500,
      rating: 4.9,
      icon: Icons.bolt,
      color: Color(0xFF42A5F5),
    ),
    Product(
      name: 'C4 Original',
      brand: 'Cellucor',
      description: 'Предтренировочный комплекс: кофеин, бета-аланин.',
      size: '195 г · 30 порций',
      price: 15800,
      rating: 4.6,
      icon: Icons.local_fire_department,
      color: Color(0xFFFF5252),
    ),
    Product(
      name: 'Serious Mass',
      brand: 'Optimum Nutrition',
      description: 'Гейнер для набора массы: 1250 ккал на порцию.',
      size: '5,45 кг · 16 порций',
      price: 34900,
      rating: 4.5,
      icon: Icons.trending_up,
      color: Color(0xFF8D6E63),
    ),
  ]),
  Category('Витамины', Icons.medication, [
    Product(
      name: 'Opti-Men',
      brand: 'Optimum Nutrition',
      description: 'Мультивитамины для мужчин, 75 активных компонентов.',
      size: '90 таблеток',
      price: 13900,
      rating: 4.7,
      icon: Icons.medication,
      color: Color(0xFFAB47BC),
    ),
    Product(
      name: 'Omega-3',
      brand: 'Now Foods',
      description: 'Рыбий жир: сердце, суставы и мозг.',
      size: '100 капсул',
      price: 7900,
      rating: 4.8,
      icon: Icons.water_drop,
      color: Color(0xFFFFCA28),
    ),
    Product(
      name: 'Animal Flex',
      brand: 'Universal',
      description: 'Комплекс для связок и суставов.',
      size: '44 пакетика',
      price: 19500,
      rating: 4.6,
      icon: Icons.accessibility_new,
      color: Color(0xFF78909C),
    ),
  ]),
];

String formatPrice(int price) {
  final s = price.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '$buf ₸';
}

class TabsPage extends StatefulWidget {
  const TabsPage({super.key});

  @override
  State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  final cart = <Product>[];
  final favorites = <Product>{};

  int get total => cart.fold(0, (sum, p) => sum + p.price);

  void addToCart(Product p) {
    setState(() => cart.add(p));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${p.name} добавлен в корзину'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ));
  }

  void showCart() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Корзина',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (cart.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Пока пусто', textAlign: TextAlign.center),
              )
            else
              ...cart.map((p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(p.icon, color: p.color),
                    title: Text(p.name),
                    trailing: Text(formatPrice(p.price)),
                  )),
            const Divider(),
            Row(
              children: [
                const Text('Итого', style: TextStyle(fontSize: 18)),
                const Spacer(),
                Text(
                  formatPrice(total),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: cart.isEmpty
                  ? null
                  : () {
                      setState(() => cart.clear());
                      Navigator.pop(context);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Заказ оформлен! 💪')),
                      );
                    },
              child: const Text('Оформить заказ'),
            ),
          ],
        ),
      ),
    );
  }

  void showFavorites() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        // StatefulBuilder — чтобы список обновлялся при удалении
        builder: (context, setSheetState) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Избранное',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (favorites.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.favorite_border,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Нажмите ♡ на товаре, чтобы добавить его сюда'),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final p in favorites.toList())
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: p.color,
                              child: Icon(p.icon, color: Colors.white),
                            ),
                            title: Text(p.name),
                            subtitle: Text(formatPrice(p.price)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'В корзину',
                                  onPressed: () => addToCart(p),
                                  icon: const Icon(Icons.add_shopping_cart),
                                ),
                                IconButton(
                                  tooltip: 'Убрать',
                                  onPressed: () {
                                    setState(() => favorites.remove(p));
                                    setSheetState(() {});
                                  },
                                  icon: const Icon(Icons.favorite,
                                      color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Спортпит'),
          actions: [
            IconButton(
              tooltip: 'Избранное',
              onPressed: showFavorites,
              icon: Badge(
                isLabelVisible: favorites.isNotEmpty,
                label: Text('${favorites.length}'),
                child: const Icon(Icons.favorite_border),
              ),
            ),
            IconButton(
              tooltip: 'Корзина',
              onPressed: showCart,
              icon: Badge(
                isLabelVisible: cart.isNotEmpty,
                label: Text('${cart.length}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(30),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: scheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: [
              for (final c in categories)
                Tab(
                  height: 40,
                  child: Row(
                    children: [
                      Icon(c.icon, size: 18),
                      const SizedBox(width: 6),
                      Text(c.title),
                    ],
                  ),
                ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final c in categories)
              ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: c.products.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final p = c.products[i];
                  return _ProductCard(
                    product: p,
                    isFavorite: favorites.contains(p),
                    onFavorite: () => setState(() {
                      if (!favorites.remove(p)) favorites.add(p);
                    }),
                    onAdd: () => addToCart(p),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onAdd;

  const _ProductCard({
    required this.product,
    required this.isFavorite,
    required this.onFavorite,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final p = product;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // «Картинка» товара
            Container(
              width: 84,
              height: 104,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [p.color, p.color.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(p.icon, color: Colors.white, size: 40),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.brand.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFFFFB300)),
                      Text(' ${p.rating}',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.size,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        formatPrice(p.price),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onFavorite,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                      ),
                      IconButton.filled(
                        visualDensity: VisualDensity.compact,
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_shopping_cart, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
