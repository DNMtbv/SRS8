import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/post.dart';
import '../../data/repositories/posts_repository.dart';
import '../create_post/create_post_page.dart';
import '../post_details/post_details_page.dart';
import '../registration/registration_page.dart';
import '../widgets/state_views.dart';
import 'bloc/posts_bloc.dart';
import 'widgets/filters_panel.dart';
import 'widgets/post_card.dart';

class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  Future<void> _openCreate(BuildContext context) async {
    final bloc = context.read<PostsBloc>();
    final created = await Navigator.of(context).push<Post>(
      MaterialPageRoute(builder: (_) => const CreatePostPage()),
    );
    if (created != null) {
      bloc.add(PostsLocalPostAdded(created));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Посты'),
        actions: [
          IconButton(
            tooltip: 'Регистрация',
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RegistrationPage()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Новый пост'),
      ),
      body: const Column(
        children: [
          FiltersPanel(),
          _CachedBanner(),
          Expanded(child: _PostsBody()),
        ],
      ),
    );
  }
}

/// Плашка «Показаны сохранённые данные».
class _CachedBanner extends StatelessWidget {
  const _CachedBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostsBloc, PostsState>(
      buildWhen: (a, b) =>
          a.status != b.status ||
          a.isRefreshing != b.isRefreshing ||
          a.error != b.error,
      builder: (context, state) {
        if (state.status != PostsStatus.cached) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        final reason = state.isRefreshing
            ? 'Обновляем с сервера…'
            : state.error?.message ?? 'Не удалось обновить данные.';
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.cloud_off_outlined,
                  color: scheme.onSecondaryContainer, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Показаны сохранённые данные',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    Text(
                      reason,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.isRefreshing)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                TextButton(
                  onPressed: () => context
                      .read<PostsBloc>()
                      .add(const PostsRefreshRequested()),
                  child: const Text('Обновить'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PostsBody extends StatelessWidget {
  const _PostsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostsBloc, PostsState>(
      buildWhen: (a, b) => a.status != b.status || a.error != b.error,
      builder: (context, state) {
        final bloc = context.read<PostsBloc>();
        switch (state.status) {
          case PostsStatus.initial:
          case PostsStatus.loading:
            return const LoadingView();
          case PostsStatus.error:
            return MessageView(
              icon: Icons.wifi_off_rounded,
              title: 'Не удалось загрузить посты',
              message: state.error?.message,
              actionLabel: 'Повторить',
              onAction: () => bloc.add(const PostsRetryRequested()),
            );
          case PostsStatus.empty:
            return RefreshIndicator(
              onRefresh: () => _refresh(bloc),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  MessageView(
                    icon: Icons.inbox_outlined,
                    title: 'Постов нет',
                    message: 'Сервер вернул пустой список для этих фильтров.',
                    actionLabel: 'Сбросить фильтры',
                    onAction: () => bloc.add(const PostsFiltersReset()),
                  ),
                ],
              ),
            );
          case PostsStatus.success:
          case PostsStatus.cached:
            return const _PostsList();
        }
      },
    );
  }
}

/// pull-to-refresh ждёт, пока блок закончит обновление.
Future<void> _refresh(PostsBloc bloc) async {
  bloc.add(const PostsRefreshRequested());
  await bloc.stream.firstWhere(
    (s) => !s.isRefreshing && s.status != PostsStatus.loading,
  );
}

class _PostsList extends StatefulWidget {
  const _PostsList();

  @override
  State<_PostsList> createState() => _PostsListState();
}

class _PostsListState extends State<_PostsList> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      context.read<PostsBloc>().add(const PostsNextPageRequested());
    }
  }

  /// Если список не заполнил экран, скролла не будет — догружаем сами.
  void _fillViewportIfNeeded(PostsState state) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      if (state.search.isEmpty &&
          state.hasMore &&
          _controller.position.maxScrollExtent <= 0) {
        context.read<PostsBloc>().add(const PostsNextPageRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PostsBloc>();
    return BlocConsumer<PostsBloc, PostsState>(
      listenWhen: (a, b) => a.posts.length != b.posts.length,
      listener: (_, state) => _fillViewportIfNeeded(state),
      builder: (context, state) {
        final posts = state.visiblePosts;
        return RefreshIndicator(
          onRefresh: () => _refresh(bloc),
          child: ListView.builder(
            controller: _controller,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: posts.length + 1,
            itemBuilder: (context, index) {
              if (index == posts.length) {
                return _ListFooter(state: state, isEmpty: posts.isEmpty);
              }
              final post = posts[index];
              return PostCard(
                key: post.isLocal ? ObjectKey(post) : ValueKey(post.id),
                post: post,
                authorName: state.userById(post.userId)?.name,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PostDetailsPage(post: post),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Низ списка: индикатор подгрузки / «Повторить» / конец списка.
class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.state, required this.isEmpty});

  final PostsState state;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PostsBloc>();
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    final Widget child;
    if (state.pageStatus == PageLoadStatus.loading) {
      child = const CircularProgressIndicator();
    } else if (state.pageStatus == PageLoadStatus.error) {
      child = Column(
        children: [
          Text(
            state.pageError?.message ?? 'Не удалось загрузить страницу',
            textAlign: TextAlign.center,
            style: muted,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => bloc.add(const PostsNextPageRequested()),
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        ],
      );
    } else if (state.search.isNotEmpty) {
      child = Column(
        children: [
          if (isEmpty)
            Text('Среди загруженных постов ничего не найдено', style: muted),
          if (state.hasMore) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => bloc.add(const PostsNextPageRequested()),
              child: const Text('Загрузить ещё посты для поиска'),
            ),
          ],
        ],
      );
    } else if (!state.hasMore) {
      child = Text(
        'Больше постов нет (страниц: ${state.page}, '
        'по ${PostsRepository.pageSize} шт.)',
        style: muted,
      );
    } else {
      child = const SizedBox(height: 24);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Center(child: child),
    );
  }
}
