import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'registered_user.g.dart';

/// Пользователь, которого сохраняем в Realtime Database (/users/{key}).
@JsonSerializable(checked: true, includeIfNull: false)
class RegisteredUser extends Equatable {
  const RegisteredUser({
    required this.name,
    required this.email,
    required this.phone,
    this.city,
    this.fcmToken,
  });

  factory RegisteredUser.fromJson(Map<String, dynamic> json) =>
      _$RegisteredUserFromJson(json);

  final String name;
  final String email;
  final String phone;
  final String? city;

  /// Токен устройства: по нему можно отправить пуш именно этому пользователю.
  final String? fcmToken;

  Map<String, dynamic> toJson() => _$RegisteredUserToJson(this);

  @override
  List<Object?> get props => [name, email, phone, city, fcmToken];
}
