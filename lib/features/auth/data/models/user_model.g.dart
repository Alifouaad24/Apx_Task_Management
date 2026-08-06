// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: UserModel._asString(json['id']),
  name: UserModel._asString(UserModel._readName(json, 'name')),
  email: json['email'] == null ? '' : UserModel._asStringOrEmpty(json['email']),
  avatarUrl: UserModel._asNullableString(
    UserModel._readAvatar(json, 'avatarUrl'),
  ),
  jobTitle: UserModel._asNullableString(
    UserModel._readJobTitle(json, 'jobTitle'),
  ),
  role: UserModel._asNullableString(json['role']),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'avatarUrl': instance.avatarUrl,
  'jobTitle': instance.jobTitle,
  'role': instance.role,
};
