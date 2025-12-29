// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  username: json['username'] as String,
  fullName: json['full_name'] as String?,
  nik: json['nik'] as String?,
  phone: json['phone'] as String?,
  role: json['role'] as String,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'full_name': instance.fullName,
  'nik': instance.nik,
  'phone': instance.phone,
  'role': instance.role,
};
