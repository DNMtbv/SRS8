import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post.g.dart';

@JsonSerializable(checked: true)
class Post extends Equatable {
  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.isLocal = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  final int id;
  final int userId;
  final String title;
  final String body;

  /// Пост создан в приложении: JSONPlaceholder ничего не сохраняет,
  /// поэтому такой пост живёт только локально. В JSON не попадает.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isLocal;

  Map<String, dynamic> toJson() => _$PostToJson(this);

  Post copyWith({bool? isLocal}) => Post(
        id: id,
        userId: userId,
        title: title,
        body: body,
        isLocal: isLocal ?? this.isLocal,
      );

  @override
  List<Object?> get props => [id, userId, title, body, isLocal];
}

/// Тело запроса POST /posts.
@JsonSerializable(createFactory: false)
class CreatePostRequest {
  const CreatePostRequest({
    required this.userId,
    required this.title,
    required this.body,
  });

  final int userId;
  final String title;
  final String body;

  Map<String, dynamic> toJson() => _$CreatePostRequestToJson(this);
}
