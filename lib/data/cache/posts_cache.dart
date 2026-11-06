import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/logger.dart';
import '../models/post.dart';
import '../models/user.dart';

/// Кэш на SharedPreferences. Храним JSON, разбираем теми же
/// сгенерированными fromJson. Битый кэш удаляется и не роняет приложение.
class PostsCache {
  PostsCache(this._prefs);

  final SharedPreferences _prefs;

  static const _postsPrefix = 'cache.posts.';
  static const _usersKey = 'cache.users';
  static const _localPostsKey = 'cache.local_posts';

  Future<void> savePosts(String queryKey, List<Post> posts) =>
      _write(_postsPrefix + queryKey, posts.map((p) => p.toJson()).toList());

  List<Post>? readPosts(String queryKey) =>
      _readList(_postsPrefix + queryKey, Post.fromJson);

  Future<void> saveUsers(List<User> users) =>
      _write(_usersKey, users.map((u) => u.toJson()).toList());

  List<User>? readUsers() => _readList(_usersKey, User.fromJson);

  Future<void> saveLocalPosts(List<Post> posts) =>
      _write(_localPostsKey, posts.map((p) => p.toJson()).toList());

  List<Post> readLocalPosts() =>
      (_readList(_localPostsKey, Post.fromJson) ?? const [])
          .map((p) => p.copyWith(isLocal: true))
          .toList();

  Future<void> _write(String key, List<Map<String, dynamic>> items) async {
    await _prefs.setString(key, jsonEncode(items));
  }

  List<T>? _readList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      AppLogger.error('Повреждён кэш "$key", удаляю', error: e, stackTrace: s);
      _prefs.remove(key);
      return null;
    }
  }
}
