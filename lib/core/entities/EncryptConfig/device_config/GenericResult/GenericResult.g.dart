// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'GenericResult.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenericResult<T> _$GenericResultFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => GenericResult<T>(
  name: json['name'] as String?,
  result: _$nullableGenericFromJson(json['result'], fromJsonT),
);

Map<String, dynamic> _$GenericResultToJson<T>(
  GenericResult<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'name': ?instance.name,
  'result': ?_$nullableGenericToJson(instance.result, toJsonT),
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);
