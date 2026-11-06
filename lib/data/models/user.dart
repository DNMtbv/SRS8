import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// Из ответа /users берём только нужные поля, остальные игнорируются.
@JsonSerializable(checked: true)
class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.website,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  final int id;
  final String name;
  final String username;
  final String email;
  final String? website;

  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  List<Object?> get props => [id, name, username, email, website];
}
