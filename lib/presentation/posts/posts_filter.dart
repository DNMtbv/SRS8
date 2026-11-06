import '../../data/models/post.dart';

/// Поиск по заголовку среди уже загруженных постов (без учёта регистра).
List<Post> filterPostsByTitle(List<Post> posts, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return posts;
  return posts.where((p) => p.title.toLowerCase().contains(q)).toList();
}
