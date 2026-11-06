import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/comment.dart';
import '../../data/models/post.dart';
import '../../data/repositories/posts_repository.dart';
import '../widgets/state_views.dart';
import 'post_details_cubit.dart';

class PostDetailsPage extends StatelessWidget {
  const PostDetailsPage({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PostDetailsCubit(context.read<PostsRepository>(), post)..load(),
      child: Scaffold(
        appBar: AppBar(title: Text('Пост #${post.id}')),
        body: BlocBuilder<PostDetailsCubit, PostDetailsState>(
          builder: (context, state) => switch (state) {
            PostDetailsLoading() => const LoadingView(),
            PostDetailsError(:final error) => MessageView(
                icon: Icons.error_outline,
                title: 'Не удалось загрузить пост',
                message: error.message,
                actionLabel: 'Повторить',
                onAction: () => context.read<PostDetailsCubit>().load(),
              ),
            PostDetailsLoaded() => _DetailsView(state: state),
          },
        ),
      ),
    );
  }
}

class _DetailsView extends StatelessWidget {
  const _DetailsView({required this.state});

  final PostDetailsLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = state.post;
    final author = state.author;

    return RefreshIndicator(
      onRefresh: () => context.read<PostDetailsCubit>().load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (post.isLocal) ...[
            const Align(alignment: Alignment.centerLeft, child: LocalBadge()),
            const SizedBox(height: 8),
          ],
          Text(
            post.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              child: Text(author?.name.characters.first ?? '?'),
            ),
            title: Text(author?.name ?? 'Автор #${post.userId}'),
            subtitle: author == null
                ? null
                : Text('@${author.username} · ${author.email}'),
          ),
          const SizedBox(height: 8),
          Text(post.body, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),
          Text(
            'Комментарии (${state.comments.length})',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (state.comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                post.isLocal
                    ? 'Пост создан локально, на сервере комментариев к нему нет.'
                    : 'Комментариев пока нет.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          else
            for (final c in state.comments) _CommentTile(comment: c),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(comment.name, style: theme.textTheme.titleSmall),
            Text(
              comment.email,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 6),
            Text(comment.body),
          ],
        ),
      ),
    );
  }
}
