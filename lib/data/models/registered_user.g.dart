// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registered_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisteredUser _$RegisteredUserFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RegisteredUser', json, ($checkedConvert) {
      final val = RegisteredUser(
        name: $checkedConvert('name', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String),
        phone: $checkedConvert('phone', (v) => v as String),
        city: $checkedConvert('city', (v) => v as String?),
        fcmToken: $checkedConvert('fcmToken', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$RegisteredUserToJson(RegisteredUser instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'city': ?instance.city,
      'fcmToken': ?instance.fcmToken,
    };
