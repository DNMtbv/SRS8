import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/posts_repository.dart';
import '../bloc/posts_bloc.dart';

/// Поиск, фильтр по автору, сортировка и сброс.
class FiltersPanel extends StatefulWidget {
  const FiltersPanel({super.key});

  @override
  State<FiltersPanel> createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<FiltersPanel> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PostsBloc>();

    return BlocConsumer<PostsBloc, PostsState>(
      listenWhen: (a, b) => a.search != b.search,
      listener: (context, state) {
        // Синхронизация при сбросе фильтров.
        if (_searchController.text != state.search) {
          _searchController.text = state.search;
        }
      },
      buildWhen: (a, b) =>
          a.search != b.search ||
          a.query != b.query ||
          a.users != b.users,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (v) => bloc.add(PostsSearchChanged(v)),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  // Поиск локальный: явно говорим, что ищем среди загруженного.
                  hintText: 'Поиск по загруженным постам',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  suffixIcon: state.search.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Очистить',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            bloc.add(const PostsSearchChanged(''));
                          },
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      initialValue: state.query.userId,
                      key: ValueKey(
                        'author-${state.query.userId}-${state.users.length}',
                      ),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Автор',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Все авторы'),
                        ),
                        for (final u in state.users)
                          DropdownMenuItem<int?>(
                            value: u.id,
                            child: Text(u.name, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (id) => bloc.add(PostsAuthorFilterChanged(id)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SegmentedButton<SortOrder>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                    segments: const [
                      ButtonSegment(
                        value: SortOrder.asc,
                        label: Text('ID ↑'),
                        tooltip: 'По возрастанию ID',
                      ),
                      ButtonSegment(
                        value: SortOrder.desc,
                        label: Text('ID ↓'),
                        tooltip: 'По убыванию ID',
                      ),
                    ],
                    selected: {state.query.order},
                    onSelectionChanged: (s) =>
                        bloc.add(PostsSortChanged(s.first)),
                  ),
                ],
              ),
              if (state.hasActiveFilters)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => bloc.add(const PostsFiltersReset()),
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                    label: const Text('Сбросить фильтры'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
